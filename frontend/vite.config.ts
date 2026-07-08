import path from 'node:path'
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import VueI18nPlugin from '@intlify/unplugin-vue-i18n/vite'
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
  plugins: [
    VueI18nPlugin({
      include: [path.resolve(__dirname, './src/i18n/locales/**')],
    }),
    vue(),
    tailwindcss(),
  ],
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
