#include "ReShade.fxh"
#include "YggCore.fxh"
#include "YggTemporal.fxh"

// =============================================================================
//  YggEdgeAA_Temporal -- Temporal Anti-Aliasing with Motion Gating
//  
//  Pass 1: Render AA to temp texture
//  Pass 2: Blend with history and store new history
//  Pass 3: Copy history to backbuffer (or debug overlay)
// =============================================================================

uniform float TAASharpness <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
    ui_label = "Sharpness";
    ui_tooltip = "Edge AA strength in the current frame. 0.3-0.5 is natural.";
> = 0.38;

uniform float TAAThreshold <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 0.25;
    ui_step = 0.001;
    ui_label = "Edge Threshold";
    ui_tooltip = "Minimum edge contrast before smoothing. 0.025-0.04 recommended.";
> = 0.032;

uniform float TAASubpixel <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Subpixel Smoothing";
    ui_tooltip = "Additional smoothing for fine stair-step patterns.";
> = 0.22;

uniform float TAADetailPreservation <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Detail Preservation";
    ui_tooltip = "Reduces smoothing in high-detail texture regions.";
> = 0.72;

uniform float TAABlurRestraint <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Blur Restraint";
    ui_tooltip = "Keeps smoothing tight so it complements later sharpening.";
> = 0.68;

uniform float TAAHistoryWeight <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "History Blend";
    ui_tooltip = "How much to trust previous frames. Lower = less ghosting, higher = smoother.";
> = 0.85;

uniform float TAAMotionSensitivity <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 8.0;
    ui_step = 0.1;
    ui_label = "Motion Sensitivity";
    ui_tooltip = "Higher = faster motion response (less ghosting, more shimmer). Lower = smoother.";
> = 3.0;

uniform float TAAMotionDepthScale <
    ui_type = "drag";
    ui_min = 5.0; ui_max = 100.0;
    ui_step = 1.0;
    ui_label = "Motion Depth Scale";
    ui_tooltip = "Scales depth difference for motion detection. 20-40 for most games.";
> = 30.0;

uniform float TAAMotionLumaScale <
    ui_type = "drag";
    ui_min = 1.0; ui_max = 20.0;
    ui_step = 0.5;
    ui_label = "Motion Luma Scale";
    ui_tooltip = "Scales luma difference for motion detection. 5-12 for most content.";
> = 8.0;

uniform float TAAGhostThreshold <
    ui_type = "drag";
    ui_min = 0.01; ui_max = 0.30;
    ui_step = 0.005;
    ui_label = "Ghost Reduction Threshold";
    ui_tooltip = "Max color difference allowed in history. Lower = less ghosting.";
> = 0.12;

uniform bool TAAEnableAdaptive <
    ui_type = "checkbox";
    ui_label = "Enable Scene-Adaptive AA";
    ui_tooltip = "Adjusts AA for low-key (dark) and high-key (bright) scenes.";
> = true;

uniform float TAAAdaptiveStrength <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Adaptive AA Strength";
> = 0.38;

// -----------------------------------------------------------------------------
//  DEBUG MODE
// -----------------------------------------------------------------------------

uniform int TAADebugMode <
    ui_type = "combo";
    ui_items = "Disabled\0Motion Only (Red)\0History Weight (Green)\0Confidence (Blue)\0";
    ui_label = "Debug Mode";
    ui_tooltip = "Visualize temporal AA internals. Disabled = normal output.";
> = 0;

// -----------------------------------------------------------------------------
//  Textures
// -----------------------------------------------------------------------------

texture2D YggTAAFrameTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D YggTAAFrameSampler { Texture = YggTAAFrameTex; MinFilter = POINT; MagFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; };

texture2D YggTAAHistoryTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D YggTAAHistorySampler { Texture = YggTAAHistoryTex; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = CLAMP; AddressV = CLAMP; };

texture2D YggSceneKeyTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
sampler2D YggSceneKeySampler { Texture = YggSceneKeyTex; MinFilter = POINT; MagFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; };

// -----------------------------------------------------------------------------
//  PASS 1 -- Edge-Directed AA (current frame)
// -----------------------------------------------------------------------------

