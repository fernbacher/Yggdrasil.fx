#include "ReShade.fxh"
#include "YggCore.fxh"

// =============================================================================
//  YggVignette -- Radial Vignette
//
//  Darkens screen edges with an adjustable elliptical falloff.
//  Near-zero performance cost -- single pass, simple math.
// =============================================================================

uniform float VignetteStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Vignette Strength";
    ui_tooltip = "Overall darkening intensity at screen edges.";
> = 0.30;

uniform float VignetteInner <
    ui_type = "drag";
    ui_min = 0.20; ui_max = 0.95;
    ui_step = 0.01;
    ui_label = "Inner Radius";
    ui_tooltip = "Distance from center before darkening begins. Higher = tighter vignette.";
> = 0.55;

uniform float VignetteOuter <
    ui_type = "drag";
    ui_min = 0.30; ui_max = 1.20;
    ui_step = 0.01;
    ui_label = "Outer Radius";
    ui_tooltip = "Distance where vignette reaches full strength. Higher = softer falloff.";
> = 0.95;

uniform float VignetteCenterX <
    ui_type = "drag";
    ui_min = 0.35; ui_max = 0.65;
    ui_step = 0.01;
    ui_label = "Center X";
> = 0.50;

uniform float VignetteCenterY <
    ui_type = "drag";
    ui_min = 0.35; ui_max = 0.65;
    ui_step = 0.01;
    ui_label = "Center Y";
> = 0.50;

uniform float VignetteRoundness <
    ui_type = "drag";
    ui_min = -0.50; ui_max = 0.50;
    ui_step = 0.01;
    ui_label = "Roundness";
    ui_tooltip = "0 = circular. Positive = horizontal oval, negative = vertical oval.";
> = 0.0;

// -----------------------------------------------------------------------------
//  PIXEL SHADER
// -----------------------------------------------------------------------------

float4 PS_YggVignette(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 src = tex2D(ReShade::BackBuffer, uv).rgb;

    // Offset to center
    float2 centered = uv - float2(VignetteCenterX, VignetteCenterY);

    // Aspect-corrected elliptical distance with roundness control
    float aspect = ReShade::ScreenSize.x / max(ReShade::ScreenSize.y, 1.0);
    float2 scale = float2(1.0 + VignetteRoundness, 1.0 - VignetteRoundness);
    float dist = length(centered * float2(aspect, 1.0) * scale);

    // Smooth falloff between inner and outer radii
    float vignette = 1.0 - smoothstep(VignetteInner, VignetteOuter, dist);

    float3 result = src * lerp(1.0, vignette, VignetteStrength);

    return float4(saturate(result), 1.0);
}

// -----------------------------------------------------------------------------
//  TECHNIQUE
// -----------------------------------------------------------------------------

technique YggVignette
    < ui_label   = "YggVignette -- Radial Vignette";
      ui_tooltip =
        "Simple radial vignette with adjustable center, shape, and softness.\n"
        "Single pass, near-zero performance cost."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggVignette;
    }
}
