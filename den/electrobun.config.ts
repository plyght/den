import type { ElectrobunConfig } from "electrobun";

export default {
  app: {
    name: "Den",
    identifier: "den.app",
    version: "1.0.0",
  },
  build: {
    views: {
      mainview: {
        entrypoint: "src/mainview/index.tsx",
      },
    },
    copy: {
      "src/mainview/index.html": "views/mainview/index.html",
    },
    mac: {
      bundleCEF: false,
    },
    linux: {
      bundleCEF: false,
    },
    win: {
      bundleCEF: false,
    },
  },
} satisfies ElectrobunConfig;
