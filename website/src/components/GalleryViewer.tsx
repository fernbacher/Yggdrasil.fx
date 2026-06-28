"use client";

import { useRef, useCallback, useEffect } from "react";

export default function GalleryViewer() {
  const viewerRef = useRef<HTMLDivElement>(null);
  const imgTopRef = useRef<HTMLImageElement>(null);
  const handleRef = useRef<HTMLDivElement>(null);
  const isDragging = useRef(false);

  const moveSlider = useCallback((clientX: number) => {
    const viewer = viewerRef.current;
    const imgTop = imgTopRef.current;
    const handle = handleRef.current;
    if (!viewer || !imgTop || !handle) return;

    const rect = viewer.getBoundingClientRect();
    let x = clientX - rect.left;
    if (x < 0) x = 0;
    if (x > rect.width) x = rect.width;
    const percent = (x / rect.width) * 100;

    handle.style.left = `${percent}%`;
    imgTop.style.clipPath = `inset(0 0 0 ${percent}%)`;

    if (!viewer.classList.contains("dragging")) {
      viewer.classList.add("dragging");
    }
  }, []);

  const stopDragging = useCallback(() => {
    isDragging.current = false;
    viewerRef.current?.classList.remove("dragging");
  }, []);

  useEffect(() => {
    const viewer = viewerRef.current;
    if (!viewer) return;

    const onMouseDown = (e: MouseEvent) => {
      isDragging.current = true;
      moveSlider(e.clientX);
    };

    const onMouseMove = (e: MouseEvent) => {
      if (isDragging.current) moveSlider(e.clientX);
    };

    const onTouchStart = (e: TouchEvent) => {
      isDragging.current = true;
      moveSlider(e.touches[0].clientX);
    };

    const onTouchMove = (e: TouchEvent) => {
      if (isDragging.current) {
        moveSlider(e.touches[0].clientX);
        e.preventDefault();
      }
    };

    const onKeyDown = (e: KeyboardEvent) => {
      const handle = handleRef.current;
      if (!handle) return;
      const rect = viewer.getBoundingClientRect();
      const currentPercent = parseFloat(handle.style.left) || 50;
      const currentX = (currentPercent / 100) * rect.width;
      if (e.key === "ArrowLeft") moveSlider(currentX - 20);
      if (e.key === "ArrowRight") moveSlider(currentX + 20);
    };

    viewer.addEventListener("mousedown", onMouseDown);
    document.addEventListener("mousemove", onMouseMove);
    document.addEventListener("mouseup", stopDragging);
    viewer.addEventListener("touchstart", onTouchStart, { passive: true });
    document.addEventListener("touchmove", onTouchMove, { passive: false });
    document.addEventListener("touchend", stopDragging);
    viewer.addEventListener("keydown", onKeyDown);

    return () => {
      viewer.removeEventListener("mousedown", onMouseDown);
      document.removeEventListener("mousemove", onMouseMove);
      document.removeEventListener("mouseup", stopDragging);
      viewer.removeEventListener("touchstart", onTouchStart);
      document.removeEventListener("touchmove", onTouchMove);
      document.removeEventListener("touchend", stopDragging);
      viewer.removeEventListener("keydown", onKeyDown);
    };
  }, [moveSlider, stopDragging]);

  return (
    <section
      id="gallery"
      className="py-40 bg-ygg-surface border-y border-ygg-line"
    >
      <div className="max-w-[1400px] mx-auto px-6 md:px-16">
        <div className="grid grid-cols-1 lg:grid-cols-[0.8fr_1.2fr] gap-24 items-center">
          {/* Text side */}
          <div>
            <span className="font-mono text-xs text-ygg-accent uppercase tracking-[0.2em] font-bold">
              Visual Proof
            </span>
            <h2 className="text-7xl font-bold tracking-[-0.04em] leading-none mt-2 mb-6">
              The
              <br />
              Pipeline.
            </h2>
            <p className="text-ygg-text-dim text-lg max-w-[400px] font-light mb-8">
              Experience the exact transformation Yggdrasil applies to the
              rendered frame. Every shader in the suite works in harmony to
              produce the final image.
            </p>
            <div className="font-mono text-xs text-ygg-accent uppercase tracking-[0.1em] flex items-center gap-2">
              <span>⇔</span> Drag to compare
            </div>
          </div>

          {/* Viewer */}
          <div className="relative">
            <div
              ref={viewerRef}
              data-cursor-hover
              tabIndex={0}
              className="relative w-full aspect-video rounded-[2px] overflow-hidden bg-black select-none border border-ygg-line"
              style={{ cursor: "ew-resize" }}
            >
              {/* Viewfinder */}
              <div className="absolute inset-0 pointer-events-none z-[2]">
                <div className="absolute top-4 left-4 w-6 h-6 border border-white opacity-50 border-r-0 border-b-0" />
                <div className="absolute top-4 right-4 w-6 h-6 border border-white opacity-50 border-l-0 border-b-0" />
                <div className="absolute bottom-4 left-4 w-6 h-6 border border-white opacity-50 border-r-0 border-t-0" />
                <div className="absolute bottom-4 right-4 w-6 h-6 border border-white opacity-50 border-l-0 border-t-0" />
                <div className="absolute top-4 left-1/2 -translate-x-1/2 font-mono text-[0.65rem] text-white uppercase tracking-[0.2em] opacity-70 flex items-center gap-2">
                  <span className="text-[#ff4c4c] animate-[pulse_2s_infinite]">
                    ●
                  </span>
                  LIVE FEED
                </div>
              </div>

              {/* Bottom image (off) */}
              <img
                src="/images/comparisons/gowyggoff.png"
                className="absolute top-0 left-0 w-full h-full object-cover pointer-events-none"
                alt="Raw engine output"
              />
              {/* Top image (on) — clipped to show comparison */}
              <img
                ref={imgTopRef}
                src="/images/comparisons/gowyggon.png"
                className="absolute top-0 left-0 w-full h-full object-cover pointer-events-none"
                style={{ clipPath: "inset(0 0 0 50%)" }}
                alt="Yggdrasil pipeline applied"
              />

              {/* Handle */}
              <div
                ref={handleRef}
                className="absolute top-0 left-[50%] w-[2px] h-full bg-white/80 -translate-x-1/2 pointer-events-none [box-shadow:0_0_15px_var(--accent)] z-[3] transition-[background,box-shadow] duration-200 [.dragging_&]:bg-white [.dragging_&]:[box-shadow:0_0_30px_var(--accent),0_0_60px_var(--accent)]"
              >
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white bg-ygg-accent w-10 h-10 rounded-full flex items-center justify-center border-2 border-white text-base [box-shadow:0_0_15px_var(--accent)] transition-transform duration-200 [.dragging_&]:scale-125 [.dragging_&]:bg-white [.dragging_&]:text-ygg-accent [.dragging_&]:[writing-mode:horizontal-tb]">
                  ⇔
                </div>
              </div>

              {/* Labels */}
              <div className="absolute bottom-4 left-4 px-3 py-1.5 bg-black/70 backdrop-blur-[10px] font-mono text-[0.65rem] uppercase tracking-[0.1em] text-ygg-text-dim border border-ygg-line z-[2]">
                Raw Engine Output
              </div>
              <div className="absolute bottom-4 right-4 px-3 py-1.5 bg-black/70 backdrop-blur-[10px] font-mono text-[0.65rem] uppercase tracking-[0.1em] text-ygg-accent border border-ygg-line z-[2]">
                Yggdrasil Pipeline
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
