#include "ReShade.fxh"
#include "YggCore.fxh"
texture2D YggLocalMeanTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D YggLocalMeanSampler { Texture = YggLocalMeanTex; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = CLAMP; AddressV = CLAMP; };

texture2D YggSceneKeyTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
sampler2D YggSceneKeySampler { Texture = YggSceneKeyTex; MinFilter = POINT; MagFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; };

// =============================================================================
//  YggSharp -- Adaptive Detail Sharpening
// =============================================================================

uniform float SharpStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Sharp Strength";
    ui_tooltip = "Primary detail recovery strength.";
> = 0.50;

uniform float SharpRadius <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 2.0;
    ui_step = 0.05;
    ui_label = "Sharp Radius";
    ui_tooltip = "Sampling radius for detail recovery.";
> = 1.0;

uniform float EdgeThreshold <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.25;
    ui_step = 0.001;
    ui_label = "Edge Threshold";
    ui_tooltip = "Suppresses sharpening in very flat regions.";
> = 0.018;

uniform float HaloSuppression <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Halo Suppression";
    ui_tooltip = "Clamps sharpened output toward local neighborhood to reduce ringing.";
> = 0.64;

uniform float DetailBias <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Detail Bias";
    ui_tooltip = "Biases sharpening toward small-scale texture detail.";
> = 0.38;

uniform float EdgePrecision <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.5;
    ui_step = 0.01;
    ui_label = "Edge Precision";
    ui_tooltip = "Extra emphasis on clean edge definition.";
> = 0.22;

uniform float MicroDetail <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.5;
    ui_step = 0.01;
    ui_label = "Micro Detail";
    ui_tooltip = "Recovers very fine detail and material texture.";
> = 0.18;

uniform float LocalContrast <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Local Contrast Assist";
    ui_tooltip = "Mid-frequency luma separation assist, useful in darker scenes.";
> = 0.18;

uniform float ContrastRadius <
    ui_type = "drag";
    ui_min = 1.0; ui_max = 3.0;
    ui_step = 0.25;
    ui_label = "Local Contrast Radius";
> = 1.5;

uniform bool LumaOnly <
    ui_type = "checkbox";
    ui_label = "Luma-Only Sharpen";
    ui_tooltip =
        "Applies sharpening via multiplicative luma scale -- preserves channel ratios exactly.\n"
        "No hue shift, no color fringing. Recommended on.";
> = true;

uniform bool EnableAdaptiveSharpness <
    ui_type = "checkbox";
    ui_label = "Enable Scene-Adaptive Sharpen";
    ui_tooltip = "Reduces aggressiveness in dark scenes, allows slightly more in bright scenes.";
> = true;

uniform float AdaptiveSharpnessStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Adaptive Sharpness Strength";
> = 0.35;

float3 SampleBB(float2 uv)
{
    return tex2D(ReShade::BackBuffer, uv).rgb;
}

float3 BlurCross5(float2 uv, float2 px, float radius)
{
    float2 r = px * radius;
    float3 c = SampleBB(uv);
    float3 n = SampleBB(uv + float2(0.0, -r.y));
    float3 s = SampleBB(uv + float2(0.0,  r.y));
    float3 e = SampleBB(uv + float2( r.x, 0.0));
    float3 w = SampleBB(uv + float2(-r.x, 0.0));
    return (c + n + s + e + w) * 0.2;
}

float3 BlurDiamond5(float2 uv, float2 px, float radius)
{
    float2 r  = px * radius;
    float3 c  = SampleBB(uv);
    float3 ne = SampleBB(uv + float2( r.x, -r.y));
    float3 nw = SampleBB(uv + float2(-r.x, -r.y));
    float3 se = SampleBB(uv + float2( r.x,  r.y));
    float3 sw = SampleBB(uv + float2(-r.x,  r.y));
    return (c + ne + nw + se + sw) * 0.2;
}

