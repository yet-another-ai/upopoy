import path from 'node:path'
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import vue from '@vitejs/plugin-vue'

const railsProxyTarget =
  process.env.VITE_RAILS_PROXY_TARGET ??
  process.env.VITE_API_PROXY_TARGET ??
  'http://localhost:3001'

const railsProxy = {
  target: railsProxyTarget,
  changeOrigin: true,
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': railsProxy,
      '/pghero': railsProxy,
      '/rails-assets': railsProxy,
    },
  },
})
