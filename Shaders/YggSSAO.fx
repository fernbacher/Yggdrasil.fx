#include "ReShade.fxh"
#include "YggCore.fxh"
#include "YggSSAO.fxh"

// =============================================================================
//  YggSSAO v2.2 -- GTAO-inspired SSAO
// =============================================================================

uniform float SSAOStrength <
    ui_type = "drag"; ui_min = 0.0; ui_max = 4.0; ui_step = 0.01;
    ui_label = "SSAO Strength";
    ui_tooltip = "Occlusion darkening. 1.0-2.0 natural. 3.0+ stylized.";
> = 1.8;

uniform float SSAORadius <
    ui_type = "drag"; ui_min = 1.0; ui_max = 24.0; ui_step = 0.1;
    ui_label = "Sample Radius (px)";
    ui_tooltip = "Search radius. 4-8px contact shadows. 8-16px broader occlusion.";
> = 8.0;

uniform float SSAOThickness <
    ui_type = "drag"; ui_min = 0.001; ui_max = 0.50; ui_step = 0.001;
    ui_label = "Depth Thickness Gate";
    ui_tooltip =
        "Max depth diff to count as occlusion.\n"
        "Prevents distant geo from casting AO on foreground.\n"
        "0.05-0.15 recommended. Raise if AO looks too tight.";
> = 0.10;

uniform float SSAOBias <
    ui_type = "drag"; ui_min = 0.0; ui_max = 0.05; ui_step = 0.0005;
    ui_label = "Self-Occlusion Bias";
    ui_tooltip = "Min depth diff to count. Raise if flat surfaces show noise.";
> = 0.004;

uniform float SSAOBrightLimit <
    ui_type = "drag"; ui_min = 0.3; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Bright Area Limit";
    ui_tooltip = "Suppresses AO on bright pixels. Prevents darkening emissives/sky.";
> = 0.85;

uniform float SSAOBlurSharpness <
    ui_type = "drag"; ui_min = 1.0; ui_max = 40.0; ui_step = 0.5;
    ui_label = "Blur Edge Sharpness";
    ui_tooltip = "Bilateral depth sensitivity. Higher = less AO bleed across edges.";
> = 12.0;

uniform float SSAOBlend <
    ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Blend";
> = 1.0;

uniform float SSAONormalStrength <
    ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Normal Weighting";
    ui_tooltip = "0 = ignore normals. 0.5-0.8 = recommended.";
> = 0.6;

uniform bool SSAOLumaOnly <
    ui_type = "checkbox";
    ui_label = "Luma-Only Composite";
    ui_tooltip = "AO via luma scale. Hue/sat unchanged. Recommended on.";
> = true;

uniform bool SSAOAdaptive <
    ui_type = "checkbox";
    ui_label = "Scene-Adaptive Strength";
> = true;

uniform float SSAOAdaptStrength <
    ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Adaptive Strength";
> = 0.38;

uniform uint SSAOFrame < source = "framecount"; >;

// =============================================================================
//  TEXTURES
// =============================================================================

texture2D YggSSAORawTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
sampler2D YggSSAORawSampler  { Texture = YggSSAORawTex;  MinFilter = POINT;  MagFilter = POINT;  AddressU = CLAMP; AddressV = CLAMP; };

texture2D YggSSAOBlurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
sampler2D YggSSAOBlurSampler { Texture = YggSSAOBlurTex; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = CLAMP; AddressV = CLAMP; };

texture2D YggSceneKeyTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
sampler2D YggSceneKeySampler { Texture = YggSceneKeyTex; MinFilter = POINT; MagFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; };

// =============================================================================
//  BILATERAL WEIGHT
// =============================================================================

float BW(float cD, float nD)
{
    return exp(-abs(cD - nD) * SSAOBlurSharpness * 80.0);
}

// =============================================================================
//  HORIZON SAMPLE -- correct depth convention
//
//  sampleD < centerD means sample is CLOSER (in front) -> potential occluder.
//  diff = sampleD - centerD -> negative for occluders.
//  We want: -SSAOThickness <= diff <= -SSAOBias
//    Lower bound: not so close that it's the same surface (bias)
//    Upper bound: not so far in front that it's a different object (thickness)
// =============================================================================

// SSAO sample -- returns occlusion weight [0,1]
// Uses screen-space pixel distance + depth difference to compute
// a physically meaningful occlusion angle.
// Scale factor converts linearized depth delta to screen-space units.
// Empirically: linearized depth of 0.001 ~= 1 world unit at typical FOV.
// We use a tunable world scale so the angle math works across games.
#define SSAO_DEPTH_SCALE 150.0

