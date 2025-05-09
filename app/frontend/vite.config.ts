import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import postcssNesting from 'postcss-nesting';

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [react()],
    build: {
        outDir: "../backend/static",
        emptyOutDir: true,
        sourcemap: true,
        rollupOptions: {
            plugins: []
        }
    },
    server: {
        proxy: {
            "/ask": "http://localhost:8000",
            "/sessions": "http://localhost:8000",
            "/chat": "http://localhost:8000",
            "/getFeatureFlags": "http://localhost:8000",
            "/getalltags": "http://localhost:8000",
            "/getblobclienturl": "http://localhost:8000",
            "/getalluploadstatus": "http://localhost:8000",
            "/deleteItems": "http://localhost:8000",
            "/resubmitItems": "http://localhost:8000",
            "/getfolders": "http://localhost:8000",
            "/gettags": "http://localhost:8000",
            "/getHint": "http://localhost:8000",
            "/stream": "http://localhost:8000",
            "/posttd": "http://localhost:8000",
            "/getSolve": "http://localhost:8000",
            "/refresh": "http://localhost:8000",
            "/getTempImages": "http://localhost:8000",
            "/process_td_agent_response": "http://localhost:8000",
            "/logstatus": "http://localhost:8000",
            "/getInfoData": "http://localhost:8000",
            "/getWarningBanner": "http://localhost:8000",
            "/getMaxCSVFileSize": "http://localhost:8000",
            "/getcitation": "http://localhost:8000",
            "/getApplicationTitle": "http://localhost:8000",
            "/process_agent_response": "http://localhost:8000",
            "/getTdAnalysis": "http://localhost:8000",
            "/file": "http://localhost:8000",
            "/get-file": "http://localhost:8000",
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
