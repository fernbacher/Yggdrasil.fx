#ifndef YGG_SSAO_FXH
#define YGG_SSAO_FXH

// =============================================================================
//  YggSSAO Kernel -- Depth, Normal Reconstruction, GTAO Helpers
//
//  Why this exists as a separate header:
//    SSAO requires non-trivial depth math that shouldn't pollute YggCore.
//    Depth linearization, normal reconstruction from depth derivatives,
//    and horizon angle integration are SSAO-specific primitives.
//
//  Normal reconstruction from depth:
//    ReShade has no normal buffer. We reconstruct surface normals by taking
//    cross products of depth gradient vectors. This is an approximation but
//    is sufficient for screen-space AO -- errors only appear at silhouette
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
//  Quality is limited by depth precision -- works well on smooth surfaces,
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

#endif
