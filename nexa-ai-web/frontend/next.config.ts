import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',
  basePath: '/nexa-ai',
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
