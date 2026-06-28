#ifndef YGG_TEMPORAL_FXH
#define YGG_TEMPORAL_FXH

#include "ReShade.fxh"
#include "YggCore.fxh"

#ifndef YGG_TEMPORAL_EPS
    #define YGG_TEMPORAL_EPS 1e-5
#endif

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