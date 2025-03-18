import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import postcssNesting from 'postcss-nesting';
//import { nodePolyfills } from 'vite-plugin-node-polyfills'
//import rollupNodePolyFill from 'rollup-plugin-node-polyfills' --deprecated??


// https://vitejs.dev/config/
export default defineConfig({
    plugins: [react()],
    build: {
        outDir: "../backend/static",
        emptyOutDir: true,
        sourcemap: true,
        rollupOptions: {
            plugins: [
                //rollupNodePolyFill(), 
                //nodePolyfills()
            ]
        }
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
    },
    resolve: {
        alias: {
            buffer: 'rollup-plugin-node-polyfills/polyfills/buffer-es6',
            process: 'rollup-plugin-node-polyfills/polyfills/process-es6'
        }
    }
});
