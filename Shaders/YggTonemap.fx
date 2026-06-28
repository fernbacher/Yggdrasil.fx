#include "ReShade.fxh"
#include "YggCore.fxh"

texture2D YggSceneKeyTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
sampler2D YggSceneKeySampler { Texture = YggSceneKeyTex; MinFilter = POINT; MagFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; };

// =============================================================================
//  YggTonemap -- AgX-Inspired SDR Tonemapper
// =============================================================================

uniform float Exposure <
    ui_type = "drag";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Exposure (EV)";
    ui_tooltip = "Global exposure compensation. Negative = darker, positive = brighter.";
> = 0.0;

uniform float Shoulder <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Shoulder Rolloff";
    ui_tooltip = "How highlights roll off. 0.5 = natural film, 1.0 = more aggressive, 0.0 = hard clip.";
> = 0.65;

uniform float Toe <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Shadow Lift";
    ui_tooltip = "Lifts shadows while preserving blacks. Higher = more detail in dark areas.";
> = 0.12;

uniform float Contrast <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Contrast";
    ui_tooltip = "S-curve contrast applied before tonemapping.";
> = 1.05;

uniform float WhitePoint <
    ui_type = "drag";
    ui_min = 1.0; ui_max = 20.0;
    ui_step = 0.1;
    ui_label = "White Point (nits)";
    ui_tooltip = "Peak brightness target in nits. 8-12 for SDR, 6-8 for darker displays, 15+ for HDR simulation.";
> = 10.0;

uniform bool SceneAdaptiveExposure <
    ui_type = "checkbox";
    ui_label = "Scene-Adaptive Exposure";
    ui_tooltip = "Automatically adjusts exposure based on overall scene brightness.";
> = true;

uniform float AdaptationSpeed <
    ui_type = "drag";
    ui_min = 0.01; ui_max = 0.50;
    ui_step = 0.01;
    ui_label = "Adaptation Speed";
    ui_tooltip = "Temporal smoothing rate. Lower = slower adaptation (cinematic). Higher = faster.";
> = 0.10;

uniform bool LumaOnlyTonemap <
    ui_type = "checkbox";
    ui_label = "Luma-Only Tonemap";
    ui_tooltip = "Apply tonemap to luminance only, preserving hue and saturation. Recommended on.";
> = true;

// =============================================================================
//  TEXTURES
// =============================================================================

texture2D YggTonemapHistoryTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D YggTonemapHistorySampler { Texture = YggTonemapHistoryTex; MinFilter = POINT; MagFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; };

// =============================================================================
//  AgX Tone Curve -- based on Troy Sobotka's algorithm
//
//  Unlike Reinhard or simple ACES, AgX maps linear values through a
//  polynomial that has a natural shoulder and toe, preserving color
//  integrity across the entire range.
//
//  Reference: https://github.com/sobotka/AgX
// =============================================================================

float AgX_Evaluate(float x, float shoulder, float toe, float whitePoint)
{
    // Guard against division by zero
    float eps = 1e-6;
    x = max(x, 0.0);

    // Normalize by white point
    float xNorm = x / max(whitePoint, eps);

    // AgX base polynomial: f(x) = (x * (a*x + b)) / (x * (c*x + d) + e)
    // a, b, c, d, e tuned for filmic response
    const float a = 1.204;
    const float b = 0.340;
    const float c = -0.020;
    const float d = 0.438;
    const float e = 0.061;

    // Apply the polynomial
    float num = xNorm * (a * xNorm + b);
    float den = xNorm * (c * xNorm + d) + e;
    float y = num / max(den, eps);

    // Shoulder rolloff -- modifies the polynomial response in highlights
    // Higher shoulder = more aggressive rolloff (softer shoulder)
    if (shoulder > 0.01)
    {
        float shoulderFactor = 1.0 + shoulder * 0.8;
        float xShoulder = xNorm * shoulderFactor;
        float numS = xShoulder * (a * xShoulder + b);
        float denS = xShoulder * (c * xShoulder + d) + e;
        float yS = numS / max(denS, eps);
        // Blend between base and shoulder-adjusted
        float blend = saturate(xNorm * 2.5 - 0.5);
        y = lerp(y, yS, blend * shoulder);
    }

    // Toe lift -- dark regions get a gentle lift
    if (toe > 0.01)
    {
        float toeFactor = toe * 0.6;
        float toeCurve = y / max(y + toeFactor * (1.0 - y), eps);
        // Apply more to dark areas, none to bright
        float toeBlend = 1.0 - saturate(xNorm * 4.0 - 0.5);
        y = lerp(y, toeCurve, toeBlend * toe);
    }

    // Clamp to [0, 1] range (SDR output)
    return saturate(y);
}

