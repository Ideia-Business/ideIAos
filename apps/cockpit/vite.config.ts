// SOURCE: IdeiaOS v14 | kind: config | targets: apps/cockpit
// Dev server: loopback 127.0.0.1, porta fixa 5273, sem login.
// strictPort: true garante que o Vite FALHA em vez de cair em porta aleatória
// se 5273 estiver ocupada — o gate sempre sabe a porta e nunca colide com
// dev servers de produtos-irmãos na mesma máquina.
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  server: {
    host: "127.0.0.1",
    port: 5273,
    strictPort: true,
  },
});
