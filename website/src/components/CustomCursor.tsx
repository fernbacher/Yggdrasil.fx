"use client";

import { useEffect, useRef } from "react";

export default function CustomCursor() {
  const dotRef = useRef<HTMLDivElement>(null);
  const ringRef = useRef<HTMLDivElement>(null);
  const mx = useRef(0);
  const my = useRef(0);
  const rx = useRef(0);
  const ry = useRef(0);
  const raf = useRef(0);

  useEffect(() => {
    const dot = dotRef.current;
    const ring = ringRef.current;
    if (!dot || !ring) return;

    const onMouseMove = (e: MouseEvent) => {
      mx.current = e.clientX;
      my.current = e.clientY;
      dot.style.left = mx.current + "px";
      dot.style.top = my.current + "px";
    };

    const animate = () => {
      rx.current += (mx.current - rx.current) * 0.15;
      ry.current += (my.current - ry.current) * 0.15;
      ring.style.left = rx.current + "px";
      ring.style.top = ry.current + "px";
      raf.current = requestAnimationFrame(animate);
    };
    raf.current = requestAnimationFrame(animate);

    const onEnter = () => ring.classList.add("hover");
    const onLeave = () => ring.classList.remove("hover");

    const hoverTargets = document.querySelectorAll(
      "a, button, [data-cursor-hover]"
    );
    hoverTargets.forEach((el) => {
      el.addEventListener("mouseenter", onEnter);
      el.addEventListener("mouseleave", onLeave);
    });

    document.addEventListener("mousemove", onMouseMove);

    return () => {
      cancelAnimationFrame(raf.current);
      document.removeEventListener("mousemove", onMouseMove);
      hoverTargets.forEach((el) => {
        el.removeEventListener("mouseenter", onEnter);
        el.removeEventListener("mouseleave", onLeave);
      });
    };
  }, []);

  return (
    <>
      <div ref={dotRef} className="cursor-dot" />
      <div ref={ringRef} className="cursor-ring" />
    </>
  );
}
