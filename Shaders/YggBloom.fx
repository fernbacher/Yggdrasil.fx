#include "ReShade.fxh"
#include "YggCore.fxh"

// =============================================================================
//  YggBloom -- Multi-Pass Bloom (Bright Glow)
//
//  Pass 1: Bright pass -- extract pixels above threshold, downsample 2x
//  Pass 2: Horizontal gaussian blur
//  Pass 3: Vertical gaussian blur
//  Pass 4: Composite -- upsample blurred bloom, tint warm, add to original
//
//  Complements YggHalation (which handles dark-area glow from highlights).
// =============================================================================

// -----------------------------------------------------------------------------
//  UNIFORMS
// -----------------------------------------------------------------------------

uniform float BloomStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Bloom Strength";
    ui_tooltip = "Overall bloom intensity.";
> = 0.40;

uniform float BloomThreshold <
    ui_type = "drag";
    ui_min = 0.3; ui_max = 0.95;
    ui_step = 0.01;
    ui_label = "Bloom Threshold";
    ui_tooltip = "Luminance above which pixels contribute to bloom. Lower = more glow.";
> = 0.72;

uniform float BloomRadius <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 3.0;
    ui_step = 0.1;
    ui_label = "Bloom Radius";
    ui_tooltip = "Gaussian blur spread. Higher = wider, softer glow.";
> = 1.5;

uniform float BloomWarmth <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Bloom Warmth";
    ui_tooltip = "0 = neutral white glow, 1 = warm golden glow.";
> = 0.35;

// -----------------------------------------------------------------------------
//  TEXTURES
// -----------------------------------------------------------------------------

texture2D YggBloomHalfTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8; };
sampler2D YggBloomHalfSampler { Texture = YggBloomHalfTex; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = CLAMP; AddressV = CLAMP; };

texture2D YggBloomTempTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8; };
sampler2D YggBloomTempSampler { Texture = YggBloomTempTex; MinFilter = POINT; MagFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; };

// -----------------------------------------------------------------------------
//  PASS 1 -- Bright Pass (threshold + downsample 2x)
// -----------------------------------------------------------------------------

float4 PS_BloomBright(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize;

    // 2x2 box downsample for anti-aliased bright extraction
    float3 s00 = tex2D(ReShade::BackBuffer, uv + float2(-px.x, -px.y)).rgb;
    float3 s10 = tex2D(ReShade::BackBuffer, uv + float2( px.x, -px.y)).rgb;
    float3 s01 = tex2D(ReShade::BackBuffer, uv + float2(-px.x,  px.y)).rgb;
    float3 s11 = tex2D(ReShade::BackBuffer, uv + float2( px.x,  px.y)).rgb;
    float3 avg = (s00 + s10 + s01 + s11) * 0.25;

    float luma = YggLuma(avg);
    float bright = smoothstep(BloomThreshold * 0.85, BloomThreshold, luma);
    float3 color = avg * bright;

    return float4(saturate(color), 1.0);
}

// -----------------------------------------------------------------------------
//  PASS 2 -- Horizontal Blur (5-tap gaussian)
// -----------------------------------------------------------------------------

float4 PS_BloomBlurH(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize * 2.0; // half-res texture = pixel size is 2x
    float radius = max(BloomRadius, 0.5);
    float2 off = float2(px.x * radius, 0.0);

    // 5-tap gaussian: weights 0.0625, 0.25, 0.375, 0.25, 0.0625
    float3 c0 = tex2D(YggBloomHalfSampler, uv - 2.0 * off).rgb * 0.0625;
    float3 c1 = tex2D(YggBloomHalfSampler, uv - 1.0 * off).rgb * 0.2500;
    float3 c2 = tex2D(YggBloomHalfSampler, uv).rgb * 0.3750;
    float3 c3 = tex2D(YggBloomHalfSampler, uv + 1.0 * off).rgb * 0.2500;
    float3 c4 = tex2D(YggBloomHalfSampler, uv + 2.0 * off).rgb * 0.0625;

    return float4(c0 + c1 + c2 + c3 + c4, 1.0);
}

// -----------------------------------------------------------------------------
//  PASS 3 -- Vertical Blur (5-tap gaussian)
// -----------------------------------------------------------------------------

float4 PS_BloomBlurV(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize * 2.0;
    float radius = max(BloomRadius, 0.5);
    float2 off = float2(0.0, px.y * radius);

    float3 c0 = tex2D(YggBloomTempSampler, uv - 2.0 * off).rgb * 0.0625;
    float3 c1 = tex2D(YggBloomTempSampler, uv - 1.0 * off).rgb * 0.2500;
    float3 c2 = tex2D(YggBloomTempSampler, uv).rgb * 0.3750;
    float3 c3 = tex2D(YggBloomTempSampler, uv + 1.0 * off).rgb * 0.2500;
    float3 c4 = tex2D(YggBloomTempSampler, uv + 2.0 * off).rgb * 0.0625;

    return float4(c0 + c1 + c2 + c3 + c4, 1.0);
}

// -----------------------------------------------------------------------------
//  PASS 4 -- Composite (upsample + tint + add to original)
// -----------------------------------------------------------------------------

float4 PS_BloomComposite(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 src = tex2D(ReShade::BackBuffer, uv).rgb;
    float3 bloom = tex2D(YggBloomHalfSampler, uv).rgb;

    // Tint warm
    float3 warmColor = lerp(float3(1.0, 1.0, 1.0), float3(1.0, 0.82, 0.55), BloomWarmth);
    float3 tintedBloom = bloom * warmColor * BloomStrength;

    // Additive composite
    float3 result = src + tintedBloom;

    return float4(saturate(result), 1.0);
}

// -----------------------------------------------------------------------------
//  TECHNIQUE
// -----------------------------------------------------------------------------

technique YggBloom
    < ui_label   = "YggBloom -- Multi-Pass Bloom";
      ui_tooltip =
        "Multi-pass bloom: bright threshold -> gaussian blur -> warm tint composite.\n"
        "Complements YggHalation (handles bright-to-surrounding glow).\n"
        "4 passes: Bright -> BlurH -> BlurV -> Composite."; >
{
    pass BrightPass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_BloomBright;
        RenderTarget = YggBloomHalfTex;
    }
    pass BlurH
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_BloomBlurH;
        RenderTarget = YggBloomTempTex;
    }
    pass BlurV
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_BloomBlurV;
        RenderTarget = YggBloomHalfTex;
    }
    pass Composite
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_BloomComposite;
    }
}
