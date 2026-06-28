#include "ReShade.fxh"
#include "YggCore.fxh"

// =============================================================================
//  YggWhiteBalance -- Kelvin Temperature + Tint
//
//  Adjusts white balance using color temperature (Kelvin) and green/magenta
//  tint. Operates in linear light for physical correctness.
//
//  Temperature algorithm: Tanner Helland's Planckian locus approximation.
//  https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
// =============================================================================

uniform float Temperature <
    ui_type = "drag";
    ui_min = 2000.0; ui_max = 15000.0;
    ui_step = 50.0;
    ui_label = "Temperature (K)";
    ui_tooltip =
        "Color temperature in Kelvin.\n"
        "2000-4000 = warm/candlelight, 5500-6500 = daylight,\n"
        "7000-15000 = cool/overcast.";
> = 6500.0;

uniform float Tint <
    ui_type = "drag";
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Tint";
    ui_tooltip = "Green/magenta shift. Negative = green, positive = magenta.";
> = 0.0;

uniform float WBStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Strength";
    ui_tooltip = "Blend between original and white-balanced output.";
> = 1.0;

// -----------------------------------------------------------------------------
//  Temperature to RGB -- Tanner Helland's algorithm
// -----------------------------------------------------------------------------

float3 TemperatureToRGB(float kelvin)
{
    float3 rgb;
    float temp = kelvin / 100.0;

    // Red
    if (temp <= 66.0)
        rgb.r = 1.0;
    else
        rgb.r = saturate(1.29293618606 * pow(temp - 60.0, -0.1332047592));

    // Green
    if (temp <= 66.0)
        rgb.g = saturate(0.39008157876 * log(temp) - 0.63184144378);
    else
        rgb.g = saturate(1.12989086089 * pow(temp - 60.0, -0.0755148492));

    // Blue
    if (temp >= 66.0)
        rgb.b = 1.0;
    else if (temp <= 19.0)
        rgb.b = 0.0;
    else
        rgb.b = saturate(0.54320678911 * log(temp - 10.0) - 1.19625408914);

    return rgb;
}

// -----------------------------------------------------------------------------
//  PIXEL SHADER
// -----------------------------------------------------------------------------

float4 PS_YggWhiteBalance(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 src_srgb = tex2D(ReShade::BackBuffer, uv).rgb;
    float3 lin = YggToLinear3(src_srgb);

    // Compute temperature correction
    float3 tempRGB = TemperatureToRGB(Temperature);

    // Apply tint: shift green/magenta axis
    // Positive tint -> more magenta (boost R+B relative to G)
    // Negative tint -> more green (boost G relative to R+B)
    float tintFactor = Tint * 0.5;
    tempRGB.r *= (1.0 + tintFactor);
    tempRGB.b *= (1.0 + tintFactor);
    tempRGB.g *= (1.0 - tintFactor);

    // Normalize to preserve luminance
    float tempLuma = YggLuma(tempRGB);
    tempRGB /= max(tempLuma, YGG_EPS);

    // Apply white balance in linear light
    float3 corrected = lin * tempRGB;

    // Blend with original
    float3 blended = lerp(lin, corrected, WBStrength);

    float3 outColor = YggToSRGB3(saturate(blended));
    return float4(outColor, 1.0);
}

// -----------------------------------------------------------------------------
//  TECHNIQUE
// -----------------------------------------------------------------------------

technique YggWhiteBalance
    < ui_label   = "YggWhiteBalance -- Temperature + Tint";
      ui_tooltip =
        "Kelvin color temperature adjustment with green/magenta tint.\n"
        "Operates in linear light. Single pass, near-zero cost."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggWhiteBalance;
    }
}
