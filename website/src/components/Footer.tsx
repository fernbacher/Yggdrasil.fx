export default function Footer() {
  return (
    <footer className="px-6 md:px-16 py-16 border-t border-ygg-line flex flex-col md:flex-row justify-between md:items-end gap-8 text-sm text-ygg-text-mute">
      <div>
        <div className="text-2xl tracking-[5px] text-ygg-text-dim opacity-30">
          ᛁᚷᚷᛞᚱᚨᛋᛁᛚ · ᚠᛟᚱ · ᛚᛁᚾᚢᛉ
        </div>
        <p className="mt-4">Open-source shaders for PC gaming.</p>
      </div>
      <div className="text-left md:text-right">
        <p>
          <a
            href="https://github.com/fernbacher/Yggdrasil.fx"
            target="_blank"
            rel="noopener noreferrer"
            className="text-ygg-text no-underline border-b border-ygg-line hover:border-ygg-accent transition-colors"
          >
            GitHub Repository →
          </a>
        </p>
        <p className="mt-2 text-ygg-text-mute">
          Linux · Windows · Proton · Vulkan · D3D9
        </p>
      </div>
    </footer>
  );
}
