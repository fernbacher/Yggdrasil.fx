#include "ReShade.fxh"
#include "YggCore.fxh"

// =============================================================================
//  YggColor — Perceptual Color Grading with Presets
// =============================================================================

// -----------------------------------------------------------------------------
//  PRESET SELECTION & INTENSITY
// -----------------------------------------------------------------------------

uniform int Preset <
    ui_type = "combo";
    ui_items = "Custom\0Natural\0Vivid\0FakeHDR\0";
    ui_label = "Preset";
    ui_tooltip = "Quick starting point. Custom = use individual sliders below.";
> = 0;  // default to Custom — user configures their own grade

uniform float Intensity <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Intensity";
    ui_tooltip = "Blend between original and graded output. 1 = full preset/sliders, 0 = original.";
> = 1.0;

// -----------------------------------------------------------------------------
//  ORIGINAL YGGCOLOR UNIFORMS (kept for Custom mode)
// -----------------------------------------------------------------------------

uniform float Vibrance <
    ui_type = "drag";
    ui_min = -1.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Smart Vibrance";
    ui_tooltip = "Adaptive saturation boost favoring less-saturated colors. Uses Oklab chroma.";
> = 0.14;

uniform float Saturation <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Global Saturation";
> = 1.00;

uniform float Brightness <
    ui_type = "drag";
    ui_min = -0.5; ui_max = 0.5;
    ui_step = 0.001;
    ui_label = "Brightness";
> = 0.0;

uniform float Contrast <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 2.0;
    ui_step = 0.001;
    ui_label = "Contrast";
> = 1.03;

uniform float ContrastPivot <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
    ui_label = "Contrast Pivot";
    ui_tooltip = "Linear light tonal midpoint. 0.18 = photographic midgray.";
> = 0.18;

uniform float MidtoneDensity <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Midtone Density";
> = 0.20;

uniform float ShadowCompression <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Shadow Compression";
> = 0.10;

uniform float HighlightCompression <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Highlight Compression";
> = 0.16;

uniform float Gamma <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 2.5;
    ui_step = 0.001;
    ui_label = "Gamma";
> = 1.00;

uniform float BlackPoint <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.25;
    ui_step = 0.0005;
    ui_label = "Black Point";
> = 0.00;

uniform float WhitePoint <
    ui_type = "drag";
    ui_min = 0.75; ui_max = 1.0;
    ui_step = 0.0005;
    ui_label = "White Point";
> = 1.00;

uniform float RangeSoftness <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Range Softness";
> = 0.35;

uniform float HighlightProtection <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.5;
    ui_step = 0.001;
    ui_label = "Highlight Protection";
> = 0.18;

uniform float ShadowProtection <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.5;
    ui_step = 0.001;
    ui_label = "Shadow Protection";
> = 0.12;

uniform float VibranceHighlightProtect <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.5;
    ui_step = 0.001;
    ui_label = "Vibrance Highlight Protect";
> = 0.20;

uniform float VibranceShadowProtect <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.5;
    ui_step = 0.001;
    ui_label = "Vibrance Shadow Protect";
> = 0.10;

uniform float VibranceSatLimit <
    ui_type = "drag";
    ui_min = 0.05; ui_max = 0.40;
    ui_step = 0.005;
    ui_label = "Vibrance Saturation Limit";
> = 0.22;

uniform float LumaPreservation <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Luma Preservation";
> = 1.00;

uniform float BrightSatRestraint <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Bright Region Saturation Restraint";
> = 0.14;

uniform float BrightSatStart <
    ui_type = "drag";
    ui_min = 0.4; ui_max = 0.95;
    ui_step = 0.01;
    ui_label = "Bright Region Start";
> = 0.66;

uniform float BrightSatEnd <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Bright Region End";
> = 0.92;

uniform float HighlightGuard <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Highlight Guard";
> = 0.16;

uniform float HighlightGuardStart <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 0.98;
    ui_step = 0.01;
    ui_label = "Highlight Guard Start";
> = 0.72;

uniform float HighlightGuardEnd <
    ui_type = "drag";
    ui_min = 0.6; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Highlight Guard End";
> = 0.96;

uniform float HighlightGuardSatInfluence <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Highlight Guard Saturation Influence";
> = 0.65;

uniform bool StylizedContentBias <
    ui_type = "checkbox";
    ui_label = "Stylized Content Bias";
> = false;

uniform bool EnableAdaptiveTone <
    ui_type = "checkbox";
    ui_label = "Enable Adaptive Tone Bias";
> = true;

uniform bool EnableSceneAdaptation <
    ui_type = "checkbox";
    ui_label = "Enable Scene Adaptation";
> = true;

uniform float SceneAdaptStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Scene Adaptation Strength";
> = 0.45;

