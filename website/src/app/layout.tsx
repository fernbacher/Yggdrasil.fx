import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import CustomCursor from "@/components/CustomCursor";
import ScrollProgress from "@/components/ScrollProgress";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Yggdrasil.fx — ReShade Shader Suite",
  description:
    "A cohesive open-source ReShade shader suite for PC gaming. Depth, clarity, colour, and atmosphere — bound together. Linux & Windows, Proton-tested, Vulkan-ready.",
  keywords: [
    "ReShade",
    "shaders",
    "Yggdrasil",
    "post-processing",
    "gaming",
    "Vulkan",
    "Proton",
    "Linux",
    "Windows",
    "open source",
  ],
  icons: {
    icon: "/favicon.svg",
  },
  openGraph: {
    title: "Yggdrasil.fx — ReShade Shader Suite",
    description:
      "A cohesive open-source ReShade shader suite for PC gaming. Depth, clarity, colour, and atmosphere bound together.",
    url: "https://yggdrasil.fx",
    siteName: "Yggdrasil.fx",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Yggdrasil.fx — ReShade Shader Suite",
    description:
      "A cohesive open-source ReShade shader suite for PC gaming.",
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable}`}
    >
      <body className="font-sans bg-ygg-bg text-ygg-text leading-relaxed overflow-x-hidden">
        {/* Fixed overlays */}
        <div className="noise-overlay" />
        <div className="grid-bg" />
        <CustomCursor />
        <ScrollProgress />

        {children}
      </body>
    </html>
  );
}
