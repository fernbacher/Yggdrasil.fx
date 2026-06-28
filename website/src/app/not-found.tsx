import Link from "next/link";
import Navigation from "@/components/Navigation";
import Footer from "@/components/Footer";

export default function NotFound() {
  return (
    <>
      <Navigation />
      <main className="min-h-[100dvh] flex items-center justify-center">
        <div className="text-center px-6">
          <div className="font-mono text-8xl text-ygg-accent mb-8 [filter:drop-shadow(0_0_30px_var(--accent-glow))]">
            ᛟ
          </div>
          <h1 className="text-4xl font-bold tracking-[-0.04em] mb-4">Page Not Found</h1>
          <p className="text-ygg-text-dim mb-8 max-w-[400px] mx-auto">
            This branch of Yggdrasil doesn&apos;t exist. Return to the root.
          </p>
          <Link
            href="/"
            className="inline-flex items-center gap-3 px-9 py-4 rounded-[2px] font-mono font-bold text-xs uppercase tracking-[0.15em] no-underline transition-all duration-300 border border-ygg-line bg-white/[0.02] backdrop-blur-[10px] text-ygg-text hover:border-ygg-accent hover:bg-[var(--accent-glow)] hover:[box-shadow:0_0_20px_var(--accent-glow)]"
          >
            Return Home
          </Link>
        </div>
      </main>
      <Footer />
    </>
  );
}
