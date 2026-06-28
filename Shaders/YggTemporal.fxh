#ifndef YGG_TEMPORAL_FXH
#define YGG_TEMPORAL_FXH

#include "ReShade.fxh"
#include "YggCore.fxh"

#ifndef YGG_TEMPORAL_EPS
    #define YGG_TEMPORAL_EPS 1e-5
#endif

float YggMotionMagnitude(float currentDepth, float previousDepth,
                         float currentLuma, float previousLuma,
                         float depthScale, float lumaScale)
{
    float depthDiff = abs(currentDepth - previousDepth) * depthScale;
    float depthMotion = saturate(depthDiff);
    float lumaDiff = abs(currentLuma - previousLuma) * lumaScale;
    float lumaMotion = saturate(lumaDiff);
    return saturate(max(depthMotion, lumaMotion * 1.2));
}

float YggHistoryWeight(float motion, float sensitivity)
{
    return 1.0 / (1.0 + motion * sensitivity * 4.0);
}

float YggColorConsistency(float3 current, float3 history, float threshold)
{
    float3 diff = abs(current - history);
    float maxDiff = max(diff.r, max(diff.g, diff.b));
    return saturate(1.0 - maxDiff / max(threshold, YGG_TEMPORAL_EPS));
}

#endif