float4 PS_TAARender(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 px = ReShade::PixelSize;

    float localStrength  = TAASharpness;
    float localThreshold = TAAThreshold;
    float localSubpixel  = TAASubpixel;

    if (TAAEnableAdaptive)
    {
        float sceneKey    = tex2D(YggSceneKeySampler, float2(0.5, 0.5)).r;
        float lowKeyMask  = YggLowKeyMask(sceneKey, 0.28, 0.45);
        float highKeyMask = YggHighKeyMask(sceneKey, 0.55, 0.72);

        localStrength = YggAdaptiveScalar(localStrength,
            min(localStrength * 1.22 + 0.03, 2.0),
            localStrength * 0.84,
            lowKeyMask, highKeyMask, TAAAdaptiveStrength);

        localThreshold = YggAdaptiveScalar(localThreshold,
            localThreshold * 0.78,
            min(localThreshold * 1.18 + 0.004, 0.25),
            lowKeyMask, highKeyMask, TAAAdaptiveStrength);

        localSubpixel = YggAdaptiveScalar(localSubpixel,
            min(localSubpixel * 1.28 + 0.04, 1.0),
            localSubpixel * 0.88,
            lowKeyMask, highKeyMask, TAAAdaptiveStrength);
    }

    float3 c  = tex2D(ReShade::BackBuffer, uv).rgb;
    float3 n  = tex2D(ReShade::BackBuffer, uv + float2( 0.0, -px.y)).rgb;
    float3 s  = tex2D(ReShade::BackBuffer, uv + float2( 0.0,  px.y)).rgb;
    float3 e  = tex2D(ReShade::BackBuffer, uv + float2( px.x,  0.0)).rgb;
    float3 w  = tex2D(ReShade::BackBuffer, uv + float2(-px.x,  0.0)).rgb;
    float3 ne = tex2D(ReShade::BackBuffer, uv + float2( px.x, -px.y)).rgb;
    float3 nw = tex2D(ReShade::BackBuffer, uv + float2(-px.x, -px.y)).rgb;
    float3 se = tex2D(ReShade::BackBuffer, uv + float2( px.x,  px.y)).rgb;
    float3 sw = tex2D(ReShade::BackBuffer, uv + float2(-px.x,  px.y)).rgb;

    float lC  = YggLuma(c);
    float lN  = YggLuma(n);
    float lS  = YggLuma(s);
    float lE  = YggLuma(e);
    float lW  = YggLuma(w);
    float lNE = YggLuma(ne);
    float lNW = YggLuma(nw);
    float lSE = YggLuma(se);
    float lSW = YggLuma(sw);

    float gx = abs(lE - lW) + abs(lNE - lNW) + abs(lSE - lSW);
    float gy = abs(lN - lS) + abs(lNE - lSE) + abs(lNW - lSW);

    float edgeMag  = max(gx, gy) * 0.3333;
    float edgeMask = saturate((edgeMag - localThreshold)
                    * YggSafeRcp(max(0.22 - localThreshold, 0.001)));

    float textureMask = YggLocalContrastMask5Tap(ReShade::BackBuffer, uv, px);
    float detailGate  = lerp(1.0, 1.0 - textureMask, TAADetailPreservation);

    float dirH = step(gy, gx);
    float dirV = 1.0 - dirH;

    float3 blendH = (e + w) * 0.5;
    float3 blendV = (n + s) * 0.5;
    float3 directionalBlend = lerp(blendV, blendH, dirH);

    float3 diagBlend = (ne + nw + se + sw) * 0.25;
    float3 aaBlend   = lerp(directionalBlend, diagBlend, localSubpixel * 0.35);

    float blurTightness = lerp(1.0, 0.72, TAABlurRestraint);
    float aaAmount = edgeMask * detailGate * localStrength * blurTightness;
    float3 outc    = lerp(c, aaBlend, saturate(aaAmount * 0.6));

    return float4(saturate(outc), 1.0);
}

// -----------------------------------------------------------------------------
//  PASS 2 -- Temporal Accumulation (store history for next frame)
// -----------------------------------------------------------------------------

