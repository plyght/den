import { createRoot } from "react-dom/client";
import { Electroview } from "electrobun/view";
import type { RPCSchema } from "electrobun/bun";
import { App } from "./App.js";

type DenRPC = {
  bun: RPCSchema<{
    requests: Record<string, never>;
    messages: Record<string, never>;
  }>;
  webview: RPCSchema<{
    requests: Record<string, never>;
    messages: Record<string, never>;
  }>;
};

const rpc = Electroview.defineRPC<DenRPC>({
  handlers: { requests: {}, messages: {} },
});
new Electroview({ rpc });

const root = document.getElementById("root");
if (root) {
  createRoot(root).render(<App />);
}
