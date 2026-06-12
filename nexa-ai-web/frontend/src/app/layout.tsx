import type { Metadata } from "next";
import "./globals.css";
import Providers from "../components/Providers";

export const metadata: Metadata = {
  title: "Nexa AI | Private Edge-First Local AI Assistant & SaaS",
  description: "Execute Large Language Models (LLMs) locally on your hardware. Complete client-side privacy with RAG, speech-to-text, device optimizer and custom plugin sandboxes.",
  keywords: ["local AI", "offline LLM", "privacy AI assistant", "Nexa AI", "edge computing", "RAG model comparison"],
  authors: [{ name: "Nexa AI Core Team" }],
  openGraph: {
    title: "Nexa AI | Private Client-Side AI Assistant",
    description: "Run 3B and 7B GGUF/TFLite models locally. Real-time token generation speed analytics and secure offline database backups.",
    type: "website",
    url: "https://nexa.ai"
  }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark scroll-smooth h-full">
      <body className="h-full bg-background text-foreground antialiased selection:bg-primary/30 select-none">
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
