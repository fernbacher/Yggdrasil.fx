import { DownloadSimple, GithubLogo } from "@phosphor-icons/react/dist/ssr";
import Navigation from "@/components/Navigation";
import Footer from "@/components/Footer";

export const metadata = {
  title: "Download — Yggdrasil.fx",
  description: "Download the Yggdrasil ReShade shader suite from GitHub Releases. Latest version with all 16 shaders.",
};

export default function DownloadPage() {
  return (
    <>
      <Navigation />
      <main className="pt-32 pb-32 min-h-[100dvh] flex items-center">
        <div className="max-w-[1000px] mx-auto px-6 md:px-16 w-full">
          <h1 className="text-6xl md:text-7xl font-extrabold tracking-[-0.04em] mb-6">
            Download
          </h1>
          <p className="text-ygg-text-dim text-lg max-w-[600px] font-light mb-16">
            Grab the latest release or browse version history on GitHub.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {/* Primary Download */}
            <a
              href="https://github.com/fernbacher/Yggdrasil.fx/releases"
              target="_blank"
              rel="noopener noreferrer"
              className="bg-ygg-accent text-white no-underline rounded-[2px] p-12 flex flex-col justify-between transition-all duration-300 hover:bg-white hover:text-ygg-bg hover:[box-shadow:0_0_40px_rgba(255,255,255,0.2)] group"
            >
              <DownloadSimple weight="bold" className="text-5xl mb-6" />
              <div>
                <h2 className="text-3xl font-bold tracking-[-0.02em] mb-2">
                  Latest Release
                </h2>
                <p className="opacity-80 font-mono text-sm uppercase tracking-[0.1em]">
                  GitHub Releases → v1.0
                </p>
              </div>
            </a>

            {/* Source Code */}
            <a
              href="https://github.com/fernbacher/Yggdrasil.fx"
              target="_blank"
              rel="noopener noreferrer"
              className="bg-ygg-surface border border-ygg-line rounded-[2px] p-12 flex flex-col justify-between transition-all duration-300 hover:border-ygg-accent hover:bg-[var(--accent-glow)] group"
            >
              <GithubLogo weight="bold" className="text-5xl mb-6 text-ygg-text" />
              <div>
                <h2 className="text-3xl font-bold tracking-[-0.02em] mb-2 text-ygg-text">
                  Source Code
                </h2>
                <p className="text-ygg-text-dim font-mono text-sm uppercase tracking-[0.1em]">
                  View on GitHub →
                </p>
              </div>
            </a>
          </div>

          {/* Quick Install */}
          <div className="mt-24 border-t border-ygg-line pt-16">
            <h2 className="text-2xl font-bold tracking-[-0.02em] mb-6">
              Quick Install
            </h2>
            <div className="bg-ygg-surface border border-ygg-line p-8 rounded-[2px] font-mono text-sm text-ygg-text-dim space-y-2">
              <p className="text-ygg-accent"># 1. Download the latest release from GitHub</p>
              <p className="text-ygg-text-dim"># 2. Extract the archive</p>
              <p className="text-ygg-text-dim"># 3. Copy all Ygg*.fx and Ygg*.fxh files into:</p>
              <p className="text-ygg-text pl-4">&lt;game directory&gt;/reshade-shaders/Shaders/</p>
              <p className="text-ygg-text-dim mt-4"># 4. Enable shaders in ReShade overlay (Home key)</p>
              <p className="text-ygg-text-dim"># 5. Follow the recommended load order from the docs</p>
            </div>
          </div>

          {/* Compatibility */}
          <div className="mt-16">
            <h2 className="text-2xl font-bold tracking-[-0.02em] mb-6">
              Compatibility
            </h2>
            <div className="flex flex-wrap gap-4">
              <Badge>Linux (Proton)</Badge>
              <Badge>Windows</Badge>
              <Badge>Vulkan</Badge>
              <Badge>D3D9</Badge>
              <Badge>ReShade 5.8+</Badge>
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}

function Badge({ children }: { children: string }) {
  return (
    <span className="px-4 py-2 border border-ygg-line rounded-[2px] font-mono text-xs text-ygg-text-dim uppercase tracking-[0.1em]">
      {children}
    </span>
  );
}
