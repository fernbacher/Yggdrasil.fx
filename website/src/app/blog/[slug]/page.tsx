import { notFound } from "next/navigation";
import Link from "next/link";
import Navigation from "@/components/Navigation";
import Footer from "@/components/Footer";

interface PostMeta {
  title: string;
  date: string;
  excerpt: string;
}

// Per-post metadata + lazy MDX import
const posts: Record<
  string,
  { meta: PostMeta; loader: () => Promise<{ default: React.ComponentType }> }
> = {
  "v1-0-release": {
    meta: {
      title: "Yggdrasil.fx v1.0 — Initial Release",
      date: "2026-06-28",
      excerpt:
        "The first public release of the Yggdrasil ReShade shader suite. Twelve shaders, cross-platform support, and a fully documented pipeline.",
    },
    loader: () => import("@/content/blog/v1-0-release.mdx"),
  },
};

export async function generateStaticParams() {
  return Object.keys(posts).map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const entry = posts[slug];
  if (!entry) return { title: "Not Found — Yggdrasil.fx" };
  return {
    title: `${entry.meta.title} — Yggdrasil.fx`,
    description: entry.meta.excerpt,
  };
}

export default async function BlogPost({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const entry = posts[slug];
  if (!entry) notFound();

  const { default: Content } = await entry.loader();

  return (
    <>
      <Navigation />
      <main className="pt-32 pb-32">
        <article className="max-w-[800px] mx-auto px-6 md:px-16">
          <Link
            href="/blog"
            className="font-mono text-xs text-ygg-text-mute uppercase tracking-[0.1em] no-underline hover:text-ygg-accent transition-colors mb-8 inline-block"
          >
            ← Back to blog
          </Link>

          <time className="font-mono text-xs text-ygg-text-mute uppercase tracking-[0.1em] mb-4 block">
            {new Date(entry.meta.date).toLocaleDateString("en-US", {
              year: "numeric",
              month: "long",
              day: "numeric",
            })}
          </time>

          <Content />
        </article>
      </main>
      <Footer />
    </>
  );
}
