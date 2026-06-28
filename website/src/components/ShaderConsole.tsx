"use client";

import { useState, useCallback } from "react";
import { shaders } from "@/lib/shaders";

function generateTerminal(name: string) {
  return [
    { text: `> exec Ygg${name.replace(/\s/g, "")}.fx`, cls: "text-ygg-accent" },
    { text: `Compiling technique [Ygg${name.replace(/\s/g, "")}]...`, cls: "" },
    { text: `Texture reads optimized.`, cls: "" },
    { text: `[OK] Technique loaded successfully.`, cls: "text-ygg-green" },
  ];
}

export default function ShaderConsole() {
  const [activeIndex, setActiveIndex] = useState(0);
  const active = shaders[activeIndex];
  const [termLines, setTermLines] = useState<{ text: string; cls: string }[]>(
    () => generateTerminal(shaders[0].name)
  );

  const setActive = useCallback((index: number) => {
    setActiveIndex(index);
    const lines = generateTerminal(shaders[index].name);
    setTermLines([]);
    const t = setTimeout(() => setTermLines(lines), 1);
    return () => clearTimeout(t);
  }, []);

  return (
    <section id="shaders" className="py-40 relative">
      <div className="max-w-[1400px] mx-auto px-6 md:px-16">
        <div className="grid grid-cols-1 lg:grid-cols-[1fr_1.2fr] gap-16 min-h-[100vh]">
          {/* Left: Shader Inspector */}
          <div className="sticky top-0 h-[100vh] flex flex-col justify-center pr-8 lg:border-r border-ygg-line overflow-hidden">
            {/* Scanline */}
            <div className="absolute top-0 left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-ygg-accent to-transparent opacity-30 animate-[scanLine_4s_linear_infinite] z-[5]" />

            <div className="flex justify-between items-center mb-8 pb-4 border-b border-ygg-line">
              <h3 className="text-sm uppercase tracking-[0.2em] text-ygg-text-mute font-mono">
                {"// Shader Inspector"}
              </h3>
              <div className="w-2 h-2 bg-ygg-green rounded-full [box-shadow:0_0_10px_#4cff4c] animate-[pulse_2s_infinite]" />
            </div>

            <div className="flex gap-8 items-start mb-8">
              <div className="text-8xl leading-none text-ygg-accent [filter:drop-shadow(0_0_20px_var(--accent-glow))]">
                {active.rune}
              </div>
              <div className="flex-1">
                <h2 className="text-6xl font-extrabold tracking-[-0.04em] mb-4 leading-none">
                  {active.name}
                </h2>
                <p className="text-lg text-ygg-text-dim max-w-[500px] font-light mb-6">
                  {active.shortDesc}
                </p>
                <span className="inline-block px-3 py-1.5 border border-ygg-accent rounded-[2px] text-xs uppercase tracking-[0.1em] text-ygg-accent bg-[var(--accent-glow)] font-mono font-bold">
                  {active.tag}
                </span>
              </div>
            </div>

            {/* Terminal */}
            <div className="bg-black border border-ygg-line p-6 rounded-[2px] font-mono text-xs text-ygg-text-dim mb-6 min-h-[100px]">
              {termLines.map((line, i) => (
                <div
                  key={i}
                  className="mb-2 opacity-0 -translate-y-1"
                  style={{
                    animation: `termAppear 0.3s forwards`,
                    animationDelay: `${i * 0.15}s`,
                  }}
                >
                  <span className={line.cls}>{line.text}</span>
                </div>
              ))}
            </div>

            {/* Performance Bars */}
            <div className="flex flex-col gap-4">
              <div className="flex items-center gap-4">
                <span className="w-[120px] font-mono text-xs text-ygg-text-mute uppercase">
                  Performance Cost
                </span>
                <div className="flex-1 h-1 bg-ygg-line rounded-[2px] overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-ygg-accent to-ygg-accent-2 rounded-[2px] transition-[width] duration-600"
                    style={{ width: `${active.cost}%` }}
                  />
                </div>
              </div>
              <div className="flex items-center gap-4">
                <span className="w-[120px] font-mono text-xs text-ygg-text-mute uppercase">
                  Visual Impact
                </span>
                <div className="flex-1 h-1 bg-ygg-line rounded-[2px] overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-ygg-accent to-ygg-accent-2 rounded-[2px] transition-[width] duration-600"
                    style={{ width: `${active.impact}%` }}
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Right: Shader List */}
          <div className="flex flex-col">
            {shaders.map((s, i) => (
              <div
                key={s.name}
                data-cursor-hover
                data-index={i}
                className={`flex justify-between items-center py-12 border-b border-ygg-line cursor-pointer transition-all duration-300 relative hover:pl-8 [&.active]:pl-8 first:border-t ${
                  i === activeIndex ? "active" : ""
                }`}
                onMouseEnter={() => setActive(i)}
                onClick={() => setActive(i)}
              >
                {/* Active line indicator */}
                <div
                  className={`absolute left-0 top-1/2 h-[1px] bg-ygg-accent transition-all duration-300 ${
                    i === activeIndex ? "w-6" : "w-0 group-hover:w-6"
                  }`}
                />
                <div className="flex items-center gap-8">
                  <span
                    className={`text-2xl w-[30px] transition-colors duration-300 ${
                      i === activeIndex
                        ? "text-ygg-accent"
                        : "text-ygg-text-mute"
                    }`}
                  >
                    {s.rune}
                  </span>
                  <span className="text-2xl font-medium tracking-[-0.02em]">
                    {s.name}
                  </span>
                </div>
                <span className="font-mono text-xs text-ygg-text-mute tabular-nums">
                  {String(i + 1).padStart(2, "0")}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