uniform float AdaptiveToneStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Adaptive Tone Bias Strength";
> = 0.35;

// -----------------------------------------------------------------------------
//  PRESET DEFINITIONS (matches YggFakeHDR parameters)
// -----------------------------------------------------------------------------

struct PresetParams
{
    float contrast;
    float saturation;
    float vibrance;
    float shadowCompression;
    float highlightCompression;
    float midtoneDensity;
    float highlightProtection;
    float shadowProtection;
};

PresetParams GetPresetParams(int preset)
{
    PresetParams p;
    // Default to Custom (all zeros, will be ignored)
    p.contrast = 0.0;
    p.saturation = 0.0;
    p.vibrance = 0.0;
    p.shadowCompression = 0.0;
    p.highlightCompression = 0.0;
    p.midtoneDensity = 0.0;
    p.highlightProtection = 0.0;
    p.shadowProtection = 0.0;

    switch (preset)
    {
        case 1: // Natural
            p.contrast              = 1.04;
            p.saturation            = 1.02;
            p.vibrance              = 0.06;
            p.shadowCompression     = 0.04;
            p.highlightCompression  = 0.04;
            p.midtoneDensity        = 0.06;
            p.highlightProtection   = 0.08;
            p.shadowProtection      = 0.06;
            break;
        case 2: // Vivid
            p.contrast              = 1.18;
            p.saturation            = 1.25;
            p.vibrance              = 0.18;
            p.shadowCompression     = 0.14;
            p.highlightCompression  = 0.12;
            p.midtoneDensity        = 0.18;
            p.highlightProtection   = 0.12;
            p.shadowProtection      = 0.10;
            break;
        case 3: // FakeHDR
            p.contrast              = 1.36;
            p.saturation            = 1.48;
            p.vibrance              = 0.28;
            p.shadowCompression     = 0.24;
            p.highlightCompression  = 0.22;
            p.midtoneDensity        = 0.28;
            p.highlightProtection   = 0.16;
            p.shadowProtection      = 0.14;
            break;
        case 0: // Custom — fall through, keep zeros
        default:
            break;
    }
    return p;
}

// -----------------------------------------------------------------------------
//  PIXEL SHADER
// -----------------------------------------------------------------------------

texture2D YggColorTex : COLOR;
sampler2D YggColorSampler { Texture = YggColorTex; };

float3 ApplyAdaptiveToneBias(float3 original, float3 graded, float strength)
{
    return YggToneRestraint(original, graded, 0.18, 0.34, 0.68, 0.86, strength);
}

