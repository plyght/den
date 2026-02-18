import { join } from "node:path";
import { homedir } from "node:os";
import { mkdir } from "node:fs/promises";

export interface Config {
  server: string;
  token: string;
}

const CONFIG_DIR = join(homedir(), ".den");
const CONFIG_PATH = join(CONFIG_DIR, "config.json");

const DEFAULT_CONFIG: Config = {
  server: "http://localhost:7745",
  token: "",
};

export async function loadConfig(): Promise<Config> {
  try {
    const file = Bun.file(CONFIG_PATH);
    if (!(await file.exists())) {
      await ensureConfig();
      return { ...DEFAULT_CONFIG };
    }
    const raw = await file.text();
    const parsed = JSON.parse(raw) as Partial<Config>;
    return { ...DEFAULT_CONFIG, ...parsed };
  } catch {
    return { ...DEFAULT_CONFIG };
  }
}

export async function saveConfig(config: Config): Promise<void> {
  await ensureConfig();
  await Bun.write(CONFIG_PATH, JSON.stringify(config, null, 2) + "\n");
}

async function ensureConfig(): Promise<void> {
  await mkdir(CONFIG_DIR, { recursive: true });
  const file = Bun.file(CONFIG_PATH);
  if (!(await file.exists())) {
    await Bun.write(
      CONFIG_PATH,
      JSON.stringify(DEFAULT_CONFIG, null, 2) + "\n",
    );
  }
}

export function checkToken(config: Config): boolean {
  if (!config.token) {
    console.log(
      "No token configured. Run `den config set token <your-token>` to connect to your Den server.",
    );
    return false;
  }
  return true;
}
