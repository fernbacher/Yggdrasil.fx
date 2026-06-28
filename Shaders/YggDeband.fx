#include "ReShade.fxh"
#include "YggCore.fxh"

// =============================================================================
//  YggDeband — Perceptual Debanding
// =============================================================================

uniform float DebandStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Deband Strength";
    ui_tooltip = "How strongly near-flat gradients are smoothed toward their band average.";
> = 0.28;

uniform float DebandThresholdL <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.10;
    ui_step = 0.0005;
    ui_label = "Luma Threshold";
    ui_tooltip = "Maximum luma difference to consider a sample part of the same band. 0.015-0.025 for most content.";
> = 0.018;

uniform float DebandThresholdC <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.10;
    ui_step = 0.0005;
    ui_label = "Chroma Threshold";
    ui_tooltip = "Maximum chroma difference. Catches color banding in saturated gradients missed by luma-only detection.";
> = 0.010;

uniform float DebandRange <
    ui_type = "drag";
    ui_min = 1.0; ui_max = 16.0;
    ui_step = 0.5;
    ui_label = "Deband Range (px)";
    ui_tooltip = "Sampling radius in pixels. Wider catches broader banding. 6-12 for most compressed content.";
> = 8.0;

uniform int DebandIterations <
    ui_type = "drag";
    ui_min = 1; ui_max = 4;
    ui_step = 1;
    ui_label = "Iterations";
    ui_tooltip = "Randomized sample rounds. 2 covers most banding. 3 for heavy compression artifacts.";
> = 2;

uniform float EdgeProtection <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Edge Protection";
    ui_tooltip = "Reduces debanding near real image edges. Prevents smoothing of intentional contrast boundaries.";
> = 0.82;

uniform float GrainStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
    ui_label = "Grain / Dither Strength";
    ui_tooltip = "Triangular dither after smoothing to prevent re-banding on 8-bit output.";
> = 0.010;

uniform bool EnableAdaptiveDeband <
    ui_type = "checkbox";
    ui_label = "Enable Scene-Adaptive Deband";
    ui_tooltip = "Adjusts debanding aggressiveness based on overall scene brightness.";
> = true;

uniform float AdaptiveDebandStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Adaptive Deband Strength";
> = 0.35;

uniform uint DebandFrameCount < source = "framecount"; >;