float4 PS_TAATemporal(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    // Current frame (AA output)
    float3 currentFrame = tex2D(YggTAAFrameSampler, uv).rgb;

    // History (previous frame)
    float4 historySample = tex2D(YggTAAHistorySampler, uv);
    float3 historyColor = historySample.rgb;
    float historyConfidence = historySample.a;

    // Motion detection using 2x2 neighborhood
    float2 px = ReShade::PixelSize;
    float3 c00 = tex2D(ReShade::BackBuffer, uv).rgb;
    float3 c10 = tex2D(ReShade::BackBuffer, uv + float2(px.x, 0.0)).rgb;
    float3 c01 = tex2D(ReShade::BackBuffer, uv + float2(0.0, px.y)).rgb;
    float3 c11 = tex2D(ReShade::BackBuffer, uv + float2(px.x, px.y)).rgb;

    float lumaCenter = YggLuma(c00);
    float lumaNeighborhood = (YggLuma(c10) + YggLuma(c01) + YggLuma(c11)) / 3.0;
    float lumaVariation = abs(lumaCenter - lumaNeighborhood) * TAAMotionLumaScale;
    float lumaMotion = saturate(lumaVariation);

    float d00 = ReShade::GetLinearizedDepth(uv);
    float d10 = ReShade::GetLinearizedDepth(uv + float2(px.x, 0.0));
    float d01 = ReShade::GetLinearizedDepth(uv + float2(0.0, px.y));
    float d11 = ReShade::GetLinearizedDepth(uv + float2(px.x, px.y));

    float depthCenter = d00;
    float depthNeighborhood = (d10 + d01 + d11) / 3.0;
    float depthVariation = abs(depthCenter - depthNeighborhood) * TAAMotionDepthScale;
    float depthMotion = saturate(depthVariation);

    float motion = saturate(max(lumaMotion, depthMotion));

    // History weight
    float historyWeight = YggHistoryWeight(motion, TAAMotionSensitivity);
    historyWeight *= TAAHistoryWeight;

    float colorConsistency = YggColorConsistency(currentFrame, historyColor, TAAGhostThreshold);
    historyWeight *= colorConsistency;
    historyWeight *= saturate(historyConfidence * 1.2);
    historyWeight = clamp(historyWeight, 0.0, 1.0);

    float3 blended = lerp(currentFrame, historyColor, historyWeight);
    float newConfidence = 1.0 - motion * 0.5;

    return float4(saturate(blended), newConfidence);
}

// -----------------------------------------------------------------------------
//  PASS 3 -- Copy to Backbuffer (with optional Debug overlay)
// -----------------------------------------------------------------------------

float4 PS_TAACopy(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float4 history = tex2D(YggTAAHistorySampler, uv);
    float3 output = history.rgb;

    // Debug overlay
    if (TAADebugMode != 0)
    {
        // Recompute motion and weights for debug visualization
        float2 px = ReShade::PixelSize;
        float3 c00 = tex2D(ReShade::BackBuffer, uv).rgb;
        float3 c10 = tex2D(ReShade::BackBuffer, uv + float2(px.x, 0.0)).rgb;
        float3 c01 = tex2D(ReShade::BackBuffer, uv + float2(0.0, px.y)).rgb;
        float3 c11 = tex2D(ReShade::BackBuffer, uv + float2(px.x, px.y)).rgb;

        float lumaCenter = YggLuma(c00);
        float lumaNeighborhood = (YggLuma(c10) + YggLuma(c01) + YggLuma(c11)) / 3.0;
        float lumaVariation = abs(lumaCenter - lumaNeighborhood) * TAAMotionLumaScale;
        float lumaMotion = saturate(lumaVariation);

        float d00 = ReShade::GetLinearizedDepth(uv);
        float d10 = ReShade::GetLinearizedDepth(uv + float2(px.x, 0.0));
        float d01 = ReShade::GetLinearizedDepth(uv + float2(0.0, px.y));
        float d11 = ReShade::GetLinearizedDepth(uv + float2(px.x, px.y));

        float depthCenter = d00;
        float depthNeighborhood = (d10 + d01 + d11) / 3.0;
        float depthVariation = abs(depthCenter - depthNeighborhood) * TAAMotionDepthScale;
        float depthMotion = saturate(depthVariation);

        float motion = saturate(max(lumaMotion, depthMotion));

        float historyWeight = YggHistoryWeight(motion, TAAMotionSensitivity);
        historyWeight *= TAAHistoryWeight;
        float colorConsistency = YggColorConsistency(output, history.rgb, TAAGhostThreshold);
        historyWeight *= colorConsistency;
        historyWeight *= saturate(history.a * 1.2);
        historyWeight = clamp(historyWeight, 0.0, 1.0);

        float confidence = history.a;

        float3 debug;
        switch (TAADebugMode)
        {
            case 1: debug = motion.xxx; break;
            case 2: debug = historyWeight.xxx; break;
            case 3: debug = confidence.xxx; break;
            default: debug = float3(motion, historyWeight, confidence); break;
        }
        output = debug;
    }

    return float4(output, 1.0);
}

// -----------------------------------------------------------------------------
//  Techniques
// -----------------------------------------------------------------------------

technique YggEdgeAA_Temporal
{
    pass RenderAA
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_TAARender;
        RenderTarget = YggTAAFrameTex;
    }

    pass TemporalAccum
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_TAATemporal;
        RenderTarget = YggTAAHistoryTex;
    }

    pass CopyToBackbuffer
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_TAACopy;
    }
}