#include "ReShade.fxh"
#include "YggCore.fxh"

// =============================================================================
//  YggHalation — Warm Highlight Bleed (Filmic Glow)
//
//  FIX v2: Properly compute bright mask from luma for each neighbor sample.
//  No more sampling red channel as if it were the mask. Now computes luma
//  for each offset, then bright = max(0, luma - threshold).
//  Dark mask is steep (only deep shadows get the glow).
// =============================================================================

uniform float HalationStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.5;
    ui_step = 0.01;
    ui_label = "Strength";
    ui_tooltip = "Overall intensity of the halation glow.";
> = 0.18;

uniform float HalationThreshold <
    ui_type = "drag";
    ui_min = 0.4; ui_max = 0.9;
    ui_step = 0.01;
    ui_label = "Threshold";
    ui_tooltip = "Luminance above which highlights are considered bright. Lower = more glow.";
> = 0.72;

uniform float HalationRadius <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 3.0;
    ui_step = 0.25;
    ui_label = "Radius (px)";
    ui_tooltip = "Spread distance of the glow. Smaller = tighter, less screen-wide bleed.";
> = 1.2;

uniform float Warmth <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Warmth";
    ui_tooltip = "0 = neutral white glow, 1 = golden/orange filmic glow.";
> = 0.68;

uniform float ShadowDepth <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.5;
    ui_step = 0.01;
    ui_label = "Shadow Depth";
    ui_tooltip = "How deep into shadows the glow penetrates. 0 = only pure black, 0.3 = into mid‑shadows.";
> = 0.18;

uniform bool EnableAdaptiveHalation <
    ui_type = "checkbox";
    ui_label = "Enable Scene-Adaptive Halation";
> = true;

uniform float AdaptiveHalationStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Adaptive Strength";
> = 0.30;

// -----------------------------------------------------------------------------
//  PIXEL SHADER
// -----------------------------------------------------------------------------

