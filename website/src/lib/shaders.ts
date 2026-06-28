export interface Shader {
  rune: string;
  name: string;
  tag: string;
  cost: number;
  impact: number;
  shortDesc: string;
  longDesc: string;
  loadOrder: number;
  category: "Depth" | "Detail" | "Clean" | "Smooth" | "Tone" | "Glow" | "Core" | "Finish";
}

export const shaders: Shader[] = [
  {
    rune: "ᚨ",
    name: "Atmos",
    tag: "Depth",
    cost: 15,
    impact: 75,
    loadOrder: 6,
    category: "Depth",
    shortDesc: "Atmospheric separation & dehaze — restores depth in veiled, hazy scenes.",
    longDesc:
      "Atmos analyses the luminance histogram and applies a local atmospheric separation pass. It dehazes scenes by subtracting a depth-aware airlight estimate, bringing distant detail back into view without over-brightening foregrounds. Works on luminance only to preserve chroma fidelity.",
  },
  {
    rune: "ᚲ",
    name: "Clarity",
    tag: "Detail",
    cost: 25,
    impact: 85,
    loadOrder: 7,
    category: "Detail",
    shortDesc: "Mid-frequency local contrast — brings out form and texture without ruining edges.",
    longDesc:
      "Clarity applies a multi-scale unsharp mask limited to mid-frequencies. Unlike generic sharpeners, it avoids ringing at strong luminance edges by modulating gain through an edge-stopping function. The result is tactile texture enhancement that respects silhouettes.",
  },
  {
    rune: "ᚲᛟ",
    name: "Color",
    tag: "Tone",
    cost: 20,
    impact: 90,
    loadOrder: 4,
    category: "Tone",
    shortDesc: "Perceptual colour grading with presets (Natural, Vivid, FakeHDR). Smart vibrance in Oklab space.",
    longDesc:
      "Color operates in the Oklab colour space for perceptually uniform grading. It offers multiple presets — Natural for subtle correction, Vivid for punchy saturation, and FakeHDR for a high-dynamic-range emulation. Smart vibrance selectively boosts muted tones while protecting skin hues and already-saturated regions.",
  },
  {
    rune: "ᛞ",
    name: "Deband",
    tag: "Clean",
    cost: 10,
    impact: 60,
    loadOrder: 1,
    category: "Clean",
    shortDesc: "Perceptual debanding with randomised angular sampling — catches banding in all directions.",
    longDesc:
      "Deband detects false contours through angular sampling across multiple randomised directions. Rather than a simple dither, it applies perceptual noise injection modulated by the surrounding gradient magnitude. This catches banding artefacts at any orientation while preserving genuine high-frequency detail.",
  },
  {
    rune: "ᛏ",
    name: "EdgeAA Temporal",
    tag: "Smooth",
    cost: 35,
    impact: 95,
    loadOrder: 2,
    category: "Smooth",
    shortDesc: "Edge-directed AA with temporal accumulation. Reduces shimmer and pixel crawl over time. Built-in debug mode.",
    longDesc:
      "EdgeAA Temporal detects geometry edges via depth and normal discontinuities, then accumulates sub-pixel coverage over multiple frames. A confidence-weighted blend rejects disocclusion ghosts and moving specular highlights. Debug modes visualize motion vectors, accumulation history, or per-pixel confidence for tuning.",
  },
  {
    rune: "ᛟ",
    name: "SSAO",
    tag: "Depth",
    cost: 40,
    impact: 85,
    loadOrder: 3,
    category: "Depth",
    shortDesc: "GTAO-inspired ambient occlusion — contact shadows with depth-aware thickness gating.",
    longDesc:
      "SSAO samples the depth buffer in a hemisphere around each pixel (6 directions × 8 depth reads = 48 taps), computing horizon angles to estimate ambient occlusion. A thickness-gating function prevents self-occlusion on thin geometry (fences, foliage) while still producing rich contact shadows where surfaces meet.",
  },
  {
    rune: "ᛋ",
    name: "Sharp",
    tag: "Detail",
    cost: 15,
    impact: 70,
    loadOrder: 8,
    category: "Detail",
    shortDesc: "Adaptive detail sharpening with halo suppression and anti-ringing. Luma-only mode preserves hue.",
    longDesc:
      "Sharp applies adaptive sharpening with built-in halo suppression that detects and clamps overshoot at luminance edges. An anti-ringing kernel prevents the telltale white fringe around high-contrast boundaries. The optional luma-only mode restricts sharpening to the luminance channel, leaving chrominance untouched.",
  },
  {
    rune: "ᚦ",
    name: "Tonemap",
    tag: "Tone",
    cost: 20,
    impact: 80,
    loadOrder: 9,
    category: "Tone",
    shortDesc: "AgX-inspired SDR tonemapper. Scene-adaptive exposure, shoulder/toe control, luma-only mode.",
    longDesc:
      "Tonemap implements an AgX-inspired SDR display transform. It uses a scene-adaptive exposure estimate, a filmic shoulder for highlight rolloff, and a controllable toe for shadow density. The luma-only mode applies the curve to luminance only, preserving artistic colour grading.",
  },
  {
    rune: "ᚷ",
    name: "Halation",
    tag: "Glow",
    cost: 15,
    impact: 65,
    loadOrder: 10,
    category: "Glow",
    shortDesc: "Warm highlight bleed into deep shadows — filmic glow that respects bright-area integrity.",
    longDesc:
      "Halation simulates the filmic phenomenon where bright highlights bleed warm light into adjacent dark regions. Unlike a simple Gaussian blur, it uses a directional scatter kernel weighted toward red wavelengths, with a brightness threshold that prevents the glow from contaminating bright image areas.",
  },
  {
    rune: "ᛚ",
    name: "Local Mean",
    tag: "Core",
    cost: 5,
    impact: 50,
    loadOrder: 5,
    category: "Core",
    shortDesc: "Shared blur pre-pass. Saves texture reads across Sharp and Clarity — performance boost.",
    longDesc:
      "LocalMean computes a shared multi-scale blurred luminance buffer used by both Sharp and Clarity. By centralising the expensive blur passes, it eliminates redundant texture samples and gives a measurable performance improvement when both detail shaders are active.",
  },
  {
    rune: "ᛚᚢ",
    name: "LUT",
    tag: "Finish",
    cost: 5,
    impact: 40,
    loadOrder: 12,
    category: "Finish",
    shortDesc: "3D LUT applier — load your own grade with near-zero runtime cost.",
    longDesc:
      "LUT applies a 3D colour lookup table (cube format) as the final stage of the pipeline. It uses trilinear interpolation for smooth gradation and costs almost nothing at runtime. Drop in any .cube file to apply a professional colour grade.",
  },
  {
    rune: "ᚠ",
    name: "FilmGrain",
    tag: "Finish",
    cost: 10,
    impact: 55,
    loadOrder: 11,
    category: "Finish",
    shortDesc: "Triangular dither with luma-weighted envelope. Film-like grain that fades in shadows/highlights.",
    longDesc:
      "FilmGrain generates a triangular-dithered noise pattern modulated by a luminance-weighted envelope. Grain intensity is strongest in midtones and naturally fades in deep shadows and bright highlights, mimicking the characteristic silver-halide grain distribution of film stock.",
  },
];

export const shaderByName: Record<string, Shader> = {};
for (const s of shaders) {
  shaderByName[s.name] = s;
}

export const shadersByLoadOrder = [...shaders].sort((a, b) => a.loadOrder - b.loadOrder);
