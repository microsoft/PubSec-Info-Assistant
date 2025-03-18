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
            "/sessions": "http://localhost:5000",
            "/chat": "http://localhost:5000",
            "/getFeatureFlags": "http://localhost:5000",
            "/getalltags": "http://localhost:5000",
            "/getblobclienturl": "http://localhost:5000",
            "/getalluploadstatus": "http://localhost:5000",
            "/deleteItems": "http://localhost:5000",
            "/resubmitItems": "http://localhost:5000",
            "/getfolders": "http://localhost:5000",
            "/gettags": "http://localhost:5000",
            "/getHint": "http://localhost:5000",
            "/stream": "http://localhost:5000",
            "/posttd": "http://localhost:5000",
            "/getSolve": "http://localhost:5000",
            "/refresh": "http://localhost:5000",
            "/getTempImages": "http://localhost:5000",
            "/process_td_agent_response": "http://localhost:5000",
            "/logstatus": "http://localhost:5000",
            "/getInfoData": "http://localhost:5000",
            "/getWarningBanner": "http://localhost:5000",
            "/getMaxCSVFileSize": "http://localhost:5000",
            "/getcitation": "http://localhost:5000",
            "/getApplicationTitle": "http://localhost:5000",
            "/process_agent_response": "http://localhost:5000",
            "/getTdAnalysis": "http://localhost:5000",
            "/file":"http://localhost:5000",
            "/get-file":"http://localhost:5000",
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
