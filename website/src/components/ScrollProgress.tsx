"use client";

import { useEffect } from "react";

export default function ScrollProgress() {
  useEffect(() => {
    const bar = document.getElementById("scroll-progress-bar");
    if (!bar) return;

    const onScroll = () => {
      const h = document.documentElement;
      const st = h.scrollTop || document.body.scrollTop;
      const sh = h.scrollHeight || document.body.scrollHeight;
      bar.style.width = (st / (sh - h.clientHeight)) * 100 + "%";
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return <div id="scroll-progress-bar" className="scroll-progress" />;
}
