import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  // The repo ships two lockfiles (package-lock.json and pnpm-lock.yaml) plus a
  // pnpm-workspace.yaml, so Turbopack can infer the PARENT directory as the
  // workspace root and then fail to resolve `tailwindcss` for PostCSS, since
  // node_modules only exists here. Pin the root to the package itself.
  turbopack: {
    root: import.meta.dirname,
  },
  async headers() {
    return [
      {
        source: "/:path*",
        headers: [
          { key: "Cache-Control", value: "no-store, no-cache, must-revalidate, proxy-revalidate" },
          { key: "Pragma", value: "no-cache" },
          { key: "Expires", value: "0" },
        ],
      },
    ];
  },
};

export default nextConfig;
