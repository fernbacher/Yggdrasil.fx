#include "ReShade.fxh"
#include "YggCore.fxh"

texture2D YggLocalMeanTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D YggLocalMeanSampler { Texture = YggLocalMeanTex; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = CLAMP; AddressV = CLAMP; };

// =============================================================================
//  YggClarity — Mid-Frequency Local Contrast Enhancement
// =============================================================================

uniform float ClarityStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Clarity Strength";
    ui_tooltip = "Mid-frequency local contrast and form-separation strength.";
> = 0.31;

uniform float ClarityRadius <
    ui_type = "drag";
    ui_min = 1.0; ui_max = 6.0;
    ui_step = 0.25;
    ui_label = "Clarity Radius";
    ui_tooltip = "Sampling radius in pixels for local contrast reference.";
> = 2.0;

uniform float EdgeRestraint <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Edge Restraint";
    ui_tooltip = "Reduces clarity on already hard edges so it complements sharpening instead of replacing it.";
> = 0.68;

uniform float ShadowClarityBias <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Shadow Clarity Bias";
    ui_tooltip = "Extra clarity in darker midtones without lifting blacks.";
> = 0.26;

uniform float HighlightRestraint <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Highlight Restraint";
    ui_tooltip = "Prevents clarity from over-accentuating bright surfaces and hotspots.";
> = 0.48;

uniform bool LumaOnlyClarity <
    ui_type = "checkbox";
    ui_label = "Luma-Only Clarity";
    ui_tooltip = "Applies clarity through luminance only to reduce color pollution risk.";
> = true;

uniform bool EnableAdaptiveClarity <
    ui_type = "checkbox";
    ui_label = "Enable Scene-Adaptive Clarity";
    ui_tooltip = "Adjusts clarity for low-key and high-key scenes.";
> = true;

uniform float AdaptiveClarityStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Adaptive Clarity Strength";
> = 0.40;

float4 PS_YggClarity(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize;

    float localClarityStrength    = ClarityStrength;
    float localShadowBias         = ShadowClarityBias;
    float localHighlightRestraint = HighlightRestraint;

    if (EnableAdaptiveClarity)
    {
        float sceneKey    = YggSceneKey9Tap(ReShade::BackBuffer);
        float lowKeyMask  = YggLowKeyMask(sceneKey, 0.28, 0.45);
        float highKeyMask = YggHighKeyMask(sceneKey, 0.55, 0.72);

        localClarityStrength    = YggAdaptiveScalar(localClarityStrength,
            localClarityStrength * 1.22 + 0.02,
            localClarityStrength * 0.88,
            lowKeyMask, highKeyMask, AdaptiveClarityStrength);

        localShadowBias         = YggAdaptiveScalar(localShadowBias,
            localShadowBias * 1.34 + 0.03,
            localShadowBias * 0.84,
            lowKeyMask, highKeyMask, AdaptiveClarityStrength);

        localHighlightRestraint = YggAdaptiveScalar(localHighlightRestraint,
            localHighlightRestraint * 0.92,
            min(localHighlightRestraint * 1.24 + 0.03, 1.0),
            lowKeyMask, highKeyMask, AdaptiveClarityStrength);
    }

    // Sample the backbuffer and the shared local mean
    float3 src_srgb = tex2D(ReShade::BackBuffer, uv).rgb;
    float3 avg_srgb = tex2D(YggLocalMeanSampler, uv).rgb;

    // Linearize for perceptually correct local contrast math
    float3 srcLin = YggToLinear3(src_srgb);
    float3 avgLin = YggToLinear3(avg_srgb);

    float srcL      = YggLuma(srcLin);
    float avgL      = YggLuma(avgLin);
    float localDelta = srcL - avgL;

    float edge      = YggEdgeMask5Tap(ReShade::BackBuffer, uv, px * max(ClarityRadius, 1.0));
    float localMask = YggLocalContrastMask5Tap(ReShade::BackBuffer, uv, px * max(ClarityRadius, 1.0));

    float edgeGate       = lerp(1.0, 1.0 - edge, EdgeRestraint);
    float highlightGate  = 1.0 - YggLinearStep(0.60, 1.00, srcL) * localHighlightRestraint;
    float shadowGate     = 1.0 + (1.0 - YggLinearStep(0.10, 0.45, srcL)) * localShadowBias;

    // Clarity mask — zero local contrast = zero clarity, no global lift
    float clarityMask = smoothstep(0.0, 0.08, localMask);
    float clarityGain = localClarityStrength * edgeGate * highlightGate * shadowGate * clarityMask;

    // Apply in linear, re-encode to sRGB
    float3 linOut;
    if (LumaOnlyClarity)
        linOut = srcLin + localDelta.xxx * clarityGain;
    else
        linOut = srcLin + (srcLin - avgLin) * clarityGain;

    return float4(saturate(YggToSRGB3(linOut)), 1.0);
}

technique YggClarity
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggClarity;
    }
}