float4 PS_YggSharp(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize;

    float sceneKey    = 0.5;
    float lowKeyMask  = 0.0;
    float highKeyMask = 0.0;

    float localSharpStrength = SharpStrength;
    float localLocalContrast = LocalContrast;
    float localMicroDetail   = MicroDetail;

    if (EnableAdaptiveSharpness)
    {
        sceneKey    = tex2D(YggSceneKeySampler, float2(0.5, 0.5)).r;
        lowKeyMask  = YggLowKeyMask(sceneKey, 0.28, 0.45);
        highKeyMask = YggHighKeyMask(sceneKey, 0.55, 0.72);

        localSharpStrength = YggAdaptiveScalar(localSharpStrength,
            localSharpStrength * 0.88,
            min(localSharpStrength * 1.16 + 0.01, 2.0),
            lowKeyMask, highKeyMask, AdaptiveSharpnessStrength);

        localLocalContrast = YggAdaptiveScalar(localLocalContrast,
            localLocalContrast * 1.30 + 0.03,
            localLocalContrast * 0.78,
            lowKeyMask, highKeyMask, AdaptiveSharpnessStrength);

        localMicroDetail = YggAdaptiveScalar(localMicroDetail,
            localMicroDetail * 0.92,
            min(localMicroDetail * 1.18 + 0.01, 1.5),
            lowKeyMask, highKeyMask, AdaptiveSharpnessStrength);
    }

    float3 src = SampleBB(uv);

    float3 blurSmall = BlurCross5(uv, px, SharpRadius);
    float3 blurDiag  = BlurDiamond5(uv, px, max(SharpRadius * 0.75, 0.5));
    float3 blurLarge = tex2D(YggLocalMeanSampler, uv).rgb;

    float3 detail        = src - blurSmall;
    float3 microDetailVec = src - ((blurSmall + blurDiag) * 0.5);

    float edge      = YggEdgeMask5Tap(ReShade::BackBuffer, uv, px * SharpRadius);
    float localMask = YggLocalContrastMask5Tap(ReShade::BackBuffer, uv, px * SharpRadius);

    float edgeGate     = saturate((edge - EdgeThreshold) * YggSafeRcp(max(0.20 - EdgeThreshold, 0.001)));
    float detailGate   = lerp(edgeGate, max(edgeGate, localMask), DetailBias);
    float precisionGate = saturate(pow(edgeGate, 0.80) * (1.0 + EdgePrecision * 0.45));
    detailGate         = saturate(max(detailGate * 1.06, precisionGate));

    float microGate = saturate((localMask * 0.75 + edgeGate * 0.45) * (1.0 - edgeGate * 0.18));
    float3 sharp    = src
                    + detail        * (localSharpStrength * detailGate)
                    + microDetailVec * (localMicroDetail   * microGate);

    // Anti-ringing clamp
    float3 n = SampleBB(uv + float2(0.0, -px.y * SharpRadius));
    float3 s = SampleBB(uv + float2(0.0,  px.y * SharpRadius));
    float3 e = SampleBB(uv + float2( px.x * SharpRadius, 0.0));
    float3 w = SampleBB(uv + float2(-px.x * SharpRadius, 0.0));
    float3 neighborhoodMin = min(src, min(min(n, s), min(e, w)));
    float3 neighborhoodMax = max(src, max(max(n, s), max(e, w)));

    sharp = YggAntiRingingClamp(src, sharp, neighborhoodMin, neighborhoodMax, HaloSuppression);

    if (LumaOnly)
    {
        float srcL = YggLuma(src);
        float shpL = YggLuma(sharp);

        // FIX: multiplicative luma scale -- preserves channel ratios exactly.
        // src * (shpL / srcL) scales all channels equally -> no hue shift.
        // Old additive method (src + (shpL-srcL).xxx) changed channel ratios.
        float scale = shpL / max(srcL, YGG_EPS);
        sharp = src * scale;

        // Re-clamp to neighborhood after scale to maintain anti-ringing guarantee
        sharp = clamp(sharp, neighborhoodMin, neighborhoodMax);
    }

    // Local contrast assist
    // Local contrast assist -- operates in sRGB space (consistent with LocalMean
    // texture which is also computed from sRGB backbuffer values)
    float3 localContrastColor = src + (src - blurLarge) * localLocalContrast;
    float  localContrastMask  = saturate(YggLocalContrastMask5Tap(ReShade::BackBuffer, uv, px * ContrastRadius) * 1.65);
    float  srcLuma            = YggLuma(src);
    float  lowLumaBoost       = 1.0 - YggLinearStep(0.18, 0.45, srcLuma);
    float  brightSceneRestraint = YggLinearStep(0.52, 0.82, sceneKey);
    float  contrastBlend      = saturate(localContrastMask * (0.34 + lowLumaBoost * 0.22));
    contrastBlend            *= lerp(1.0, 0.72, brightSceneRestraint);

    float3 combined = lerp(sharp, localContrastColor, contrastBlend);

    return float4(saturate(combined), 1.0);
}

technique YggSharp
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggSharp;
    }
}