float4 PS_YggHalation(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 src_srgb = tex2D(ReShade::BackBuffer, uv).rgb;
    float3 lin = YggToLinear3(src_srgb);

    float localStrength = HalationStrength;
    if (EnableAdaptiveHalation)
    {
        float sceneKey    = YggSceneKey9Tap(ReShade::BackBuffer);
        float lowKeyMask  = YggLowKeyMask(sceneKey, 0.28, 0.45);
        float highKeyMask = YggHighKeyMask(sceneKey, 0.55, 0.72);
        localStrength = YggAdaptiveScalar(localStrength,
            min(localStrength * 1.20, 1.5),
            max(localStrength * 0.80, 0.0),
            lowKeyMask, highKeyMask, AdaptiveHalationStrength);
    }

    // ---- Compute center bright value ----
    float lumaC = YggLuma(lin);
    float brightC = max(0.0, lumaC - HalationThreshold);
    brightC = brightC / max(1.0 - HalationThreshold, 0.001);

    // ---- Helper: sample bright at offset ----
    float2 px = ReShade::PixelSize * HalationRadius;

    // We'll sample the backbuffer at each offset, linearize, compute luma, then bright.
    // To keep it simple and cheap, we sample the sRGB backbuffer and linearize on the fly.
    // For performance, we could sample the already‑linearized version, but we don't have it.
    // This is still cheap: 9 taps * linearization.

    float3 col_off;
    float luma_off, bright_off;

    // Horizontal neighbors
    col_off = tex2D(ReShade::BackBuffer, uv + float2( px.x, 0.0)).rgb;
    luma_off = YggLuma(YggToLinear3(col_off));
    bright_off = max(0.0, luma_off - HalationThreshold) / max(1.0 - HalationThreshold, 0.001);
    float bR1 = bright_off;

    col_off = tex2D(ReShade::BackBuffer, uv + float2(-px.x, 0.0)).rgb;
    luma_off = YggLuma(YggToLinear3(col_off));
    bright_off = max(0.0, luma_off - HalationThreshold) / max(1.0 - HalationThreshold, 0.001);
    float bL1 = bright_off;

    col_off = tex2D(ReShade::BackBuffer, uv + float2( 2.0 * px.x, 0.0)).rgb;
    luma_off = YggLuma(YggToLinear3(col_off));
    bright_off = max(0.0, luma_off - HalationThreshold) / max(1.0 - HalationThreshold, 0.001);
    float bR2 = bright_off;

    col_off = tex2D(ReShade::BackBuffer, uv + float2(-2.0 * px.x, 0.0)).rgb;
    luma_off = YggLuma(YggToLinear3(col_off));
    bright_off = max(0.0, luma_off - HalationThreshold) / max(1.0 - HalationThreshold, 0.001);
    float bL2 = bright_off;

    // Vertical neighbors
    col_off = tex2D(ReShade::BackBuffer, uv + float2(0.0,  px.y)).rgb;
    luma_off = YggLuma(YggToLinear3(col_off));
    bright_off = max(0.0, luma_off - HalationThreshold) / max(1.0 - HalationThreshold, 0.001);
    float bD1 = bright_off;

    col_off = tex2D(ReShade::BackBuffer, uv + float2(0.0, -px.y)).rgb;
    luma_off = YggLuma(YggToLinear3(col_off));
    bright_off = max(0.0, luma_off - HalationThreshold) / max(1.0 - HalationThreshold, 0.001);
    float bU1 = bright_off;

    col_off = tex2D(ReShade::BackBuffer, uv + float2(0.0,  2.0 * px.y)).rgb;
    luma_off = YggLuma(YggToLinear3(col_off));
    bright_off = max(0.0, luma_off - HalationThreshold) / max(1.0 - HalationThreshold, 0.001);
    float bD2 = bright_off;

    col_off = tex2D(ReShade::BackBuffer, uv + float2(0.0, -2.0 * px.y)).rgb;
    luma_off = YggLuma(YggToLinear3(col_off));
    bright_off = max(0.0, luma_off - HalationThreshold) / max(1.0 - HalationThreshold, 0.001);
    float bU2 = bright_off;

    // ---- Gaussian‑like 5‑tap blur (weights: 0.1, 0.2, 0.4, 0.2, 0.1) ----
    float blurH = 0.1 * bL2 + 0.2 * bL1 + 0.4 * brightC + 0.2 * bR1 + 0.1 * bR2;
    float blurV = 0.1 * bU2 + 0.2 * bU1 + 0.4 * brightC + 0.2 * bD1 + 0.1 * bD2;

    float blur = (blurH + blurV) * 0.5;

    // ---- Tint warm ----
    float3 warmColor = lerp(float3(1.0, 1.0, 1.0), float3(1.0, 0.7, 0.3), Warmth);
    float3 glow = blur * warmColor * localStrength;

    // ---- Dark mask: only affect very dark regions ----
    // ShadowDepth controls the falloff: 0 = only pure black, 0.3 = up to mid‑shadows
    float darkMask = 1.0 - smoothstep(0.0, ShadowDepth * 1.5 + 0.05, lumaC);
    // Also ensure we don't add glow to areas that are already bright (safety)
    darkMask = saturate(min(darkMask, 1.0 - lumaC * 1.5)); // clamp — prevents negative at high luma

    glow *= darkMask;

    // ---- Composite ----
    float3 result_lin = lin + glow;

    // ---- Re‑encode ----
    float3 outColor = YggToSRGB3(saturate(result_lin));

    return float4(outColor, 1.0);
}

technique YggHalation
    < ui_label   = "YggHalation — Filmic Glow";
      ui_tooltip =
        "Warm highlight bleed into deep shadows.\n"
        "Now correctly computes bright mask from luma per sample.\n"
        "Only affects very dark areas (controlled by ShadowDepth)."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggHalation;
    }
}
