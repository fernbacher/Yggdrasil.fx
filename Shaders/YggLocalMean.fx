#include "ReShade.fxh"
#include "YggCore.fxh"

// =============================================================================
//  YggLocalMean — Shared Local Mean Texture (Blur Pre-Pass)
//
//  Computes a separable blur of the backbuffer and stores it in YggLocalMeanTex.
//  YggSharp and YggClarity read from this texture instead of doing their own
//  neighborhood sampling, saving texture reads.
//
//  Load order: must run before YggSharp and YggClarity.
// =============================================================================

uniform float BlurRadius <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 4.0;
    ui_step = 0.25;
    ui_label = "Blur Radius (px)";
    ui_tooltip = "Radius of the separable blur. Should match the largest radius used in Sharp/Clarity (default 2.0).";
> = 2.0;

// -----------------------------------------------------------------------------
//  Textures
// -----------------------------------------------------------------------------

texture2D YggLocalMeanTemp { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture2D YggLocalMeanTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };

sampler2D YggLocalMeanTempSampler { Texture = YggLocalMeanTemp; MinFilter = POINT; MagFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; };
sampler2D YggLocalMeanTexSampler { Texture = YggLocalMeanTex; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = CLAMP; AddressV = CLAMP; };

// -----------------------------------------------------------------------------
//  Horizontal Blur Pass
// -----------------------------------------------------------------------------

float4 PS_BlurH(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize;
    float radius = max(BlurRadius, 0.5);
    float2 offset = float2(radius * px.x, 0.0);

    // 5-tap box blur (equal weights)
    float3 c0 = tex2D(ReShade::BackBuffer, uv - 2.0 * offset).rgb;
    float3 c1 = tex2D(ReShade::BackBuffer, uv - 1.0 * offset).rgb;
    float3 c2 = tex2D(ReShade::BackBuffer, uv).rgb;
    float3 c3 = tex2D(ReShade::BackBuffer, uv + 1.0 * offset).rgb;
    float3 c4 = tex2D(ReShade::BackBuffer, uv + 2.0 * offset).rgb;

    float3 result = (c0 + c1 + c2 + c3 + c4) / 5.0;
    return float4(result, 1.0);
}

// -----------------------------------------------------------------------------
//  Vertical Blur Pass
// -----------------------------------------------------------------------------

float4 PS_BlurV(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize;
    float radius = max(BlurRadius, 0.5);
    float2 offset = float2(0.0, radius * px.y);

    // 5-tap box blur
    float3 c0 = tex2D(YggLocalMeanTempSampler, uv - 2.0 * offset).rgb;
    float3 c1 = tex2D(YggLocalMeanTempSampler, uv - 1.0 * offset).rgb;
    float3 c2 = tex2D(YggLocalMeanTempSampler, uv).rgb;
    float3 c3 = tex2D(YggLocalMeanTempSampler, uv + 1.0 * offset).rgb;
    float3 c4 = tex2D(YggLocalMeanTempSampler, uv + 2.0 * offset).rgb;

    float3 result = (c0 + c1 + c2 + c3 + c4) / 5.0;
    return float4(result, 1.0);
}

// -----------------------------------------------------------------------------
//  Technique
// -----------------------------------------------------------------------------

technique YggLocalMean
{
    pass BlurH
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_BlurH;
        RenderTarget = YggLocalMeanTemp;
    }
    pass BlurV
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_BlurV;
        RenderTarget = YggLocalMeanTex;
    }
}
