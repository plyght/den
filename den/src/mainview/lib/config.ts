export interface DenConfig {
  serverUrl: string;
  authToken: string;
}

const STORAGE_KEY = "den:config";

const defaults: DenConfig = {
  serverUrl: "http://localhost:7745",
  authToken: "",
};

export function getConfig(): DenConfig {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      return { ...defaults, ...JSON.parse(stored) };
    }
  } catch (_) {
    return { ...defaults };
  }
  return { ...defaults };
}

export function saveConfig(config: Partial<DenConfig>): void {
  const current = getConfig();
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ ...current, ...config }));
}
