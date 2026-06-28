import { shadersByLoadOrder } from "@/lib/shaders";

export default function InstallPipeline() {
  return (
    <section id="install" className="py-40 relative">
      <div className="max-w-[1400px] mx-auto px-6 md:px-16">
        <div className="mb-24">
          <span className="font-mono text-xs text-ygg-accent uppercase tracking-[0.2em] font-bold">
            Setup
          </span>
          <h2 className="text-7xl font-bold tracking-[-0.04em] mt-2">
            Installation Pipeline
          </h2>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-24">
          {/* Steps */}
          <div className="relative pl-8 border-l border-ygg-line">
            <Step
              label="Step 01"
              title="Copy the shader files"
              text="Place all Ygg*.fx and Ygg*.fxh files into your ReShade Shaders/ folder."
            />
            <Step
              label="Step 02"
              title="Set the load order"
              text="Enable shaders in the recommended order to ensure pipeline correctness."
            />
            <Step
              label="Step 03"
              title="Enable & tune"
              text="Enable techniques in ReShade, adjust sliders to taste. Save your preset."
            />
            <Step
              label="Step 04"
              title="Launch your game"
              text="Yggdrasil is tested on Proton, Vulkan, and D3D9. Boot your game and enjoy."
            />
          </div>

          {/* Info boxes */}
          <div className="flex flex-col gap-8">
            <div className="bg-ygg-surface border border-ygg-line p-8 rounded-[2px]">
              <div className="font-mono text-xs uppercase tracking-[0.15em] text-ygg-text mb-6 flex items-center gap-2">
                <span className="text-ygg-accent">◈</span> Recommended Load Order
              </div>
              <div className="flex flex-col gap-2.5 font-mono text-sm text-ygg-text-dim">
                {shadersByLoadOrder.map((s) => (
                  <span key={s.name} className="flex items-center gap-4">
                    <span className="text-ygg-accent font-bold">
                      {String(s.loadOrder).padStart(2, "0")}
                    </span>
                    {s.name}
                  </span>
                ))}
              </div>
            </div>

            <div className="bg-ygg-surface border border-ygg-line p-8 rounded-[2px]">
              <div className="font-mono text-xs uppercase tracking-[0.15em] text-ygg-text mb-6 flex items-center gap-2">
                <span className="text-ygg-accent">◈</span> EdgeAA Temporal Debug
                Mode
              </div>
              <div className="grid grid-cols-2 gap-2">
                <DebugItem dotColor="bg-white" label="0 = Disabled" />
                <DebugItem dotColor="bg-[#ff4c4c]" label="1 = Motion" />
                <DebugItem dotColor="bg-ygg-green" label="2 = History" />
                <DebugItem dotColor="bg-[#4c4cff]" label="3 = Confidence" />
              </div>
            </div>
          </div>
        </div>

        {/* Cross-platform badge */}
        <div className="mt-24 text-center">
          <div className="inline-flex items-center gap-2 px-6 py-3 border border-ygg-accent rounded-[2px] font-mono text-xs font-bold uppercase tracking-[0.15em] text-ygg-text bg-[var(--accent-glow)]">
            <span className="w-1.5 h-1.5 bg-ygg-green rounded-full [box-shadow:0_0_10px_#4cff4c]" />
            Linux & Windows · Proton-tested · Vulkan-ready
          </div>
        </div>
      </div>
    </section>
  );
}

function Step({
  label,
  title,
  text,
}: {
  label: string;
  title: string;
  text: string;
}) {
  return (
    <div className="relative pb-16 group">
      <div
        className="absolute -left-10 top-1.5 w-3 h-3 bg-ygg-bg border-2 border-ygg-text-mute rounded-full transition-all group-hover:border-ygg-accent group-hover:bg-ygg-accent group-hover:[box-shadow:0_0_15px_var(--accent)]"
      />
      <div className="font-mono text-[0.7rem] text-ygg-text-mute uppercase tracking-[0.2em] mb-2">
        {label}
      </div>
      <h3 className="text-2xl font-semibold mb-2">{title}</h3>
      <p className="text-ygg-text-dim max-w-[400px]">{text}</p>
    </div>
  );
}

function DebugItem({
  dotColor,
  label,
}: {
  dotColor: string;
  label: string;
}) {
  return (
    <div className="bg-white/[0.02] p-4 border border-ygg-line font-mono text-xs text-ygg-text-dim flex items-center gap-2">
      <div className={`w-2 h-2 rounded-full ${dotColor}`} />
      {label}
    </div>
  );
}