float HSamp(float2 uv, float2 offset, float centerD)
{
    float2 sUV = saturate(uv + offset);
    float  sD  = YggGetDepth(sUV);
    if (YggIsSky(sD)) return 0.0;

    float diff = sD - centerD;

    // Occluder must be closer (negative diff) within [bias, thickness] window
    if (diff > -SSAOBias || diff < -SSAOThickness) return 0.0;

    float absDiff   = abs(diff) * SSAO_DEPTH_SCALE;
    float screenDist = length(offset / ReShade::PixelSize);

    // Horizon angle: atan2(depth rise, screen distance)
    // Using sin approximation: sin(h) = rise / hypot(rise, dist)
    float hyp  = sqrt(screenDist * screenDist + absDiff * absDiff);
    float sinH = (hyp > YGG_SSAO_EPS) ? (absDiff / hyp) : 0.0;

    // Thickness falloff: full weight near surface, fades toward thickness limit
    float tRange  = max(SSAOThickness - SSAOBias, YGG_SSAO_EPS) * SSAO_DEPTH_SCALE;
    float falloff = saturate(1.0 - (absDiff - SSAOBias * SSAO_DEPTH_SCALE) / tRange);
    falloff       = falloff * falloff; // quadratic -- tighter contact shadows

    // Distance falloff: closer screen-space samples have more influence
    float distFalloff = saturate(1.0 - screenDist / (SSAORadius + YGG_SSAO_EPS));

    return saturate(sinH * falloff * (0.5 + 0.5 * distFalloff));
}

// =============================================================================
//  PASS 1 -- COMPUTE AO
//  6 directions x 4 rings (fwd + bwd = 8 samples per direction)
//  = 48 total depth samples per pixel. Fully manual -- no loops with tex2D.
// =============================================================================

float PS_SSAO_Compute(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px      = ReShade::PixelSize;
    float  centerD = YggGetDepth(uv);

    if (YggIsSky(centerD)) return 1.0;

    float3 normal = YggReconstructNormal(uv, px, centerD);

    // Per-pixel + temporal rotation for noise pattern diversity
    float frameJ   = float(SSAOFrame & 63) * 0.61803398875;
    float baseAngle = frac(YggIGN(pos.xy) + frameJ) * 6.28318530718;

    // Step distances: 3 rings at 33%, 66%, 100% of radius
    float r1 = SSAORadius * 0.333;
    float r2 = SSAORadius * 0.667;
    float r3 = SSAORadius * 1.000;

    // 6 directions -- better angular coverage, catches more contact shadow angles
    // Odd number of directions avoids axis-aligned bias artifacts
    float a0 = baseAngle;
    float a1 = baseAngle + 1.04719755120; // +60deg
    float a2 = baseAngle + 2.09439510239; // +120deg
    float a3 = baseAngle + 3.14159265358; // +180deg
    float a4 = baseAngle + 4.18879020479; // +240deg
    float a5 = baseAngle + 5.23598775598; // +300deg

    float2 d0 = float2(cos(a0), sin(a0));
    float2 d1 = float2(cos(a1), sin(a1));
    float2 d2 = float2(cos(a2), sin(a2));
    float2 d3 = float2(cos(a3), sin(a3));
    float2 d4 = float2(cos(a4), sin(a4));
    float2 d5 = float2(cos(a5), sin(a5));

    // 4 rings for better depth coverage
    float r4 = SSAORadius * 0.5;

    // Normal weighting: surfaces facing the sample direction contribute more
    // Using max(dot,0) instead of abs -- only consider front-facing directions
    float nw0 = lerp(1.0, max(dot(float3(d0,0.0), normal), 0.1), SSAONormalStrength);
    float nw1 = lerp(1.0, max(dot(float3(d1,0.0), normal), 0.1), SSAONormalStrength);
    float nw2 = lerp(1.0, max(dot(float3(d2,0.0), normal), 0.1), SSAONormalStrength);
    float nw3 = lerp(1.0, max(dot(float3(d3,0.0), normal), 0.1), SSAONormalStrength);
    float nw4 = lerp(1.0, max(dot(float3(d4,0.0), normal), 0.1), SSAONormalStrength);
    float nw5 = lerp(1.0, max(dot(float3(d5,0.0), normal), 0.1), SSAONormalStrength);

    #define DSAMP(dir, nw) ((HSamp(uv, dir*r1*px,centerD)+HSamp(uv, dir*r2*px,centerD)+HSamp(uv, dir*r3*px,centerD)+HSamp(uv, dir*r4*px,centerD)+HSamp(uv,-dir*r1*px,centerD)+HSamp(uv,-dir*r2*px,centerD)+HSamp(uv,-dir*r3*px,centerD)+HSamp(uv,-dir*r4*px,centerD))/8.0*nw)

    float totalAO = (DSAMP(d0,nw0)+DSAMP(d1,nw1)+DSAMP(d2,nw2)+DSAMP(d3,nw3)+DSAMP(d4,nw4)+DSAMP(d5,nw5)) / 6.0;

    #undef DSAMP

    // Power curve: makes AO punchier in occluded areas, cleaner in open areas
    totalAO = pow(saturate(totalAO), 0.7);

    return saturate(1.0 - totalAO * SSAOStrength);
}

// =============================================================================
//  PASS 2 -- BILATERAL BLUR HORIZONTAL (5-tap explicit)
// =============================================================================

