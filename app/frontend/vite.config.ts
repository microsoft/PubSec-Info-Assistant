import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import postcssNesting from 'postcss-nesting';
import { nodePolyfills } from 'vite-plugin-node-polyfills'

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [react(), nodePolyfills()],
    build: {
        outDir: "../backend/static",
        emptyOutDir: true,
        sourcemap: true
    },
    server: {
        proxy: {
            "/ask": "http://localhost:5000",
            "/chat": "http://localhost:5000"
        }
    },
    css: {
        postcss: {
            plugins: [
                postcssNesting
            ],
        },
    }
});
