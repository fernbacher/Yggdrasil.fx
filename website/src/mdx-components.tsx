import type { MDXComponents } from "mdx/types";

export function useMDXComponents(components: MDXComponents): MDXComponents {
  return {
    h1: ({ children, ...props }) => (
      <h1
        className="text-6xl md:text-7xl font-extrabold tracking-[-0.04em] mb-8 mt-16 leading-none"
        {...props}
      >
        {children}
      </h1>
    ),
    h2: ({ children, ...props }) => (
      <h2
        className="text-3xl font-bold tracking-[-0.02em] mb-6 mt-12 text-ygg-text"
        {...props}
      >
        {children}
      </h2>
    ),
    h3: ({ children, ...props }) => (
      <h3
        className="text-xl font-semibold mb-4 mt-8 text-ygg-text-dim"
        {...props}
      >
        {children}
      </h3>
    ),
    p: ({ children, ...props }) => (
      <p
        className="text-ygg-text-dim leading-relaxed mb-6 max-w-[65ch]"
        {...props}
      >
        {children}
      </p>
    ),
    a: ({ children, ...props }) => (
      <a
        className="text-ygg-accent no-underline border-b border-ygg-line hover:border-ygg-accent transition-colors"
        {...props}
      >
        {children}
      </a>
    ),
    ul: ({ children, ...props }) => (
      <ul className="list-none mb-6 space-y-2" {...props}>
        {children}
      </ul>
    ),
    ol: ({ children, ...props }) => (
      <ol className="list-decimal list-inside mb-6 space-y-2 text-ygg-text-dim" {...props}>
        {children}
      </ol>
    ),
    li: ({ children, ...props }) => (
      <li
        className="text-ygg-text-dim pl-6 relative before:absolute before:left-0 before:top-[0.6em] before:w-1.5 before:h-1.5 before:bg-ygg-accent before:rounded-full"
        {...props}
      >
        {children}
      </li>
    ),
    code: ({ children, ...props }) => (
      <code
        className="font-mono text-sm bg-white/[0.04] border border-ygg-line px-1.5 py-0.5 rounded-[2px] text-ygg-text"
        {...props}
      >
        {children}
      </code>
    ),
    pre: ({ children, ...props }) => (
      <pre
        className="font-mono text-sm bg-black/30 border border-ygg-line p-6 rounded-[2px] overflow-x-auto mb-6 text-ygg-text-dim"
        {...props}
      >
        {children}
      </pre>
    ),
    table: ({ children, ...props }) => (
      <div className="overflow-x-auto mb-8">
        <table
          className="w-full border-collapse text-sm text-ygg-text-dim"
          {...props}
        >
          {children}
        </table>
      </div>
    ),
    th: ({ children, ...props }) => (
      <th
        className="font-mono text-xs uppercase tracking-[0.1em] text-ygg-text text-left p-3 border-b border-ygg-line bg-white/[0.02]"
        {...props}
      >
        {children}
      </th>
    ),
    td: ({ children, ...props }) => (
      <td
        className="p-3 border-b border-ygg-line font-mono text-xs"
        {...props}
      >
        {children}
      </td>
    ),
    hr: (props) => (
      <hr className="border-ygg-line my-12" {...props} />
    ),
    ...components,
  };
}