float PS_SSAO_BlurH(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize;
    float  cD = YggGetDepth(uv);

    float2 u0 = uv + float2(-2.0 * px.x, 0.0);
    float2 u1 = uv + float2(-1.0 * px.x, 0.0);
    float2 u2 = uv;
    float2 u3 = uv + float2( 1.0 * px.x, 0.0);
    float2 u4 = uv + float2( 2.0 * px.x, 0.0);

    float w0 = 0.0625 * BW(cD, YggGetDepth(u0));
    float w1 = 0.2500 * BW(cD, YggGetDepth(u1));
    float w2 = 0.3750 * BW(cD, YggGetDepth(u2));
    float w3 = 0.2500 * BW(cD, YggGetDepth(u3));
    float w4 = 0.0625 * BW(cD, YggGetDepth(u4));

    float sum = tex2D(YggSSAORawSampler, u0).r * w0
              + tex2D(YggSSAORawSampler, u1).r * w1
              + tex2D(YggSSAORawSampler, u2).r * w2
              + tex2D(YggSSAORawSampler, u3).r * w3
              + tex2D(YggSSAORawSampler, u4).r * w4;

    return sum / max(w0 + w1 + w2 + w3 + w4, YGG_SSAO_EPS);
}

// =============================================================================
//  PASS 3 -- BILATERAL BLUR VERTICAL + COMPOSITE (5-tap explicit)
// =============================================================================

float4 PS_SSAO_BlurVComposite(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px  = ReShade::PixelSize;
    float  cD  = YggGetDepth(uv);
    float3 src = tex2D(ReShade::BackBuffer, uv).rgb;

    if (YggIsSky(cD)) return float4(src, 1.0);

    float2 u0 = uv + float2(0.0, -2.0 * px.y);
    float2 u1 = uv + float2(0.0, -1.0 * px.y);
    float2 u2 = uv;
    float2 u3 = uv + float2(0.0,  1.0 * px.y);
    float2 u4 = uv + float2(0.0,  2.0 * px.y);

    float w0 = 0.0625 * BW(cD, YggGetDepth(u0));
    float w1 = 0.2500 * BW(cD, YggGetDepth(u1));
    float w2 = 0.3750 * BW(cD, YggGetDepth(u2));
    float w3 = 0.2500 * BW(cD, YggGetDepth(u3));
    float w4 = 0.0625 * BW(cD, YggGetDepth(u4));

    float ao = tex2D(YggSSAOBlurSampler, u0).r * w0
             + tex2D(YggSSAOBlurSampler, u1).r * w1
             + tex2D(YggSSAOBlurSampler, u2).r * w2
             + tex2D(YggSSAOBlurSampler, u3).r * w3
             + tex2D(YggSSAOBlurSampler, u4).r * w4;
    ao /= max(w0 + w1 + w2 + w3 + w4, YGG_SSAO_EPS);

    // Scene adaptation
    if (SSAOAdaptive)
    {
        float sk = tex2D(YggSceneKeySampler, float2(0.5, 0.5)).r;
        float lm = YggLowKeyMask(sk, 0.28, 0.48);
        float hm = YggHighKeyMask(sk, 0.52, 0.75);
        float sc = YggAdaptiveScalar(1.0,
            1.0 + SSAOAdaptStrength * 0.25,
            1.0 - SSAOAdaptStrength * 0.35,
            lm, hm, SSAOAdaptStrength);
        ao = lerp(1.0, ao, sc);
    }

    // Bright gate
    float luma      = YggLuma(src);
    float brightGate = 1.0 - smoothstep(SSAOBrightLimit * 0.85, SSAOBrightLimit, luma);
    ao = lerp(1.0, ao, brightGate * SSAOBlend);

    // Composite
    float3 result;
    if (SSAOLumaOnly)
    {
        float scale = (luma * ao) / max(luma, YGG_SSAO_EPS);
        result = src * lerp(1.0, scale, SSAOBlend);
    }
    else
    {
        result = src * ao;
    }

    return float4(saturate(result), 1.0);
}

// =============================================================================
//  TECHNIQUE
// =============================================================================

technique YggSSAO
    < ui_label   = "YggSSAO v2.2 (GTAO)";
      ui_tooltip =
        "GTAO-inspired SSAO with correct depth convention handling.\n"
        "Near=dark, far=light depth buffer confirmed.\n"
        "6 directions x 8 samples = 48 taps. Bilateral blur. No loops with tex2D."; >
{
    pass ComputeGTAO    { VertexShader = PostProcessVS; PixelShader = PS_SSAO_Compute;        RenderTarget = YggSSAORawTex;  }
    pass BlurH          { VertexShader = PostProcessVS; PixelShader = PS_SSAO_BlurH;          RenderTarget = YggSSAOBlurTex; }
    pass BlurVComposite { VertexShader = PostProcessVS; PixelShader = PS_SSAO_BlurVComposite;                                }
}
