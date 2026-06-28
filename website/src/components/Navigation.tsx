import Link from "next/link";

const sectionLinks = [
  { href: "/#shaders", label: "Shaders" },
  { href: "/#gallery", label: "Gallery" },
  { href: "/#install", label: "Install" },
];

const pageLinks = [
  { href: "/docs", label: "Docs" },
  { href: "/download", label: "Download" },
  { href: "/blog", label: "Blog" },
];

export default function Navigation() {
  return (
    <nav className="fixed top-0 left-0 right-0 flex justify-between items-center px-6 md:px-16 py-8 z-[1000] mix-blend-difference">
      <Link
        href="/"
        className="font-mono font-bold text-[0.9rem] tracking-[0.1em] uppercase text-white no-underline flex items-center gap-2"
      >
        <svg viewBox="0 0 24 24" className="size-4" fill="none">
          <path d="M12 22 L8 18 M12 22 L12 15 M12 22 L16 18" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" opacity="0.5"/>
          <path d="M12 15 Q11 8 12 2" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
          <path d="M12 9 Q7 6 4 5" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round"/>
          <path d="M12 9 Q17 6 20 5" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round"/>
          <path d="M12 6 Q8 3 6 1" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/>
          <path d="M12 6 Q16 3 18 1" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/>
          <circle cx="12" cy="2" r="1.5" fill="#5b8cff" opacity="0.9"/>
          <circle cx="4" cy="5" r="0.8" fill="currentColor" opacity="0.5"/>
          <circle cx="20" cy="5" r="0.8" fill="currentColor" opacity="0.5"/>
          <circle cx="6" cy="1" r="0.6" fill="currentColor" opacity="0.4"/>
          <circle cx="18" cy="1" r="0.6" fill="currentColor" opacity="0.4"/>
        </svg>
        Yggdrasil
      </Link>
      <ul className="hidden md:flex gap-10 list-none">
        {sectionLinks.map((link) => (
          <li key={link.href}>
            <Link
              href={link.href}
              className="font-mono text-white no-underline text-xs font-normal uppercase tracking-[0.15em] opacity-60 hover:opacity-100 transition-opacity"
            >
              {link.label}
            </Link>
          </li>
        ))}
        {pageLinks.map((link) => (
          <li key={link.href}>
            <Link
              href={link.href}
              className="font-mono text-white no-underline text-xs font-normal uppercase tracking-[0.15em] opacity-60 hover:opacity-100 transition-opacity"
            >
              {link.label}
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
