"use client";

import { useEffect, useRef, type ReactNode } from "react";

export default function ScrollReveal({ children }: { children: ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    // Check if browser supports animation-timeline
    const supportsTimeline = CSS.supports("animation-timeline: view()");
    if (supportsTimeline) return; // CSS handles it

    // Fallback: IntersectionObserver
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.1 }
    );

    el.classList.add("reveal-animate");
    observer.observe(el);

    return () => observer.disconnect();
  }, []);

  return (
    <div ref={ref} className="reveal-animate">
      {children}
    </div>
  );
}
