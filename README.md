# Yggdrasil.fx — ReShade Shader Suite

**Yggdrasil** is a cohesive collection of ReShade shaders designed from the ground up on Linux. It brings depth, clarity, colour, and atmosphere to your favourite titles – all with a performance‑conscious, open‑source approach.

- **Linux‑first** – tested on Proton.
- **No vendor lock‑in** – everything is open source and transparent.
- **Harmonised pipeline** – shaders work together to produce a polished, cinematic image.

## 📦 Features

| Shader | Description |
|---|---|
| **Atmos** | Atmospheric dehazing – restores depth in hazy or foggy scenes. |
| **Clarity** | Mid‑frequency local contrast enhancement – brings out form and texture without haloing. |
| **Color** | Perceptual colour grading in Oklab space (Natural, Vivid, FakeHDR presets). |
| **Deband** | Randomised angular sampling to reduce colour banding across the whole image. |
| **EdgeAA_Temporal** | Edge‑directed anti‑aliasing with temporal accumulation – reduces shimmer and pixel crawl.|
| **SSAO** | GTAO‑style ambient occlusion with depth‑aware thickness gating. |
| **Sharp** | Adaptive detail sharpening with halo suppression and anti‑ringing (luma‑only mode). |
| **Tonemap** | AgX‑inspired SDR tonemapper with scene‑adaptive exposure and shoulder/toe control. |
| **Halation** | Warm highlight bleed into deep shadows – a filmic glow that respects bright areas. |
| **Local Mean** | Shared blur pre‑pass – optimises performance for Sharp and Clarity. |
| **LUT** | 3D LUT applier – load your own colour grade with near‑zero runtime cost. |
| **FilmGrain** | Triangular dither with luma‑weighted envelope – organic film grain effect. |

## 🚀 Installation

1. **Copy the shader files**
Place all `Ygg*.fx` and `Ygg*.fxh` files into your ReShade `Shaders/` folder.
1. **Set the load order**
Enable shaders in the **recommended order** (see below) to ensure the pipeline works correctly.
1. **Enable & tune**

- In the ReShade in‑game menu, enable the techniques you want.
- Adjust the sliders to your liking.
- Save your preset (`.ini` file) for future sessions.
1. **Play on Linux**
Yggdrasil is tested with Proton and Vulkan – just launch your game and enjoy.

The shaders are written in ReShade’s HLSL‑like syntax and require no compilation – they are ready to use as‑is. If you want to contribute, simply edit the `.fx` files with your favourite editor.

A much better way to get information and even a before and after comparison slider with the shaders on, are on the official website. 
### [Link](https://yggdrasilfx.vercel.app/)
