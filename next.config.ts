import path from "node:path";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Pin the workspace root explicitly: this project's git repo root is the
  // user's home directory (an unrelated pre-existing condition, not created
  // by this project — see /docs/product/product-definition.md §14), which
  // otherwise makes Next.js's root inference ambiguous.
  turbopack: {
    root: path.join(__dirname),
  },
  agentRules: false,
};

export default nextConfig;
