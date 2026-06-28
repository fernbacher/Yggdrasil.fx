#include "ReShade.fxh"
#include "YggCore.fxh"

// =============================================================================
//  YggAtmos — Atmospheric Separation / Dehaze
// =============================================================================

uniform float AtmosStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Atmospheric Separation";
    ui_tooltip = "Restores depth in hazy, veiled, or low-contrast scenes without brute-force global contrast.";
> = 0.32;

uniform float AtmosRadius <
    ui_type = "drag";
    ui_min = 1.0; ui_max = 8.0;
    ui_step = 0.25;
    ui_label = "Atmos Radius";
    ui_tooltip = "Sampling radius for local haze reference.";
> = 3.0;

uniform float VeilThreshold <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.25;
    ui_step = 0.001;
    ui_label = "Veil Threshold";
    ui_tooltip = "How much local flatness is interpreted as haze rather than real structure.";
> = 0.042;

uniform float MoodPreservation <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Mood Preservation";
    ui_tooltip = "Prevents over-aggressive dehazing so foggy or dark scenes keep their atmosphere.";
> = 0.64;

uniform float ShadowRestraint <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Shadow Restraint";
    ui_tooltip = "Limits enhancement in deep shadows to avoid fake depth or black crush.";
> = 0.58;

uniform float HighlightRestraint <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Highlight Restraint";
    ui_tooltip = "Limits enhancement in bright surfaces so haze reduction doesn't turn chalky.";
> = 0.42;

uniform bool LumaOnlyAtmos <
    ui_type = "checkbox";
    ui_label = "Luma-Only Atmosphere Recovery";
    ui_tooltip = "Applies atmospheric separation through luminance to reduce color shifting risk.";
> = true;

uniform bool EnableAdaptiveAtmos <
    ui_type = "checkbox";
    ui_label = "Enable Scene-Adaptive Atmosphere";
    ui_tooltip = "Adjusts atmospheric recovery by scene brightness.";
> = true;

uniform float AdaptiveAtmosStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Adaptive Atmosphere Strength";
> = 0.42;

float3 AtmosSample(float2 uv)
{
    return tex2D(ReShade::BackBuffer, uv).rgb;
}

float3 AtmosAvgCross(float2 uv, float2 px, float radius)
{
    float2 r = px * radius;
    float3 a = AtmosSample(uv + float2(-r.x,  0.0));
    float3 b = AtmosSample(uv + float2( r.x,  0.0));
    float3 c = AtmosSample(uv + float2( 0.0, -r.y));
    float3 d = AtmosSample(uv + float2( 0.0,  r.y));
    return (a + b + c + d) * 0.25;
}

float4 PS_YggAtmos(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize;

    float localStrength           = AtmosStrength;
    float localMood               = MoodPreservation;
    float localShadowRestraint    = ShadowRestraint;
    float localHighlightRestraint = HighlightRestraint;

    if (EnableAdaptiveAtmos)
    {
        float sceneKey    = YggSceneKey9Tap(ReShade::BackBuffer);
        float lowKeyMask  = YggLowKeyMask(sceneKey, 0.28, 0.45);
        float highKeyMask = YggHighKeyMask(sceneKey, 0.55, 0.72);

        localStrength           = YggAdaptiveScalar(localStrength,
            localStrength * 1.22 + 0.03, localStrength * 0.90,
            lowKeyMask, highKeyMask, AdaptiveAtmosStrength);

        localMood               = YggAdaptiveScalar(localMood,
            min(localMood * 1.06 + 0.02, 1.0), localMood * 0.92,
            lowKeyMask, highKeyMask, AdaptiveAtmosStrength);

        localShadowRestraint    = YggAdaptiveScalar(localShadowRestraint,
            min(localShadowRestraint * 1.06 + 0.02, 1.0), localShadowRestraint * 0.94,
            lowKeyMask, highKeyMask, AdaptiveAtmosStrength);

        localHighlightRestraint = YggAdaptiveScalar(localHighlightRestraint,
            localHighlightRestraint * 0.94,
            min(localHighlightRestraint * 1.16 + 0.02, 1.0),
            lowKeyMask, highKeyMask, AdaptiveAtmosStrength);
    }

    float3 src    = AtmosSample(uv);
    float3 avg    = AtmosAvgCross(uv, px, AtmosRadius);

    // Linearize for perceptually correct local contrast math
    float3 srcLin = YggToLinear3(src);
    float3 avgLin = YggToLinear3(avg);

    float srcL      = YggLuma(srcLin);
    float avgL      = YggLuma(avgLin);
    float lumaDelta = srcL - avgL;

    float localMask = YggLocalContrastMask5Tap(ReShade::BackBuffer, uv, px * max(AtmosRadius * 0.75, 1.0));
    float edgeMask  = YggEdgeMask5Tap(ReShade::BackBuffer, uv, px * max(AtmosRadius * 0.75, 1.0));

    // Veil gate: engage only where local flatness (small lumaDelta) suggests haze
    float veilMask = 1.0 - YggLinearStep(VeilThreshold * 0.4, VeilThreshold, abs(lumaDelta));

    // Structure gate: reduce atmos on real edges (they're not haze, they're content)
    float structureMask = saturate(1.0 - edgeMask * 0.55);

    float shadowGate    = 1.0 - (1.0 - YggLinearStep(0.08, 0.35, srcL)) * localShadowRestraint;
    float highlightGate = 1.0 - YggLinearStep(0.60, 1.00, srcL) * localHighlightRestraint;

    // FIX: simplified atmosMask. Old formula had (0.92 + (1-localMask)*0.48) which
    // created a range of 0.92-1.40 — the >1.0 portion was amplifying the mask
    // unpredictably in flat regions. New version: localMask directly gates atmos
    // as a structure gate (high local contrast = not haze = less enhancement).
    float structureGate = saturate(1.0 - localMask * 0.85);
    float atmosMask     = saturate(veilMask * structureMask * structureGate
                                   * shadowGate * highlightGate
                                   * (1.0 - localMood * 0.32));

    float gain = localStrength * atmosMask;

    // Apply in linear, re-encode to sRGB
    float3 linOut;
    if (LumaOnlyAtmos)
        linOut = srcLin + lumaDelta.xxx * gain;
    else
        linOut = srcLin + (srcLin - avgLin) * gain;

    return float4(saturate(YggToSRGB3(linOut)), 1.0);
}

technique YggAtmos
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggAtmos;
    }
}
