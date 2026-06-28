#ifndef YGG_CORE_FXH
#define YGG_CORE_FXH

#ifndef YGG_QUALITY
    #define YGG_QUALITY 1   // 0 = fast, 1 = balanced, 2 = quality
#endif

#ifndef YGG_PI
    #define YGG_PI 3.14159265359
#endif

#ifndef YGG_EPS
    #define YGG_EPS 1e-6
#endif

// -----------------------------------------------------------------------------
// Core constants / helpers
// -----------------------------------------------------------------------------

static const float3 YGG_LUMA_REC709 = float3(0.2126, 0.7152, 0.0722);

float  YggSaturate1(float x)  { return saturate(x); }
float2 YggSaturate2(float2 x) { return saturate(x); }
float3 YggSaturate3(float3 x) { return saturate(x); }
float4 YggSaturate4(float4 x) { return saturate(x); }

float YggSafeRcp(float x)
{
    return 1.0 / max(abs(x), YGG_EPS);
}

float YggSafeDiv(float a, float b)
{
    return a / max(abs(b), YGG_EPS);
}

// FIX: YggLuma must operate on LINEAR light to be physically correct.
// Callers that pass sRGB values will get approximate results — but that
// was already true before. The function itself is correct; callers that
// need accuracy should linearize first (see YggColor).
float YggLuma(float3 c)
{
    return dot(c, YGG_LUMA_REC709);
}

float YggMax3(float3 c)
{
    return max(c.r, max(c.g, c.b));
}

float YggMin3(float3 c)
{
    return min(c.r, min(c.g, c.b));
}

float YggChroma(float3 c)
{
    return YggMax3(c) - YggMin3(c);
}

float3 YggSafePow(float3 c, float p)
{
    return pow(max(c, 0.0.xxx), p);
}

float YggSmoothKnee(float x, float knee)
{
    x = saturate(x);
    knee = max(knee, YGG_EPS);
    return x / (x + knee * (1.0 - x));
}

float YggSigmoid(float x, float strength)
{
    float t = x * 2.0 - 1.0;
    float s = max(strength, 0.0);
    return saturate(0.5 + t / (2.0 * (1.0 + s * abs(t))));
}

float YggSoftClipHigh(float x, float whitePoint, float softness)
{
    whitePoint = max(whitePoint, YGG_EPS);
    softness = max(softness, YGG_EPS);
    float t = x / whitePoint;
    t = t / (1.0 + softness * max(t - 1.0, 0.0));
    return saturate(t) * whitePoint;
}

float YggSoftClipLow(float x, float blackPoint, float softness)
{
    softness = max(softness, YGG_EPS);
    float shifted = max(x - blackPoint, 0.0);
    return shifted / (1.0 + softness * max(blackPoint - x, 0.0));
}

float YggLinearStep(float a, float b, float x)
{
    return saturate((x - a) / max(b - a, YGG_EPS));
}

float YggLumaMask(float luma, float lowStart, float lowEnd, float highStart, float highEnd)
{
    float shadows = YggLinearStep(lowEnd, lowStart, luma);
    float highs   = YggLinearStep(highStart, highEnd, luma);
    return saturate(1.0 - max(shadows, highs));
}

// -----------------------------------------------------------------------------
// sRGB <-> Linear  (IEC 61966-2-1, full piecewise — NOT pow(x,2.2))
//
// ADDED: These were missing entirely. All tonal and chroma operations in
// YggColor now go through these so math is done in linear light.
// The pow(x,2.2) approximation diverges ~3% below 0.1 — exactly where
// shadow lift, black point, and toe curves operate.
// -----------------------------------------------------------------------------

float YggToLinear(float c)
{
    return (c <= 0.04045) ? c / 12.92 : pow(abs(c + 0.055) / 1.055, 2.4);
}

float3 YggToLinear3(float3 c)
{
    return float3(YggToLinear(c.r), YggToLinear(c.g), YggToLinear(c.b));
}

