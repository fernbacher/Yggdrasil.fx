import { shaders, shadersByLoadOrder } from "@/lib/shaders";
import Navigation from "@/components/Navigation";
import Footer from "@/components/Footer";

export const metadata = {
  title: "Documentation — Yggdrasil.fx",
  description: "Per-shader documentation, load order details, and technical reference for the Yggdrasil ReShade shader suite.",
};

export default function DocsPage() {
  return (
    <>
      <Navigation />
      <main className="pt-32 pb-32">
        <div className="max-w-[1000px] mx-auto px-6 md:px-16">
          {/* Header */}
          <h1 className="text-6xl md:text-7xl font-extrabold tracking-[-0.04em] mb-6">
            Documentation
          </h1>
          <p className="text-ygg-text-dim text-lg max-w-[600px] font-light mb-16">
            Everything you need to understand and configure each shader in the Yggdrasil pipeline.
          </p>

          {/* Load Order */}
          <section className="mb-24">
            <h2 className="text-3xl font-bold tracking-[-0.02em] mb-8">
              Recommended Load Order
            </h2>
            <p className="text-ygg-text-dim mb-8 max-w-[65ch]">
              Shaders execute in sequence. The order below ensures each effect has access to the correct
              input — debanding runs first on the raw frame, detail shaders share the LocalMean blur pre-pass,
              and finish effects apply last.
            </p>
            <div className="bg-ygg-surface border border-ygg-line p-8 rounded-[2px] overflow-x-auto">
              <table className="w-full border-collapse text-sm">
                <thead>
                  <tr>
                    <th className="font-mono text-xs uppercase tracking-[0.1em] text-ygg-text text-left p-3 border-b border-ygg-line bg-white/[0.02] w-20">
                      Order
                    </th>
                    <th className="font-mono text-xs uppercase tracking-[0.1em] text-ygg-text text-left p-3 border-b border-ygg-line bg-white/[0.02] w-40">
                      Shader
                    </th>
                    <th className="font-mono text-xs uppercase tracking-[0.1em] text-ygg-text text-left p-3 border-b border-ygg-line bg-white/[0.02]">
                      Category
                    </th>
                    <th className="font-mono text-xs uppercase tracking-[0.1em] text-ygg-text text-left p-3 border-b border-ygg-line bg-white/[0.02] w-28">
                      Perf Cost
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {shadersByLoadOrder.map((s) => (
                    <tr key={s.name} className="hover:bg-white/[0.02]">
                      <td className="p-3 border-b border-ygg-line font-mono text-xs text-ygg-accent">
                        {String(s.loadOrder).padStart(2, "0")}
                      </td>
                      <td className="p-3 border-b border-ygg-line font-mono text-xs text-ygg-text">
                        {s.name}
                      </td>
                      <td className="p-3 border-b border-ygg-line font-mono text-xs text-ygg-text-dim">
                        {s.category}
                      </td>
                      <td className="p-3 border-b border-ygg-line font-mono text-xs text-ygg-text-dim">
                        {s.cost}%
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          {/* Per-Shader Docs */}
          <section>
            <h2 className="text-3xl font-bold tracking-[-0.02em] mb-8">
              Shader Reference
            </h2>
            <div className="space-y-16">
              {shaders.map((s) => (
                <div key={s.name} id={s.name.toLowerCase().replace(/\s/g, "-")}>
                  <div className="flex items-center gap-6 mb-4">
                    <span className="text-5xl text-ygg-accent [filter:drop-shadow(0_0_15px_var(--accent-glow))]">
                      {s.rune}
                    </span>
                    <div>
                      <h3 className="text-3xl font-bold tracking-[-0.02em]">
                        Ygg{s.name}
                      </h3>
                      <div className="flex items-center gap-3 mt-1">
                        <span className="font-mono text-xs text-ygg-accent uppercase tracking-[0.1em]">
                          {s.tag}
                        </span>
                        <span className="text-ygg-text-mute">·</span>
                        <span className="font-mono text-xs text-ygg-text-mute">
                          Load order #{s.loadOrder}
                        </span>
                      </div>
                    </div>
                  </div>
                  <p className="text-ygg-text-dim leading-relaxed max-w-[75ch] mb-6">
                    {s.longDesc}
                  </p>
                  <div className="flex gap-12">
                    <div>
                      <div className="font-mono text-xs text-ygg-text-mute uppercase tracking-[0.1em] mb-1">
                        Perf Cost
                      </div>
                      <div className="text-ygg-text font-mono">{s.cost}%</div>
                    </div>
                    <div>
                      <div className="font-mono text-xs text-ygg-text-mute uppercase tracking-[0.1em] mb-1">
                        Visual Impact
                      </div>
                      <div className="text-ygg-text font-mono">{s.impact}%</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </section>

          {/* FAQ */}
          <section className="mt-24 border-t border-ygg-line pt-16">
            <h2 className="text-3xl font-bold tracking-[-0.02em] mb-8">FAQ</h2>
            <div className="space-y-8">
              <Faq q="What is Yggdrasil?" a="Yggdrasil is a curated suite of post-processing shaders for ReShade. It adds depth, clarity, colour grading, and atmosphere to games on Linux (via Proton) and Windows (Vulkan/D3D9)." />
              <Faq q="Do I need all shaders enabled?" a="No. The pipeline is modular — enable only the effects you want. The load order table shows the recommended sequence for whatever subset you choose." />
              <Faq q="Which shader has the highest performance cost?" a="SSAO and EdgeAA Temporal are the most expensive at 35–40%. Disable them if you need extra frames." />
              <Faq q="Can I use Yggdrasil with other shader suites?" a="Yes. Place Yggdrasil shaders at the top of your load order (before other suites) to ensure the cleanest input for downstream effects." />
            </div>
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}

function Faq({ q, a }: { q: string; a: string }) {
  return (
    <div>
      <h4 className="text-lg font-semibold mb-2 text-ygg-text">{q}</h4>
      <p className="text-ygg-text-dim leading-relaxed max-w-[65ch]">{a}</p>
    </div>
  );
}
