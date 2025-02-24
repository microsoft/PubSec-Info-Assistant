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
        sourcemap: true,
        rollupOptions: {
            output: {
                manualChunks(id) {
                    if (id.includes('node_modules/@fluentui/react-icons')) {
                        return 'fluentui-react-icons';
                    }
                    else if (id.includes('node_modules/@fluentui/react/')) {
                        return 'fluentui-react';
                    }
                    else if (id.includes('node_modules/@fluentui')) {
                        return 'fluentui';
                    }
                    if (id.includes('node_modules/react')
                        || id.includes('node_modules/@griffel')
                        || id.includes('node_modules/@react')
                        || id.includes('node_modules/@restart')) {
                        return 'react';
                    }
                    else if (id.includes('node_modules/')) {
                        // Throw all other modules into an everything-else chunk.
                        return 'everything-else';
                    }
                }
            }
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
