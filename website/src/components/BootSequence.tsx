"use client";

import { useEffect, useState, useCallback } from "react";

const bootLines = [
  { text: "> YGGDRASIL.SHADER_SUITE v1.0", color: "text-ygg-accent" },
  { text: "> Initializing interop layer...", color: "" },
  { text: "> Mounting ReShade environment...", color: "" },
  { text: "> Compiling YggCore.fxh...", color: "" },
  { text: "> Linking YggEdgeAA_Temporal.fx...", color: "" },
  { text: "> Verifying Oklab color space...", color: "text-ygg-warn" },
  { text: "> Optimizing texture reads...", color: "" },
  { text: "[OK] Pipeline initialized successfully.", color: "text-ygg-green" },
];

export default function BootSequence() {
  const [lines, setLines] = useState<string[]>([]);
  const [barPct, setBarPct] = useState(0);
  const [hidden, setHidden] = useState(false);
  const [done, setDone] = useState(false);

  useEffect(() => {
    let cancelled = false;
    const run = async () => {
      for (let i = 0; i < bootLines.length; i++) {
        if (cancelled) return;
        await new Promise((r) => setTimeout(r, 280));
        if (cancelled) return;
        setLines((prev) => [...prev, bootLines[i].text]);
        setBarPct(((i + 1) / bootLines.length) * 100);
      }
    };
    run();
    return () => { cancelled = true; };
  }, []);

  const handleLaunch = useCallback(() => {
    setHidden(true);
    document.body.classList.add("loaded");
    setTimeout(() => setDone(true), 800);
  }, []);

  if (done) return null;

  return (
    <div
      className={`fixed inset-0 z-[10000] bg-ygg-bg flex flex-col items-center justify-center transition-opacity duration-800 ${hidden ? "opacity-0 pointer-events-none" : ""}`}
    >
      <div className="w-full max-w-[500px] px-8 text-center">
        {/* Brand */}
        <div className="font-mono text-2xl font-bold text-ygg-text tracking-[0.1em] mb-8 uppercase flex items-center justify-center gap-3">
          YGGDRASIL{" "}
          <span className="text-ygg-accent font-normal text-xl [filter:drop-shadow(0_0_10px_var(--accent))]">
            ᛟ
          </span>
        </div>

        {/* Terminal */}
        <div className="font-mono text-xs text-ygg-text-dim text-left min-h-[180px] mb-8 bg-black/30 border border-ygg-line p-6 rounded-[2px] relative overflow-hidden">
          {/* Scanline */}
          <div className="absolute top-0 left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-ygg-accent to-transparent opacity-50 animate-[scanLine_4s_linear_infinite]" />
          {lines.map((line, i) => {
            const template = bootLines.find((b) => b.text === line);
            const colorClass = template?.color ?? "";
            return (
              <div
                key={i}
                className="mb-1 whitespace-pre-wrap opacity-0 animate-[termAppear_0.1s_forwards]"
                style={{ animationDelay: "0s" }}
              >
                <span className={colorClass}>{line}</span>
              </div>
            );
          })}
          {lines.length === bootLines.length && (
            <div className="mb-1 whitespace-pre-wrap">
              <span className="text-ygg-accent">&gt; </span>
              <span className="inline-block w-2 h-3.5 bg-ygg-accent align-middle ml-0.5 animate-[blink_1s_steps(2)_infinite]" />
            </div>
          )}
        </div>

        {/* Progress Bar */}
        <div className="w-full h-[2px] bg-ygg-line mb-8 overflow-hidden rounded-[2px]">
          <div
            className="h-full bg-gradient-to-r from-ygg-accent to-ygg-accent-2 transition-[width] duration-300 [box-shadow:0_0_10px_var(--accent)]"
            style={{ width: `${barPct}%` }}
          />
        </div>

        {/* Launch Button */}
        <button
          onClick={handleLaunch}
          className={`inline-flex items-center gap-3 px-9 py-4 rounded-[2px] font-mono font-bold text-xs uppercase tracking-[0.15em] no-underline transition-all duration-300 border bg-ygg-accent text-white border-ygg-accent [box-shadow:0_0_30px_var(--accent-glow)] hover:bg-white hover:text-ygg-bg hover:border-white hover:[box-shadow:0_0_40px_rgba(255,255,255,0.2)] ${lines.length >= bootLines.length ? "opacity-100 translate-y-0 pointer-events-auto" : "opacity-0 translate-y-2.5 pointer-events-none"}`}
        >
          Launch Pipeline
        </button>
      </div>
    </div>
  );
}
