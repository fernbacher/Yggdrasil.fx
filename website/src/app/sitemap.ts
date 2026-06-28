import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = "https://yggdrasil.fx";

  return [
    { url: baseUrl, lastModified: new Date(), changeFrequency: "monthly", priority: 1 },
    { url: `${baseUrl}/docs`, lastModified: new Date(), changeFrequency: "monthly", priority: 0.8 },
    { url: `${baseUrl}/download`, lastModified: new Date(), changeFrequency: "monthly", priority: 0.9 },
    { url: `${baseUrl}/blog`, lastModified: new Date(), changeFrequency: "weekly", priority: 0.7 },
    { url: `${baseUrl}/blog/v1-0-release`, lastModified: new Date(), changeFrequency: "never", priority: 0.5 },
  ];
}