float4 PS_YggColor(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 src = tex2D(ReShade::BackBuffer, uv).rgb;

    // ---- Linearize ----
    float3 lin = YggToLinear3(src);
    float3 col = lin;

    // ---- Get preset parameters (if not Custom) ----
    PresetParams presetParams = GetPresetParams(Preset);
    bool usePreset = (Preset != 0);

    // ---- Scene adaptation (computed on sRGB backbuffer) ----
    float sceneKey    = 0.5;
    float lowKeyMask  = 0.0;
    float highKeyMask = 0.0;

    float localMidtoneDensity       = MidtoneDensity;
    float localShadowCompression    = ShadowCompression;
    float localHighlightCompression = HighlightCompression;
    float localBrightSatRestraint   = BrightSatRestraint;
    float localHighlightGuard       = HighlightGuard;
    float localVibrance             = Vibrance;
    float localContrast             = Contrast;
    float localSaturation           = Saturation;
    float localHighlightProtection  = HighlightProtection;
    float localShadowProtection     = ShadowProtection;

    if (EnableSceneAdaptation)
    {
        sceneKey     = YggSceneKey9Tap(ReShade::BackBuffer);
        lowKeyMask   = YggLowKeyMask(sceneKey, 0.28, 0.45);
        highKeyMask  = YggHighKeyMask(sceneKey, 0.55, 0.72);

        localMidtoneDensity       = YggAdaptiveScalar(localMidtoneDensity,       localMidtoneDensity * 0.65,        min(localMidtoneDensity * 1.10 + 0.02, 1.0),  lowKeyMask, highKeyMask, SceneAdaptStrength);
        localShadowCompression    = YggAdaptiveScalar(localShadowCompression,    localShadowCompression * 0.60,     min(localShadowCompression * 1.05 + 0.01, 1.0), lowKeyMask, highKeyMask, SceneAdaptStrength);
        localHighlightCompression = YggAdaptiveScalar(localHighlightCompression, localHighlightCompression * 0.75,  min(localHighlightCompression * 1.15 + 0.02, 1.0), lowKeyMask, highKeyMask, SceneAdaptStrength);
        localBrightSatRestraint   = YggAdaptiveScalar(localBrightSatRestraint,   localBrightSatRestraint * 0.70,    min(localBrightSatRestraint * 1.20 + 0.02, 1.0),  lowKeyMask, highKeyMask, SceneAdaptStrength);
        localHighlightGuard       = YggAdaptiveScalar(localHighlightGuard,       localHighlightGuard * 0.70,        min(localHighlightGuard * 1.20 + 0.02, 1.0),      lowKeyMask, highKeyMask, SceneAdaptStrength);
        localVibrance             = YggAdaptiveScalar(localVibrance,             localVibrance * 0.80,              min(localVibrance * 1.10 + 0.01, 2.0),            lowKeyMask, highKeyMask, SceneAdaptStrength);
        localContrast             = YggAdaptiveScalar(localContrast,             localContrast * 0.80,              min(localContrast * 1.15, 2.0),                    lowKeyMask, highKeyMask, SceneAdaptStrength);
        localSaturation           = YggAdaptiveScalar(localSaturation,           localSaturation * 0.80,            min(localSaturation * 1.15, 2.0),                  lowKeyMask, highKeyMask, SceneAdaptStrength);
        localHighlightProtection  = YggAdaptiveScalar(localHighlightProtection,  localHighlightProtection * 0.80,   min(localHighlightProtection * 1.10 + 0.02, 0.5), lowKeyMask, highKeyMask, SceneAdaptStrength);
        localShadowProtection     = YggAdaptiveScalar(localShadowProtection,     localShadowProtection * 0.80,      min(localShadowProtection * 1.10 + 0.02, 0.5),    lowKeyMask, highKeyMask, SceneAdaptStrength);
    }

    // ---- Apply preset overrides ----
    if (usePreset)
    {
        localContrast             = presetParams.contrast;
        localSaturation           = presetParams.saturation;
        localVibrance             = presetParams.vibrance;
        localShadowCompression    = presetParams.shadowCompression;
        localHighlightCompression = presetParams.highlightCompression;
        localMidtoneDensity       = presetParams.midtoneDensity;
        localHighlightProtection  = presetParams.highlightProtection;
        localShadowProtection     = presetParams.shadowProtection;
    }

    if (StylizedContentBias)
    {
        localMidtoneDensity       = saturate(localMidtoneDensity + 0.04);
        localHighlightCompression = saturate(localHighlightCompression + 0.03);
        localBrightSatRestraint   = saturate(localBrightSatRestraint + 0.04);
        localHighlightGuard       = saturate(localHighlightGuard + 0.05);
        localVibrance             = localVibrance * 0.95;
    }

    // ---- Tonal operations ----
    col = YggSoftRangeRemap(col, BlackPoint, WhitePoint, RangeSoftness);
    col = YggToneCurve(col, localShadowCompression, localHighlightCompression,
                       localMidtoneDensity, ContrastPivot);
    col = YggApplyBrightnessContrast(col, Brightness, localContrast, ContrastPivot);
    col = YggApplyGamma(col, Gamma);

    // ---- Chroma operations ----
    col = YggSmartVibrance(col, localVibrance,
                           VibranceHighlightProtect, VibranceShadowProtect,
                           VibranceSatLimit);
    col = YggScaleChromaProtected(col, localSaturation, LumaPreservation);
    col = YggBrightRegionSatRestraint(lin, col, localBrightSatRestraint,
                                      BrightSatStart, BrightSatEnd);
    col = YggHighlightGuard(lin, col, localHighlightGuard,
                            HighlightGuardStart, HighlightGuardEnd,
                            HighlightGuardSatInfluence);

    // ---- Protection ----
    col = YggProtectHighlightsShadows(lin, col, localShadowProtection, localHighlightProtection);

    if (EnableSceneAdaptation)
    {
        float lowShadowRestore = lowKeyMask * SceneAdaptStrength * 0.35;
        col = YggAdaptiveShadowLift(lin, col, lowShadowRestore, 0.00, 0.28);
    }

    if (EnableAdaptiveTone)
    {
        float toneStrength = AdaptiveToneStrength;
        if (EnableSceneAdaptation)
        {
            toneStrength = YggAdaptiveScalar(toneStrength,
                toneStrength * 0.75,
                min(toneStrength * 1.10 + 0.02, 1.0),
                lowKeyMask, highKeyMask, SceneAdaptStrength);
        }
        col = ApplyAdaptiveToneBias(lin, col, toneStrength);
    }

    col = saturate(col);

    // ---- Intensity blend (between original linear and graded) ----
    float3 blended = lerp(lin, col, Intensity);

    // ---- Encode to sRGB ----
    float3 outColor = YggToSRGB3(blended);

    return float4(saturate(outColor), 1.0);
}

// -----------------------------------------------------------------------------
//  TECHNIQUE
// -----------------------------------------------------------------------------

technique YggColor
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggColor;
    }
}