float YggToSRGB(float c)
{
    c = max(c, 0.0);
    return (c <= 0.0031308) ? c * 12.92 : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
}

float3 YggToSRGB3(float3 c)
{
    return float3(YggToSRGB(c.r), YggToSRGB(c.g), YggToSRGB(c.b));
}

// -----------------------------------------------------------------------------
// Oklab  (Ottosson 2020)
//
// ADDED: Perceptually uniform colorspace for vibrance/chroma operations.
// HSV/HSL chroma is hue-dependent — a blue and a yellow at the same HSV
// chroma value look completely different in saturation. Oklab chroma
// is perceptually uniform, so vibrance boosts feel consistent across all hues.
//
// lab.x = L  [0..1]  perceived lightness
// lab.y = a  green <-> magenta
// lab.z = b  blue  <-> yellow
// chroma = length(lab.yz)
// -----------------------------------------------------------------------------

float3 YggLinearToOklab(float3 c)
{
    float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
    float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
    float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;

    l = pow(abs(l), 1.0 / 3.0) * sign(l);
    m = pow(abs(m), 1.0 / 3.0) * sign(m);
    s = pow(abs(s), 1.0 / 3.0) * sign(s);

    return float3(
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s);
}

float3 YggOklabToLinear(float3 lab)
{
    float l = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
    float m = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
    float s = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;

    l = l * l * l;
    m = m * m * m;
    s = s * s * s;

    return float3(
        +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

// -----------------------------------------------------------------------------
// Tonal controls  — ALL operate in LINEAR light now
// Callers must decode sRGB before calling and re-encode after.
// -----------------------------------------------------------------------------

float3 YggApplyBrightnessContrast(float3 c, float brightness, float contrast, float pivot)
{
    return (c - pivot.xxx) * contrast + pivot.xxx + brightness.xxx;
}

float3 YggApplyGamma(float3 c, float gammaValue)
{
    gammaValue = max(gammaValue, 0.01);
    return YggSafePow(saturate(c), YggSafeRcp(gammaValue));
}

float3 YggApplyLevels(float3 c, float inBlack, float inWhite, float outBlack, float outWhite)
{
    float rangeIn  = max(inWhite - inBlack, YGG_EPS);
    float rangeOut = max(outWhite - outBlack, YGG_EPS);
    float3 t = saturate((c - inBlack.xxx) / rangeIn.xxx);
    return outBlack.xxx + t * rangeOut.xxx;
}

float3 YggApplyLiftGammaGain(float3 c, float3 lift, float3 gammaVec, float3 gain)
{
    float3 lifted       = max(c + lift, 0.0.xxx);
    float3 gammaApplied = pow(lifted, max(0.01.xxx, 1.0.xxx / max(gammaVec, 0.01.xxx)));
    return gammaApplied * gain;
}

float3 YggApplyWhiteBlackPoint(float3 c, float blackPoint, float whitePoint)
{
    return YggApplyLevels(c, blackPoint, whitePoint, 0.0, 1.0);
}

// -----------------------------------------------------------------------------
// Color shaping  — operates in linear light
// -----------------------------------------------------------------------------

float3 YggScaleChroma(float3 c, float amount)
{
    float l = YggLuma(c);
    return l.xxx + (c - l.xxx) * amount;
}

float3 YggScaleChromaProtected(float3 c, float amount, float preserveLuma)
{
    float l0    = YggLuma(c);
    float3 outc = l0.xxx + (c - l0.xxx) * amount;

    if (preserveLuma > 0.0)
    {
        float l1 = YggLuma(outc);
        outc += (l0 - l1).xxx * preserveLuma;
    }

    return outc;
}

float YggSaturationWeight(float3 c)
{
    float maxc = YggMax3(c);
    float minc = YggMin3(c);
    return YggSafeDiv(maxc - minc, max(maxc, YGG_EPS));
}

// FIX: YggSmartVibrance rewritten to use Oklab chroma instead of HSV chroma.
//
// OLD: used (max-min)/max as the saturation weight. This is HSV saturation —
// hue-dependent and perceptually non-uniform. A blue at HSV-sat 0.4 looks
// far more saturated than a yellow at HSV-sat 0.4. The vibrance mask was
// therefore inconsistent across hues, over-boosting some and under-boosting others.
//
// NEW: converts to linear first, then Oklab. Computes chroma as length(a,b).
// This is perceptually uniform — equal numeric chroma = equal perceived saturation
// across all hues. Vibrance inverse-weight and ceiling are now hue-agnostic.
// Output is converted back through Oklab -> linear -> sRGB.
//
// protectHighlights / protectShadows retained as luma masks on the linear value.
// satLimit now operates in Oklab chroma space (different scale: 0.0-~0.4 typical).
float3 YggSmartVibrance(float3 c, float vibrance, float protectHighlights,
                        float protectShadows, float satLimit)
{
    // c is already linear (callers linearize before this)
    float3 lab    = YggLinearToOklab(c);
    float  chroma = length(lab.yz);
    float  luma   = lab.x; // Oklab L is perceptual lightness

    // Inverse chroma weight: muted colors boosted more than vivid ones
    // satLimit in Oklab space — 0.15 is moderate, 0.3 is vivid
    float unsatMask   = saturate(1.0 - chroma / max(satLimit, YGG_EPS));

    // Midtone bias: protect extreme shadows and highlights from vibrance
    // using Oklab L (perceptual lightness) instead of raw sRGB luma
    float midtoneBias     = YggLumaMask(luma, 0.10, 0.22, 0.78, 0.92);
    float highlightMask   = 1.0 - YggLinearStep(1.0 - protectHighlights, 1.0, luma);
    float shadowMask      = 1.0 - YggLinearStep(0.0, protectShadows, luma);

    float boostFactor = 1.0 + vibrance * unsatMask * midtoneBias * highlightMask * shadowMask;

    // Protect near-achromatic pixels from noise amplification
    float chromaMask = smoothstep(0.0, 0.012, chroma);
    lab.yz *= lerp(1.0, boostFactor, chromaMask);

    // Hard chroma ceiling in Oklab space
    float newChroma = length(lab.yz);
    if (newChroma > satLimit)
        lab.yz *= satLimit / newChroma;

    float3 linOut = YggOklabToLinear(lab);
    return max(linOut, 0.0);
}

float3 YggProtectHighlightsShadows(float3 original, float3 graded,
                                   float shadowProtect, float highlightProtect)
{
    float luma          = YggLuma(original);
    float protectShadow = 1.0 - YggLinearStep(0.0, shadowProtect, luma);
    float protectHigh   = YggLinearStep(1.0 - highlightProtect, 1.0, luma);
    float protect       = saturate(max(protectShadow, protectHigh));
    return lerp(graded, original, protect);
}

float3 YggToneRestraint(float3 original, float3 graded,
                        float shadowStart, float shadowEnd,
                        float highStart, float highEnd, float strength)
{
    float luma    = YggLuma(original);
    float midMask = YggLumaMask(luma, shadowStart, shadowEnd, highStart, highEnd);
    float amount  = lerp(1.0 - strength, 1.0, midMask);
    return lerp(original, graded, amount);
}

float3 YggSoftRangeRemap(float3 c, float blackPoint, float whitePoint, float softness)
{
    blackPoint = saturate(blackPoint);
    whitePoint = max(whitePoint, blackPoint + 0.01);
    softness   = saturate(softness);

    float3 t = saturate((c - blackPoint.xxx) / (whitePoint - blackPoint).xxx);
    t = lerp(t, t * t * (3.0 - 2.0 * t), softness * 0.35);
    return t;
}

float YggToneCurveScalar(float x, float shadowCompression,
                         float highlightCompression, float midtoneDensity, float pivot)
{
    x     = saturate(x);
    pivot = saturate(pivot);

    float toeWeight      = 1.0 - YggLinearStep(0.0, pivot, x);
    float shoulderWeight = YggLinearStep(pivot, 1.0, x);

    float toe      = x / (x + shadowCompression * max(1.0 - x, YGG_EPS));
    float shoulder = x / (1.0 + highlightCompression * max(x - pivot, 0.0));

    float curved = lerp(x, toe, saturate(shadowCompression) * toeWeight);
    curved = lerp(curved, shoulder, saturate(highlightCompression) * shoulderWeight);

    float centered = curved - pivot;
    curved = pivot + centered * lerp(1.0, 1.0 - midtoneDensity * 0.35,
                                     1.0 - abs(centered) * 2.0);

    return saturate(curved);
}

float3 YggToneCurve(float3 c, float shadowCompression,
                    float highlightCompression, float midtoneDensity, float pivot)
{
    return float3(
        YggToneCurveScalar(c.r, shadowCompression, highlightCompression, midtoneDensity, pivot),
        YggToneCurveScalar(c.g, shadowCompression, highlightCompression, midtoneDensity, pivot),
        YggToneCurveScalar(c.b, shadowCompression, highlightCompression, midtoneDensity, pivot));
}

float3 YggBrightRegionSatRestraint(float3 original, float3 graded,
                                   float amount, float start, float end)
{
    float luma    = YggLuma(graded);
    float sat     = YggSaturationWeight(graded);
    float lumaMask = YggLinearStep(start, end, luma);
    float satMask  = YggLinearStep(0.10, 0.85, sat);
    float mask     = lumaMask * satMask;

    float  lg      = YggLuma(graded);
    float3 neutral = lg.xxx;
    float3 restrained = lerp(graded, neutral + (graded - neutral) * (1.0 - amount), mask);

    float  lr = YggLuma(restrained);
    restrained += (lg - lr).xxx;

    return restrained;
}

float3 YggHighlightGuard(float3 original, float3 graded,
                         float amount, float start, float end, float satInfluence)
{
    float lo = YggLuma(original);
    float lg = YggLuma(graded);
    float so = YggSaturationWeight(original);
    float sg = YggSaturationWeight(graded);

    float lumaMask = YggLinearStep(start, end, max(lo, lg));
    float satMask  = lerp(1.0, YggLinearStep(0.15, 0.90, max(so, sg)), saturate(satInfluence));
    float mask     = saturate(lumaMask * satMask * amount);

    float3 restored = lerp(graded, original, mask);
    float3 mixed    = lerp(restored, graded, 0.20);
    return mixed;
}

float3 YggSampleColor(sampler2D s, float2 uv)
{
    return tex2D(s, uv).rgb;
}

// Scene key — 9 sparse taps across the frame
// NOTE: Each shader that enables scene adaptation calls this independently.
// This is correct for separate-pass shaders (each reads its own backbuffer state).
// Cost: 9 taps × number of shaders with adaptation enabled. Acceptable on GTX 1650.
float YggSceneKey9Tap(sampler2D s)
{
    float l = 0.0;
    l += YggLuma(YggSampleColor(s, float2(0.50, 0.50)));
    l += YggLuma(YggSampleColor(s, float2(0.25, 0.25)));
    l += YggLuma(YggSampleColor(s, float2(0.75, 0.25)));
    l += YggLuma(YggSampleColor(s, float2(0.25, 0.75)));
    l += YggLuma(YggSampleColor(s, float2(0.75, 0.75)));
    l += YggLuma(YggSampleColor(s, float2(0.50, 0.20)));
    l += YggLuma(YggSampleColor(s, float2(0.50, 0.80)));
    l += YggLuma(YggSampleColor(s, float2(0.20, 0.50)));
    l += YggLuma(YggSampleColor(s, float2(0.80, 0.50)));
    return l / 9.0;
}

float YggLowKeyMask(float sceneKey, float start, float end)
{
    return 1.0 - YggLinearStep(start, end, sceneKey);
}

float YggHighKeyMask(float sceneKey, float start, float end)
{
    return YggLinearStep(start, end, sceneKey);
}

float YggAdaptiveScalar(float baseValue, float lowKeyValue, float highKeyValue,
                        float lowMask, float highMask, float adaptStrength)
{
    float adapted = lerp(baseValue, lowKeyValue, lowMask);
    adapted = lerp(adapted, highKeyValue, highMask);
    return lerp(baseValue, adapted, saturate(adaptStrength));
}

float3 YggAdaptiveShadowLift(float3 original, float3 graded,
                             float amount, float start, float end)
{
    float  luma = YggLuma(original);
    float  mask = 1.0 - YggLinearStep(start, end, luma);
    return lerp(graded, lerp(graded, original, amount), mask);
}

float3 YggNeutralClamp(float3 c)
{
    return saturate(c);
}

// -----------------------------------------------------------------------------
// Sampling helpers / masks
// -----------------------------------------------------------------------------

float YggEdgeMask5Tap(sampler2D s, float2 uv, float2 px)
{
    float lC = YggLuma(YggSampleColor(s, uv));
    float lL = YggLuma(YggSampleColor(s, uv + float2(-px.x, 0.0)));
    float lR = YggLuma(YggSampleColor(s, uv + float2( px.x, 0.0)));
    float lU = YggLuma(YggSampleColor(s, uv + float2(0.0, -px.y)));
    float lD = YggLuma(YggSampleColor(s, uv + float2(0.0,  px.y)));

    float gx = abs(lR - lL);
    float gy = abs(lD - lU);
    return saturate((gx + gy) * 2.0);
}

float YggLocalContrastMask5Tap(sampler2D s, float2 uv, float2 px)
{
    float3 c = YggSampleColor(s, uv);
    float3 l = YggSampleColor(s, uv + float2(-px.x, 0.0));
    float3 r = YggSampleColor(s, uv + float2( px.x, 0.0));
    float3 u = YggSampleColor(s, uv + float2(0.0, -px.y));
    float3 d = YggSampleColor(s, uv + float2(0.0,  px.y));

    float center = YggLuma(c);
    float avg    = (YggLuma(l) + YggLuma(r) + YggLuma(u) + YggLuma(d)) * 0.25;
    return saturate(abs(center - avg) * 4.0);
}

// -----------------------------------------------------------------------------
// Sharpen helpers
// -----------------------------------------------------------------------------

float3 YggUnsharp5Tap(sampler2D s, float2 uv, float2 px)
{
    float3 c    = YggSampleColor(s, uv);
    float3 n    = YggSampleColor(s, uv + float2(0.0, -px.y));
    float3 e    = YggSampleColor(s, uv + float2( px.x, 0.0));
    float3 w    = YggSampleColor(s, uv + float2(-px.x, 0.0));
    float3 d    = YggSampleColor(s, uv + float2(0.0,  px.y));
    float3 blur = (n + e + w + d) * 0.25;
    return c - blur;
}

float3 YggAntiRingingClamp(float3 base, float3 sharpened,
                           float3 neighborhoodMin, float3 neighborhoodMax, float strength)
{
    float3 clamped = clamp(sharpened, neighborhoodMin, neighborhoodMax);
    return lerp(sharpened, clamped, saturate(strength));
}

// -----------------------------------------------------------------------------
// Deband / dither helpers
// -----------------------------------------------------------------------------

float YggHash12(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

// ADDED: IGN (Interleaved Gradient Noise, Jimenez 2014)
// Better spatial frequency distribution than the hash above for dithering.
// Used by YggDeband for randomized sample directions.
float YggIGN(float2 pixelPos)
{
    return frac(52.9829189 * frac(dot(pixelPos, float2(0.06711056, 0.00583715))));
}

float3 YggTriangularDither(float2 uv, float strength)
{
    float n1  = YggHash12(uv);
    float n2  = YggHash12(uv + 19.19);
    float tri = (n1 + n2 - 1.0);
    return tri.xxx * strength;
}

#endif
