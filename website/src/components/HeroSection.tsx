"use client";

import { useEffect } from "react";

export default function HeroSection() {
  useEffect(() => {
    const observer = new MutationObserver(() => {
      if (document.body.classList.contains("loaded")) {
        document.querySelectorAll(".tree-roots path").forEach((p, i) => {
          (p as SVGPathElement).style.animation = `drawStage 1.2s cubic-bezier(0.16,1,0.3,1) forwards`;
          (p as SVGPathElement).style.animationDelay = `${i * 0.08}s`;
        });
        document.querySelectorAll(".tree-trunk path").forEach((p, i) => {
          (p as SVGPathElement).style.animation = `drawStage 1.5s cubic-bezier(0.16,1,0.3,1) forwards`;
          (p as SVGPathElement).style.animationDelay = `${0.8 + i * 0.1}s`;
        });
        document.querySelectorAll(".tree-branches-1 path").forEach((p, i) => {
          (p as SVGPathElement).style.animation = `drawStage 1.6s cubic-bezier(0.16,1,0.3,1) forwards`;
          (p as SVGPathElement).style.animationDelay = `${2 + i * 0.06}s`;
        });
        document.querySelectorAll(".tree-branches-2 path").forEach((p, i) => {
          (p as SVGPathElement).style.animation = `drawStage 1.4s cubic-bezier(0.16,1,0.3,1) forwards`;
          (p as SVGPathElement).style.animationDelay = `${3.2 + i * 0.05}s`;
        });
        document.querySelectorAll(".tree-branches-3 path").forEach((p, i) => {
          (p as SVGPathElement).style.animation = `drawStage 1.6s cubic-bezier(0.16,1,0.3,1) forwards`;
          (p as SVGPathElement).style.animationDelay = `${4.2 + i * 0.04}s`;
        });
        document.querySelectorAll(".tree-node").forEach((n) => {
          (n as HTMLElement).style.animation = `nodeGlow 0.8s cubic-bezier(0.16,1,0.3,1) forwards`;
          (n as HTMLElement).style.animationDelay = `${5.5 + Math.random() * 0.8}s`;
        });
        document.querySelectorAll(".tree-rune").forEach((r, i) => {
          (r as HTMLElement).style.animation = `nodeGlow 1s cubic-bezier(0.16,1,0.3,1) forwards`;
          (r as HTMLElement).style.animationDelay = `${6 + i * 0.3}s`;
        });
        observer.disconnect();
      }
    });
    observer.observe(document.body, { attributes: true, attributeFilter: ["class"] });
    return () => observer.disconnect();
  }, []);

  return (
    <header className="min-h-[100dvh] flex items-center justify-center relative overflow-hidden">
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
        <div className="w-[min(80vw,800px)] h-[min(80vh,800px)] rounded-full bg-[radial-gradient(ellipse_at_center,var(--accent-glow)_0%,transparent_60%)] blur-[100px] animate-[heroPulse_8s_ease-in-out_infinite]" />
      </div>

      <svg
        className="absolute inset-0 m-auto w-[min(88vw,840px)] h-[min(92vh,840px)] opacity-65 pointer-events-none"
        viewBox="-20 -30 440 560"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <filter id="glow">
            <feGaussianBlur stdDeviation="2" result="blur" />
            <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
          </filter>
          <filter id="glowStrong">
            <feGaussianBlur stdDeviation="4" result="blur" />
            <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
          </filter>
          <radialGradient id="nodeGlowGrad" cx="50%" cy="50%">
            <stop offset="0%" stopColor="#7a6aff" stopOpacity="1" />
            <stop offset="100%" stopColor="#5b8cff" stopOpacity="0.3" />
          </radialGradient>
        </defs>

        <g className="tree-roots" stroke="#4a6a8a" strokeWidth="2.5" fill="none" strokeLinecap="round">
          <path d="M200 460 L200 500" /><path d="M200 460 Q190 475 170 500" />
          <path d="M200 460 Q210 475 230 500" /><path d="M200 455 Q175 465 140 490" />
          <path d="M200 455 Q225 465 260 490" /><path d="M200 450 Q160 455 110 475" strokeWidth="2" />
          <path d="M200 450 Q240 455 290 475" strokeWidth="2" />
          <path d="M200 448 Q180 440 150 460" strokeWidth="1.8" stroke="#3a5a7a" />
          <path d="M200 448 Q220 440 250 460" strokeWidth="1.8" stroke="#3a5a7a" />
        </g>

        <g className="tree-trunk" stroke="#5b8cff" fill="none" strokeLinecap="round">
          <path d="M200 440 Q195 380 198 320 Q200 280 200 240" strokeWidth="6" />
          <path d="M200 240 Q198 200 200 170" strokeWidth="5" />
          <path d="M200 170 Q202 140 200 110" strokeWidth="4" />
          <path d="M195 420 Q193 380 196 340" strokeWidth="1" stroke="#3a5a8a" opacity="0.4" />
          <path d="M205 430 Q207 390 204 350" strokeWidth="1" stroke="#3a5a8a" opacity="0.4" />
          <path d="M197 310 Q198 270 200 240" strokeWidth="0.8" stroke="#3a5a8a" opacity="0.3" />
        </g>

        <g className="tree-branches-1" stroke="#5b8cff" fill="none" strokeLinecap="round">
          <path d="M198 370 Q170 350 135 320" strokeWidth="3.5" /><path d="M198 330 Q165 300 120 270" strokeWidth="3" />
          <path d="M200 290 Q170 260 140 220" strokeWidth="3" /><path d="M200 250 Q175 230 150 190" strokeWidth="2.5" />
          <path d="M202 370 Q230 350 265 320" strokeWidth="3.5" /><path d="M202 330 Q235 300 280 270" strokeWidth="3" />
          <path d="M200 290 Q230 260 260 220" strokeWidth="3" /><path d="M200 250 Q225 230 250 190" strokeWidth="2.5" />
          <path d="M200 200 Q175 175 140 145" strokeWidth="2.5" /><path d="M200 180 Q170 150 130 120" strokeWidth="2.2" />
          <path d="M200 200 Q225 175 260 145" strokeWidth="2.5" /><path d="M200 180 Q230 150 270 120" strokeWidth="2.2" />
        </g>

        <g className="tree-branches-2" stroke="#7a6aff" fill="none" strokeLinecap="round">
          <path d="M135 320 Q115 310 95 290" strokeWidth="2" /><path d="M135 320 Q120 295 105 320" strokeWidth="1.5" />
          <path d="M120 270 Q100 255 85 235" strokeWidth="2" /><path d="M120 270 Q105 245 110 230" strokeWidth="1.5" />
          <path d="M140 220 Q120 200 100 185" strokeWidth="1.8" /><path d="M150 190 Q130 170 110 155" strokeWidth="1.5" />
          <path d="M140 145 Q120 130 100 115" strokeWidth="1.8" /><path d="M130 120 Q110 105 95 90" strokeWidth="1.5" />
          <path d="M265 320 Q285 310 305 290" strokeWidth="2" /><path d="M265 320 Q280 295 295 320" strokeWidth="1.5" />
          <path d="M280 270 Q300 255 315 235" strokeWidth="2" /><path d="M280 270 Q295 245 290 230" strokeWidth="1.5" />
          <path d="M260 220 Q280 200 300 185" strokeWidth="1.8" /><path d="M250 190 Q270 170 290 155" strokeWidth="1.5" />
          <path d="M260 145 Q280 130 300 115" strokeWidth="1.8" /><path d="M270 120 Q290 105 305 90" strokeWidth="1.5" />
        </g>

        <g className="tree-branches-3" stroke="#8aa4c8" fill="none" strokeLinecap="round" strokeWidth="1">
          <path d="M200 140 Q180 125 160 100 Q145 85 130 80" opacity="0.7" />
          <path d="M200 160 Q175 140 155 115 Q140 100 120 95" opacity="0.7" />
          <path d="M200 120 Q180 100 160 75 Q145 60 125 55" opacity="0.6" />
          <path d="M200 100 Q185 85 170 60 Q155 45 140 35" opacity="0.6" />
          <path d="M200 140 Q220 125 240 100 Q255 85 270 80" opacity="0.7" />
          <path d="M200 160 Q225 140 245 115 Q260 100 280 95" opacity="0.7" />
          <path d="M200 120 Q220 100 240 75 Q255 60 275 55" opacity="0.6" />
          <path d="M200 100 Q215 85 230 60 Q245 45 260 35" opacity="0.6" />
          <path d="M200 70 Q190 55 185 40 Q182 30 180 22" opacity="0.5" />
          <path d="M200 70 Q210 55 215 40 Q218 30 220 22" opacity="0.5" />
          <path d="M200 70 Q196 52 200 35" opacity="0.4" />
          <path d="M95 290 Q80 275 70 260 Q60 250 55 240" opacity="0.5" />
          <path d="M305 290 Q320 275 330 260 Q340 250 345 240" opacity="0.5" />
          <path d="M140 220 Q125 210 115 200" opacity="0.5" /><path d="M260 220 Q275 210 285 200" opacity="0.5" />
          <path d="M100 185 Q85 175 75 165" opacity="0.5" /><path d="M300 185 Q315 175 325 165" opacity="0.5" />
          <path d="M155 100 Q140 90 130 85" opacity="0.4" /><path d="M245 100 Q260 90 270 85" opacity="0.4" />
          <path d="M170 60 Q160 50 150 45" opacity="0.4" /><path d="M230 60 Q240 50 250 45" opacity="0.4" />
        </g>

        <g filter="url(#glowStrong)">
          <circle className="tree-node" cx="200" cy="460" r="3" fill="#7a6aff" opacity="0" />
          <circle className="tree-node" cx="200" cy="370" r="2.5" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="200" cy="290" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="200" cy="200" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="200" cy="110" r="2.5" fill="#7a6aff" opacity="0" />
          <circle className="tree-node" cx="95" cy="290" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="85" cy="235" r="2.5" fill="#7a6aff" opacity="0" />
          <circle className="tree-node" cx="100" cy="185" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="110" cy="155" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="100" cy="115" r="2.5" fill="#7a6aff" opacity="0" />
          <circle className="tree-node" cx="95" cy="90" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="130" cy="80" r="1.8" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="120" cy="95" r="1.8" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="125" cy="55" r="1.5" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="140" cy="35" r="2" fill="#7a6aff" opacity="0" />
          <circle className="tree-node" cx="55" cy="240" r="1.5" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="75" cy="165" r="1.5" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="150" cy="45" r="1.2" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="305" cy="290" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="315" cy="235" r="2.5" fill="#7a6aff" opacity="0" />
          <circle className="tree-node" cx="300" cy="185" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="290" cy="155" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="300" cy="115" r="2.5" fill="#7a6aff" opacity="0" />
          <circle className="tree-node" cx="305" cy="90" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="270" cy="80" r="1.8" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="280" cy="95" r="1.8" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="275" cy="55" r="1.5" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="260" cy="35" r="2" fill="#7a6aff" opacity="0" />
          <circle className="tree-node" cx="110" cy="320" r="1.5" fill="#ffc878" opacity="0" />
          <circle className="tree-node" cx="295" cy="320" r="1.5" fill="#ffc878" opacity="0" />
          <circle className="tree-node" cx="345" cy="240" r="1.5" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="325" cy="165" r="1.5" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="250" cy="45" r="1.2" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="200" cy="70" r="3" fill="url(#nodeGlowGrad)" opacity="0" />
          <circle className="tree-node" cx="180" cy="22" r="2.2" fill="#7a6aff" opacity="0" />
          <circle className="tree-node" cx="220" cy="22" r="2.2" fill="#7a6aff" opacity="0" />
          <circle className="tree-node" cx="200" cy="35" r="2" fill="#5b8cff" opacity="0" />
          <circle className="tree-node" cx="185" cy="45" r="1.5" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="215" cy="45" r="1.5" fill="#8aa4c8" opacity="0" />
          <circle className="tree-node" cx="170" cy="500" r="1.5" fill="#3a5a7a" opacity="0" />
          <circle className="tree-node" cx="230" cy="500" r="1.5" fill="#3a5a7a" opacity="0" />
          <circle className="tree-node" cx="140" cy="490" r="1.5" fill="#3a5a7a" opacity="0" />
          <circle className="tree-node" cx="260" cy="490" r="1.5" fill="#3a5a7a" opacity="0" />
        </g>

        <g fontFamily="serif" fontSize="10" fill="#5b8cff" opacity="0" filter="url(#glow)">
          <text className="tree-rune" x="132" y="325" opacity="0">ᚨ</text>
          <text className="tree-rune" x="260" y="325" opacity="0">ᚲ</text>
          <text className="tree-rune" x="117" y="275" opacity="0">ᛏ</text>
          <text className="tree-rune" x="273" y="275" opacity="0">ᛞ</text>
          <text className="tree-rune" x="137" y="225" opacity="0">ᛟ</text>
          <text className="tree-rune" x="255" y="225" opacity="0">ᛋ</text>
          <text className="tree-rune" x="198" y="365" opacity="0">ᛚ</text>
        </g>
      </svg>

      <div className="absolute top-1/2 -translate-y-1/2 left-6 md:left-16 opacity-0 [body.loaded_&]:opacity-100 [body.loaded_&]:[transition:opacity_1s_ease_2s] font-mono text-[0.7rem] tracking-[0.4em] uppercase text-ygg-text-mute font-normal [writing-mode:vertical-rl]">
        RESHADE · VULKAN · D3D
      </div>
      <div className="absolute top-1/2 -translate-y-1/2 right-6 md:right-16 opacity-0 [body.loaded_&]:opacity-100 [body.loaded_&]:[transition:opacity_1s_ease_2s] font-mono text-[0.7rem] tracking-[0.4em] uppercase text-ygg-text-mute font-normal [writing-mode:vertical-rl]">
        VERSION 1.0 · OPEN SOURCE
      </div>

      <div className="relative z-[2] text-center flex flex-col items-center opacity-0 translate-y-8 [body.loaded_&]:opacity-100 [body.loaded_&]:translate-y-0 [body.loaded_&]:[transition:opacity_1.2s_cubic-bezier(0.16,1,0.3,1)_4s,transform_1.2s_cubic-bezier(0.16,1,0.3,1)_4s] pt-[6vh]">
        <div className="font-mono text-xs text-ygg-accent mb-6 tracking-[0.2em] uppercase flex items-center gap-2">
          <span className="w-1.5 h-1.5 bg-ygg-green rounded-full [box-shadow:0_0_10px_#4cff4c] animate-[pulse_2s_infinite]" />
          System Online · Pipeline Ready
        </div>

        <h1 className="text-[13vw] md:text-[12vw] font-black leading-[0.82] tracking-[-0.05em] mb-8 relative bg-gradient-to-b from-white via-ygg-accent/30 to-ygg-accent-2 bg-clip-text text-transparent [filter:drop-shadow(0_0_40px_var(--accent-glow))]">
          YGGDRASIL
          <span className="absolute top-[10%] -right-[4%] text-[0.14em] text-ygg-accent font-normal [filter:drop-shadow(0_0_18px_var(--accent))] [-webkit-text-fill-color:var(--accent)]">
            ᛟ
          </span>
        </h1>

        <p className="text-ygg-text-dim text-base md:text-lg max-w-[520px] mb-10 font-light leading-relaxed">
          A cohesive ReShade shader suite built for PC gamers. Depth, clarity,
          colour, and atmosphere bound together.
        </p>

        <div className="flex gap-5 items-center">
          <a href="#install" className="px-10 py-4 rounded-[2px] font-mono font-bold text-xs uppercase tracking-[0.15em] no-underline transition-all duration-300 inline-flex items-center gap-3 bg-ygg-accent text-white border border-ygg-accent [box-shadow:0_0_30px_var(--accent-glow)] hover:bg-white hover:text-ygg-bg hover:border-white hover:[box-shadow:0_0_40px_rgba(255,255,255,0.2)] magnetic-btn">
            Get Started
          </a>
          <a href="#shaders" className="px-10 py-4 rounded-[2px] font-mono font-bold text-xs uppercase tracking-[0.15em] no-underline transition-all duration-300 inline-flex items-center gap-3 border border-ygg-line bg-white/[0.02] backdrop-blur-[10px] text-ygg-text hover:border-ygg-accent hover:bg-[var(--accent-glow)] hover:[box-shadow:0_0_20px_var(--accent-glow)] magnetic-btn">
            Explore Shaders
          </a>
        </div>
      </div>
    </header>
  );
}
