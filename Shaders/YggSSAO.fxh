#ifndef YGG_SSAO_FXH
#define YGG_SSAO_FXH

// =============================================================================
//  YggSSAO Kernel — Depth, Normal Reconstruction, GTAO Helpers
//
//  Why this exists as a separate header:
//    SSAO requires non-trivial depth math that shouldn't pollute YggCore.
//    Depth linearization, normal reconstruction from depth derivatives,
//    and horizon angle integration are SSAO-specific primitives.
//
//  Normal reconstruction from depth:
//    ReShade has no normal buffer. We reconstruct surface normals by taking
//    cross products of depth gradient vectors. This is an approximation but
//    is sufficient for screen-space AO — errors only appear at silhouette
//    edges where AO would be unreliable anyway.
//
//  Depth reversal detection:
//    Some games/APIs give a reversed depth buffer (1=near, 0=far).
//    We detect this by sampling center vs edge and checking which end
//    is sky. If reversed, we flip our comparisons accordingly.
// =============================================================================

#include "ReShade.fxh"

#ifndef YGG_SSAO_EPS
    #define YGG_SSAO_EPS 1e-5
#endif

// -----------------------------------------------------------------------------
//  Depth helpers
// -----------------------------------------------------------------------------

float YggGetDepth(float2 uv)
{
    return ReShade::GetLinearizedDepth(uv);
}

// Check if a pixel is sky/background (at or near maximum depth)
bool YggIsSky(float depth)
{
    return depth > 0.9995;
}

// Detect depth buffer reversal heuristically:
// Sample top-center (likely sky) and bottom-center (likely ground/geometry).
// In a standard depth buffer, sky = high value (~1.0), ground = lower.
// In a reversed buffer, sky = low value (~0.0), ground = higher.
// Returns 1.0 if standard, -1.0 if reversed.
float YggDetectDepthDir(sampler2D depthSampler)
{
    // We can't sample an arbitrary depth sampler — use GetLinearizedDepth
    float top    = ReShade::GetLinearizedDepth(float2(0.5, 0.05));
    float bottom = ReShade::GetLinearizedDepth(float2(0.5, 0.95));
    float center = ReShade::GetLinearizedDepth(float2(0.5, 0.5));

    // Sky pixels at top should be max depth in standard buffer
    // If top < center, buffer may be reversed
    // This is a heuristic — not perfect for all scenes
    return (top > center) ? 1.0 : -1.0;
}

// -----------------------------------------------------------------------------
//  View-space position reconstruction from depth + UV
//  We don't have true camera matrices so we reconstruct a pseudo view-space
//  position sufficient for normal estimation and AO radius scaling.
// -----------------------------------------------------------------------------

float3 YggReconstructPosition(float2 uv, float depth)
{
    // Map UV to [-1,1] clip space XY
    float2 clipXY = uv * float2(2.0, -2.0) + float2(-1.0, 1.0);
    // Z is linearized depth remapped to [0,1] view space
    return float3(clipXY * depth, depth);
}

// -----------------------------------------------------------------------------
//  Normal reconstruction from depth buffer derivatives
//
//  Uses a 4-tap cross (not central difference) to avoid bias at edges.
//  Reconstructs two tangent vectors from the depth gradient and computes
//  their cross product to get the surface normal.
//
//  Quality is limited by depth precision — works well on smooth surfaces,
//  degrades on thin geometry and silhouette edges. Acceptable for SSAO.
// -----------------------------------------------------------------------------

float3 YggReconstructNormal(float2 uv, float2 px, float centerDepth)
{
    float2 uvR = uv + float2( px.x, 0.0);
    float2 uvL = uv + float2(-px.x, 0.0);
    float2 uvU = uv + float2(0.0, -px.y);
    float2 uvD = uv + float2(0.0,  px.y);

    float dR = YggGetDepth(uvR);
    float dL = YggGetDepth(uvL);
    float dU = YggGetDepth(uvU);
    float dD = YggGetDepth(uvD);

    // Prefer the sample closer in depth to center (reduces edge artifacts)
    float dH = (abs(dR - centerDepth) < abs(dL - centerDepth)) ? dR : dL;
    float dV = (abs(dU - centerDepth) < abs(dD - centerDepth)) ? dU : dD;

    float3 pC  = YggReconstructPosition(uv,  centerDepth);
    float3 pR  = YggReconstructPosition(uvR, dH);
    float3 pD  = YggReconstructPosition(uvD, dV);

    float3 tangentX = pR - pC;
    float3 tangentY = pD - pC;

    float3 normal = cross(tangentX, tangentY);

    // Normalize safely
    float len = length(normal);
    if (len < YGG_SSAO_EPS) return float3(0.0, 0.0, 1.0);
    return normal / len;
}

// -----------------------------------------------------------------------------
//  GTAO horizon angle integration helper
//
//  GTAO (Jimenez et al. 2016) replaces point sampling with a horizon angle
//  integral along screen-space directions. For each direction:
//    1. March along the direction finding the maximum horizon angle h
//    2. AO contribution = sin(h) - sin(bias)
//
//  Advantage over hemisphere SSAO: better handles self-occlusion,
//  no sampling noise pattern, works correctly at low step counts.
//  Same ALU cost as hemisphere SSAO at equivalent sample counts.
// -----------------------------------------------------------------------------

// Finds maximum horizon angle along a screen-space direction
// Returns the sine of the horizon angle (used directly for AO integration)
float YggHorizonAngle(float2 uv, float2 direction, float centerDepth,
                      float3 normal, float radius, float2 px,
                      float thicknessGate, float bias,
                      int steps)
{
    float maxSinH = sin(bias); // start at bias angle
    float stepSize = radius / float(steps);

    [unroll]
    for (int s = 1; s <= steps; s++)
    {
        float2 offset    = direction * float(s) * stepSize * px;
        float2 sampleUV  = saturate(uv + offset);
        float  sampleD   = YggGetDepth(sampleUV);

        // Depth difference — positive means sample is further (behind surface)
        float depthDiff = sampleD - centerDepth;

        // Skip sky samples
        if (YggIsSky(sampleD)) continue;

        // Thickness gate: reject occluders beyond thickness (the "shadows everything" fix)
        if (depthDiff > thicknessGate) continue;

        // Only count samples that are in front of (closer than) center surface
        // i.e., they stick up above the surface and could occlude ambient light
        if (depthDiff >= -thicknessGate && depthDiff < -bias)
        {
            // Compute horizon elevation angle
            // Position difference in pseudo view space
            float3 horizonVec = float3(direction * float(s) * stepSize, -depthDiff);
            float  len        = length(horizonVec);
            if (len < YGG_SSAO_EPS) continue;

            float sinH = -depthDiff / len; // elevation sine
            maxSinH    = max(maxSinH, sinH);
        }
    }

    // Integrate: bent angle contribution weighted by cosine of normal
    // Normal weighting: surfaces facing away from the direction contribute less
    float3 dirVec   = float3(direction, 0.0);
    float normalDot = max(dot(normalize(dirVec), normal), 0.0);
    float ao        = (maxSinH - sin(bias)) * (0.25 + normalDot * 0.75);

    return saturate(ao);
}

// Rotation matrix for 2D vector
float2 YggRotate2D(float2 v, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float2(v.x * c - v.y * s, v.x * s + v.y * c);
}

// Bilateral depth weight for blur
float YggBilateralDepthWeight(float centerD, float neighborD, float sharpness)
{
    float diff = abs(centerD - neighborD);
    return exp(-diff * sharpness * 80.0);
}

#endif
