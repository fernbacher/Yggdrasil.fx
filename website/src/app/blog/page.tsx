import Link from "next/link";
import Navigation from "@/components/Navigation";
import Footer from "@/components/Footer";

interface PostMeta {
  slug: string;
  title: string;
  date: string;
  excerpt: string;
}

// Static post list — add new posts here
const posts: PostMeta[] = [
  {
    slug: "v1-0-release",
    title: "Yggdrasil.fx v1.0 — Initial Release",
    date: "2026-06-28",
    excerpt:
      "The first public release of the Yggdrasil ReShade shader suite. Sixteen shaders, cross-platform support, and a fully documented pipeline.",
  },
];

export const metadata = {
  title: "Blog — Yggdrasil.fx",
  description: "Release notes, changelog, and development updates for the Yggdrasil ReShade shader suite.",
};

export default function BlogPage() {
  return (
    <>
      <Navigation />
      <main className="pt-32 pb-32 min-h-[100dvh]">
        <div className="max-w-[1000px] mx-auto px-6 md:px-16">
          <h1 className="text-6xl md:text-7xl font-extrabold tracking-[-0.04em] mb-6">
            Blog
          </h1>
          <p className="text-ygg-text-dim text-lg max-w-[600px] font-light mb-16">
            Release notes, changelog, and development updates.
          </p>

          <div className="space-y-0">
            {posts.map((post) => (
              <Link
                key={post.slug}
                href={`/blog/${post.slug}`}
                className="block py-10 border-b border-ygg-line hover:bg-white/[0.01] transition-all group"
              >
                <article>
                  <time className="font-mono text-xs text-ygg-text-mute uppercase tracking-[0.1em] mb-3 block">
                    {new Date(post.date).toLocaleDateString("en-US", {
                      year: "numeric",
                      month: "long",
                      day: "numeric",
                    })}
                  </time>
                  <h2 className="text-2xl font-bold tracking-[-0.02em] mb-3 group-hover:text-ygg-accent transition-colors">
                    {post.title}
                  </h2>
                  <p className="text-ygg-text-dim leading-relaxed max-w-[65ch]">
                    {post.excerpt}
                  </p>
                </article>
              </Link>
            ))}
          </div>

          {posts.length === 0 && (
            <div className="text-center py-24">
              <p className="text-ygg-text-mute font-mono text-sm">
                No posts yet. Check back soon.
              </p>
            </div>
          )}
        </div>
      </main>
      <Footer />
    </>
  );
}
