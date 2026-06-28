#include "ReShade.fxh"
#include "YggCore.fxh"

// =============================================================================
//  YggSceneKey -- Shared Scene Brightness Pre-Pass
//
//  Computes YggSceneKey9Tap once and stores the scalar result in an R8 texture.
//  All shaders that need scene-adaptive behavior read from this texture instead
//  of calling YggSceneKey9Tap independently, saving up to 72 backbuffer reads
//  per frame when the full suite is active.
//
//  Load order: must run before any consumer shader (Deband, SSAO, Color, etc).
// =============================================================================

// -----------------------------------------------------------------------------
//  Texture
// -----------------------------------------------------------------------------

texture2D YggSceneKeyTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
sampler2D YggSceneKeySampler { Texture = YggSceneKeyTex; MinFilter = POINT; MagFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; };

// -----------------------------------------------------------------------------
//  Pixel Shader
// -----------------------------------------------------------------------------

float4 PS_YggSceneKey(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float key = YggSceneKey9Tap(ReShade::BackBuffer);
    return float4(key.xxx, 1.0);
}

// -----------------------------------------------------------------------------
//  Technique
// -----------------------------------------------------------------------------

technique YggSceneKey
    < ui_label   = "YggSceneKey -- Shared Scene Brightness";
      ui_tooltip =
        "Computes 9-tap scene brightness once for the entire suite.\n"
        "Must be enabled and placed first in the load order."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_YggSceneKey;
        RenderTarget = YggSceneKeyTex;
    }
}
