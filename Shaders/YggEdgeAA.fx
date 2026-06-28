#include "ReShade.fxh"
#include "YggCore.fxh"

// =============================================================================
//  YggEdgeAA — Edge-Directed Anti-Aliasing
// =============================================================================

uniform float AAEdgeStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Edge AA Strength";
    ui_tooltip = "Primary edge smoothing strength. 0.3-0.5 is natural. Above 1.0 is aggressive.";
> = 0.38;

uniform float AAThreshold <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.25;
    ui_step = 0.001;
    ui_label = "Edge Threshold";
    ui_tooltip = "Minimum edge contrast before smoothing engages. Lower catches more edges. 0.025-0.04 recommended.";
> = 0.032;

uniform float AASubpixel <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Subpixel Smoothing";
    ui_tooltip = "Additional smoothing for fine stair-step and subpixel aliasing patterns.";
> = 0.22;

uniform float AADetailPreservation <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Detail Preservation";
    ui_tooltip = "Reduces smoothing in high-detail texture regions to avoid FXAA-like mush.";
> = 0.72;

uniform float AABlurRestraint <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Blur Restraint";
    ui_tooltip = "Keeps smoothing tight so this complements later sharpening rather than fighting it.";
> = 0.68;

uniform bool EnableAdaptiveAA <
    ui_type = "checkbox";
    ui_label = "Enable Scene-Adaptive AA";
    ui_tooltip = "Meaningfully adjusts edge smoothing for low-key (dark) and high-key (bright) scenes.";
> = true;

uniform float AdaptiveAAStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Adaptive AA Strength";
    ui_tooltip = "How strongly scene brightness shifts AA behavior. 0.3-0.5 is natural.";
> = 0.38;

float3 AASample(float2 uv)
{
    return tex2D(ReShade::BackBuffer, uv).rgb;
}

float4 PS_YggEdgeAA(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize;

    float localStrength  = AAEdgeStrength;
    float localThreshold = AAThreshold;
    float localSubpixel  = AASubpixel;

    if (EnableAdaptiveAA)
    {
        float sceneKey    = YggSceneKey9Tap(ReShade::BackBuffer);
        float lowKeyMask  = YggLowKeyMask(sceneKey, 0.28, 0.45);
        float highKeyMask = YggHighKeyMask(sceneKey, 0.55, 0.72);

        // Low-key (dark scene): lower threshold to catch more edges,
        // boost strength and subpixel — aliasing is more visible in dark content.
        // High-key (bright scene): raise threshold slightly, reduce strength —
        // natural contrast makes aliasing less perceptible.
        localStrength = YggAdaptiveScalar(localStrength,
            min(localStrength * 1.22 + 0.03, 2.0),   // low-key: stronger
            localStrength * 0.84,                      // high-key: weaker
            lowKeyMask, highKeyMask, AdaptiveAAStrength);

        localThreshold = YggAdaptiveScalar(localThreshold,
            localThreshold * 0.78,                     // low-key: lower threshold (catch more)
            min(localThreshold * 1.18 + 0.004, 0.25), // high-key: higher threshold (catch less)
            lowKeyMask, highKeyMask, AdaptiveAAStrength);

        localSubpixel = YggAdaptiveScalar(localSubpixel,
            min(localSubpixel * 1.28 + 0.04, 1.0),   // low-key: more subpixel help
            localSubpixel * 0.88,                      // high-key: less needed
            lowKeyMask, highKeyMask, AdaptiveAAStrength);
    }

    // 3x3 neighborhood
    float3 c  = AASample(uv);
    float3 n  = AASample(uv + float2( 0.0,  -px.y));
    float3 s  = AASample(uv + float2( 0.0,   px.y));
    float3 e  = AASample(uv + float2( px.x,  0.0));
    float3 w  = AASample(uv + float2(-px.x,  0.0));
    float3 ne = AASample(uv + float2( px.x, -px.y));
    float3 nw = AASample(uv + float2(-px.x, -px.y));
    float3 se = AASample(uv + float2( px.x,  px.y));
    float3 sw = AASample(uv + float2(-px.x,  px.y));

    float lC  = YggLuma(c);
    float lN  = YggLuma(n);
    float lS  = YggLuma(s);
    float lE  = YggLuma(e);
    float lW  = YggLuma(w);
    float lNE = YggLuma(ne);
    float lNW = YggLuma(nw);
    float lSE = YggLuma(se);
    float lSW = YggLuma(sw);

    // Sobel-style gradient magnitude
    float gx = abs(lE - lW) + abs(lNE - lNW) + abs(lSE - lSW);
    float gy = abs(lN - lS) + abs(lNE - lSE) + abs(lNW - lSW);

    float edgeMag  = max(gx, gy) * 0.3333;
    float edgeMask = saturate((edgeMag - localThreshold)
                    * YggSafeRcp(max(0.22 - localThreshold, 0.001)));

    // Detail preservation: reduce AA in high-texture regions
    float textureMask = YggLocalContrastMask5Tap(ReShade::BackBuffer, uv, px);
    float detailGate  = lerp(1.0, 1.0 - textureMask, AADetailPreservation);

    // Direction-aware blend: smooth along the edge direction
    float dirH = step(gy, gx);  // 1 = horizontal edge, blend vertically
    float dirV = 1.0 - dirH;    // 1 = vertical edge, blend horizontally

    float3 blendH = (e + w) * 0.5;
    float3 blendV = (n + s) * 0.5;
    float3 directionalBlend = lerp(blendV, blendH, dirH);

    // Diagonal blend for subpixel patterns
    float3 diagBlend = (ne + nw + se + sw) * 0.25;
    float3 aaBlend   = lerp(directionalBlend, diagBlend, localSubpixel * 0.35);

    float blurTightness = lerp(1.0, 0.72, AABlurRestraint);

    // FIX: removed hardcoded * 0.5 multiplier that was halving effective range.
    // Using * 0.6 cap instead — gives full usable range while keeping restraint
    // against over-smoothing at strength 2.0.
    float aaAmount = edgeMask * detailGate * localStrength * blurTightness;
    float3 outc    = lerp(c, aaBlend, saturate(aaAmount * 0.6));

    return float4(saturate(outc), 1.0);
}

technique YggEdgeAA
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggEdgeAA;
    }
}