// =============================================================================
//  PASS 1 -- Compute temporally-smoothed exposure
//  Reads YggSceneKeySampler, blends with history, writes to history texture.
// =============================================================================

float4 PS_TonemapComputeExposure(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float prevExpo = tex2D(YggTonemapHistorySampler, float2(0.5, 0.5)).r;

    float targetExpo = Exposure;
    if (SceneAdaptiveExposure)
    {
        float sceneKey = tex2D(YggSceneKeySampler, float2(0.5, 0.5)).r;
        float targetLog = log2(0.18);
        float sceneLog = log2(max(sceneKey, 0.001));
        float deltaEV = targetLog - sceneLog;
        targetExpo = Exposure + clamp(deltaEV, -1.5, 1.5);
    }

    // Temporal lerp -- smooth adaptation toward target
    // AdaptationSpeed now directly controls the lerp factor per frame
    float smoothedExpo = lerp(prevExpo, targetExpo, saturate(AdaptationSpeed));

    return float4(smoothedExpo.xxx, 1.0);
}

// =============================================================================
//  PASS 2 -- Apply tonemap using smoothed exposure
// =============================================================================

float4 PS_TonemapApply(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    // Sample and linearize
    float3 src_srgb = tex2D(ReShade::BackBuffer, uv).rgb;
    float3 lin = YggToLinear3(src_srgb);

    // Read smoothed exposure from history texture
    float expo = tex2D(YggTonemapHistorySampler, float2(0.5, 0.5)).r;

    // Apply exposure (2^EV)
    float exposureScale = pow(2.0, expo);
    float3 exposed = lin * exposureScale;

    // Pre-tonemap contrast (s-curve in linear)
    float pivot = 0.18; // photographic midgray
    float3 contrastAdj = (exposed - pivot) * Contrast + pivot;
    contrastAdj = max(contrastAdj, 0.0);

    // Extract luminance and chroma
    float luma = YggLuma(contrastAdj);

    // Apply AgX tonemap to luminance
    // Internal range expansion: Toe and Shoulder UI sliders span 0-1 / 0-2,
    // but the AgX polynomial expects wider input ranges. The scaling factors
    // below map the user-friendly slider ranges to the polynomial's domain.
    float toeAdjusted = Toe * 1.2;
    float shoulderAdjusted = Shoulder * 1.5;
    float whitePointAdjusted = WhitePoint;
    float tonemappedLuma = AgX_Evaluate(luma, shoulderAdjusted, toeAdjusted, whitePointAdjusted);

    // Apply to color
    float3 result;
    if (LumaOnlyTonemap)
    {
        // Preserve chroma ratio -- scale RGB proportionally to new luma
        float scale = tonemappedLuma / max(luma, 1e-6);
        result = contrastAdj * scale;
    }
    else
    {
        // Full RGB tonemap -- each channel individually
        float3 tonemapped = float3(
            AgX_Evaluate(contrastAdj.r, shoulderAdjusted, toeAdjusted, whitePointAdjusted),
            AgX_Evaluate(contrastAdj.g, shoulderAdjusted, toeAdjusted, whitePointAdjusted),
            AgX_Evaluate(contrastAdj.b, shoulderAdjusted, toeAdjusted, whitePointAdjusted)
        );
        // Reconstruct luma after per-channel tonemap to avoid desaturation
        float newLuma = YggLuma(tonemapped);
        float lumaScale = tonemappedLuma / max(newLuma, 1e-6);
        result = tonemapped * lumaScale;
    }

    // Encode to sRGB
    float3 outColor = YggToSRGB3(saturate(result));

    return float4(outColor, 1.0);
}

technique YggTonemap
    < ui_label   = "YggTonemap -- AgX SDR Tonemapper";
      ui_tooltip =
        "AgX-inspired filmic tonemapper with temporal exposure smoothing.\n"
        "Pass 1 blends scene exposure with previous frame to eliminate pops.\n"
        "Pass 2 applies the tonemap with shoulder, toe, and contrast controls."; >
{
    pass ComputeExposure
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_TonemapComputeExposure;
        RenderTarget = YggTonemapHistoryTex;
    }

    pass Apply
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_TonemapApply;
    }
}
