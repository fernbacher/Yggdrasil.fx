#include "ReShade.fxh"
#include "YggCore.fxh"

uniform float GrainStrength <
    ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.005;
    ui_label = "Grain Strength";
    ui_tooltip = "Overall grain intensity. 0.04-0.10 is natural film range.";
> = 0.055;

uniform float GrainSize <
    ui_type = "drag"; ui_min = 0.5; ui_max = 3.0; ui_step = 0.05;
    ui_label = "Grain Size";
    ui_tooltip = "1.0 = pixel-scale. Higher = coarser grain clumps.";
> = 1.0;

uniform float ShadowGrain <
    ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Shadow Grain Scale";
    ui_tooltip = "Grain multiplier in shadows. Real film has less grain in deep blacks.";
> = 0.45;

uniform float HighlightGrain <
    ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Highlight Grain Scale";
    ui_tooltip = "Grain multiplier in highlights. Real film grain fades in blown areas.";
> = 0.30;

uniform bool ChromaGrain <
    ui_type = "checkbox";
    ui_label = "Chroma Grain";
    ui_tooltip = "Adds slight per-channel variation for color grain. More filmic, slightly more cost.";
> = true;

uniform bool Temporal <
    ui_type = "checkbox";
    ui_label = "Temporal Jitter";
    ui_tooltip = "Rotates grain pattern per frame. Prevents static texture appearance.";
> = true;

uniform uint GrainFrame < source = "framecount"; >;

float4 PS_YggFilmGrain(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 src  = tex2D(ReShade::BackBuffer, uv).rgb;
    float  luma = YggLuma(src);
    float2 px   = pos.xy / GrainSize;

    // Luminance-weighted grain envelope — peaks in midtones, fades at extremes
    // Real film: grain is a silver halide process, most visible at medium exposure
    float midtoneMask = 1.0 - abs(luma * 2.0 - 1.0);                     // peaks at luma=0.5
    float shadowMask  = lerp(ShadowGrain,   1.0, smoothstep(0.0, 0.35, luma));
    float highlightMask = lerp(HighlightGrain, 1.0, 1.0 - smoothstep(0.65, 1.0, luma));
    float envelope    = midtoneMask * shadowMask * highlightMask;

    float frameOff = Temporal ? frac(float(GrainFrame) / 256.0) * 256.0 * 0.61803398875 : 0.0;

    // Triangular noise (two uniform samples summed = triangle distribution)
    // Triangle distribution matches silver halide grain statistics better than uniform
    float n1 = YggHash12(px + float2(frameOff, 0.0));
    float n2 = YggHash12(px + float2(0.0, frameOff + 3.7));
    float grain = (n1 + n2 - 1.0) * GrainStrength * envelope;

    float3 result;
    if (ChromaGrain)
    {
        float n3 = YggHash12(px + float2(frameOff + 7.3, frameOff + 2.1));
        float n4 = YggHash12(px + float2(frameOff + 1.9, frameOff + 8.6));
        float n5 = YggHash12(px + float2(frameOff + 5.5, frameOff + 4.4));
        float n6 = YggHash12(px + float2(frameOff + 9.1, frameOff + 6.2));
        float gr = (n3 + n4 - 1.0) * GrainStrength * envelope * 0.55;
        float gg = (n5 + n6 - 1.0) * GrainStrength * envelope * 0.55;
        // B channel gets slightly more chroma grain (film blue layer is grainier)
        float n7 = YggHash12(px + float2(frameOff + 3.3, frameOff + 7.7));
        float n8 = YggHash12(px + float2(frameOff + 6.6, frameOff + 1.1));
        float gb = (n7 + n8 - 1.0) * GrainStrength * envelope * 0.70;
        result = src + float3(grain + gr, grain + gg, grain + gb);
    }
    else
    {
        result = src + grain.xxx;
    }

    return float4(saturate(result), 1.0);
}

technique YggFilmGrain_DX9
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggFilmGrain;
    }
}