float4 PS_YggDeband(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px        = ReShade::PixelSize;
    float2 pixelPos  = uv / px;

    float localStrength  = DebandStrength;
    float localThreshL   = DebandThresholdL;
    float localThreshC   = DebandThresholdC;
    float localGrain     = GrainStrength;

    if (EnableAdaptiveDeband)
    {
        float sceneKey    = YggSceneKey9Tap(ReShade::BackBuffer);
        float lowKeyMask  = YggLowKeyMask(sceneKey, 0.28, 0.45);
        float highKeyMask = YggHighKeyMask(sceneKey, 0.55, 0.72);

        localStrength = YggAdaptiveScalar(localStrength,
            localStrength * 0.88,
            min(localStrength * 1.18 + 0.01, 2.0),
            lowKeyMask, highKeyMask, AdaptiveDebandStrength);

        localThreshL  = YggAdaptiveScalar(localThreshL,
            localThreshL * 0.92,
            min(localThreshL * 1.18 + 0.002, 0.10),
            lowKeyMask, highKeyMask, AdaptiveDebandStrength);

        localThreshC  = YggAdaptiveScalar(localThreshC,
            localThreshC * 0.92,
            min(localThreshC * 1.18 + 0.001, 0.10),
            lowKeyMask, highKeyMask, AdaptiveDebandStrength);

        localGrain    = YggAdaptiveScalar(localGrain,
            localGrain * 0.85,
            min(localGrain * 1.15 + 0.001, 1.0),
            lowKeyMask, highKeyMask, AdaptiveDebandStrength);
    }

    float3 src  = tex2D(ReShade::BackBuffer, uv).rgb;
    float  srcL = YggLuma(src);
    float  srcC = YggChroma(src);

    float  edge        = YggEdgeMask5Tap(ReShade::BackBuffer, uv, px * max(DebandRange * 0.5, 1.0));
    float  edgeProtect = lerp(1.0, 1.0 - edge, EdgeProtection);

    // =========================================================================
    //  RANDOMIZED ANGULAR SAMPLING
    //  Each iteration picks a random angle from IGN and a random distance
    //  within [0.25, 1.0] * DebandRange. Temporal jitter from frame count
    //  provides additional coverage over time.
    // =========================================================================

    float3 accumColor = 0.0.xxx;
    float  hits       = 0.0;

    // Explicitly unrolled 4 iterations — no loops with tex2D (gradient instruction safety)
    float FC = float(DebandFrameCount & 0xFF);
    float3 sDB; float2 offDB; float aDB, dDB;
    // iter 0
    aDB = YggIGN(pixelPos+float2(0.0*73.1+FC*17.3,0.0*37.7))*2.0*YGG_PI;
    dDB = (0.25+YggIGN(pixelPos+float2(0.0*113.9,0.0*59.3+FC*11.7))*0.75)*DebandRange;
    offDB = float2(cos(aDB),sin(aDB))*dDB*px;
    sDB=tex2D(ReShade::BackBuffer,uv+offDB).rgb;
    if(abs(YggLuma(sDB)-srcL)<localThreshL&&abs(YggChroma(sDB)-srcC)<localThreshC){accumColor+=sDB;hits+=1.0;}
    // iter 1
    aDB = YggIGN(pixelPos+float2(1.0*73.1+FC*17.3,1.0*37.7))*2.0*YGG_PI;
    dDB = (0.25+YggIGN(pixelPos+float2(1.0*113.9,1.0*59.3+FC*11.7))*0.75)*DebandRange;
    offDB = float2(cos(aDB),sin(aDB))*dDB*px;
    sDB=tex2D(ReShade::BackBuffer,uv+offDB).rgb;
    if(abs(YggLuma(sDB)-srcL)<localThreshL&&abs(YggChroma(sDB)-srcC)<localThreshC){accumColor+=sDB;hits+=1.0;}
    // iter 2
    aDB = YggIGN(pixelPos+float2(2.0*73.1+FC*17.3,2.0*37.7))*2.0*YGG_PI;
    dDB = (0.25+YggIGN(pixelPos+float2(2.0*113.9,2.0*59.3+FC*11.7))*0.75)*DebandRange;
    offDB = float2(cos(aDB),sin(aDB))*dDB*px;
    sDB=tex2D(ReShade::BackBuffer,uv+offDB).rgb;
    if(abs(YggLuma(sDB)-srcL)<localThreshL&&abs(YggChroma(sDB)-srcC)<localThreshC){accumColor+=sDB;hits+=1.0;}
    // iter 3
    aDB = YggIGN(pixelPos+float2(3.0*73.1+FC*17.3,3.0*37.7))*2.0*YGG_PI;
    dDB = (0.25+YggIGN(pixelPos+float2(3.0*113.9,3.0*59.3+FC*11.7))*0.75)*DebandRange;
    offDB = float2(cos(aDB),sin(aDB))*dDB*px;
    sDB=tex2D(ReShade::BackBuffer,uv+offDB).rgb;
    if(abs(YggLuma(sDB)-srcL)<localThreshL&&abs(YggChroma(sDB)-srcC)<localThreshC){accumColor+=sDB;hits+=1.0;}

    float3 result = src;

    if (hits > 0.0)
    {
        float3 bandAvg = accumColor / hits;
        float  blend   = saturate(hits / 4.0) * localStrength * edgeProtect;
        result         = lerp(src, bandAvg, blend * 0.65);
    }

    // Post-deband dither
    float ditherEdgeGate = saturate(1.0 - edge * 1.5) * saturate(0.35 + (hits / max(float(DebandIterations), 1.0)));
    float3 dither = YggTriangularDither(uv * ReShade::ScreenSize.xy, localGrain);
    result += dither * ditherEdgeGate;

    return float4(saturate(result), 1.0);
}

technique YggDeband
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggDeband;
    }
}
