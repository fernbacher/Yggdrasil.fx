#include "ReShade.fxh"
#include "YggCore.fxh"

// 3D LUT applier. Export a neutral 32x32x32 LUT from ReShade's LUT shader,
// grade it in any software (Resolve, Photoshop, etc), save as PNG, point here.
// Near-zero runtime cost — single 3D texture lookup per pixel.

#ifndef YGG_LUT_SIZE
    #define YGG_LUT_SIZE 32
#endif

uniform float LUTStrength <
    ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "LUT Strength";
    ui_tooltip = "Blend between original and LUT output. 1.0 = full LUT.";
> = 1.0;

uniform bool LUTLinearSample <
    ui_type = "checkbox";
    ui_label = "Linear Interpolation";
    ui_tooltip = "Trilinear interpolation between LUT cells. Smoother at 32x32 size. Recommended on.";
> = true;

texture2D YggLUTTex < source = "YggNeutral.png"; >
{
    Width  = YGG_LUT_SIZE * YGG_LUT_SIZE;
    Height = YGG_LUT_SIZE;
    Format = RGBA8;
};

sampler2D YggLUTSamplerPoint
{
    Texture   = YggLUTTex;
    MinFilter = POINT; MagFilter = POINT;
    AddressU  = CLAMP; AddressV  = CLAMP;
};

sampler2D YggLUTSamplerLinear
{
    Texture   = YggLUTTex;
    MinFilter = LINEAR; MagFilter = LINEAR;
    AddressU  = CLAMP; AddressV  = CLAMP;
};

float3 ApplyLUT(float3 c, sampler2D lut)
{
    // Scale input to LUT cell centers
    float  scale  = float(YGG_LUT_SIZE - 1) / float(YGG_LUT_SIZE);
    float  offset = 0.5 / float(YGG_LUT_SIZE);
    c             = saturate(c) * scale + offset;

    // 2D atlas layout: B selects tile column, RG index within tile
    float  bSlice = c.b * float(YGG_LUT_SIZE - 1);
    float  bLow   = floor(bSlice);
    float  bHigh  = min(bLow + 1.0, float(YGG_LUT_SIZE - 1));
    float  bFrac  = bSlice - bLow;

    float2 uvLow  = float2((bLow  + c.r) / float(YGG_LUT_SIZE), c.g);
    float2 uvHigh = float2((bHigh + c.r) / float(YGG_LUT_SIZE), c.g);

    float3 colLow  = tex2D(lut, uvLow).rgb;
    float3 colHigh = tex2D(lut, uvHigh).rgb;

    return lerp(colLow, colHigh, bFrac);
}

float4 PS_YggLUT(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 src    = tex2D(ReShade::BackBuffer, uv).rgb;
    float3 luted  = LUTLinearSample
                  ? ApplyLUT(src, YggLUTSamplerLinear)
                  : ApplyLUT(src, YggLUTSamplerPoint);

    return float4(saturate(lerp(src, luted, LUTStrength)), 1.0);
}

technique YggLUT
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggLUT;
    }
}
