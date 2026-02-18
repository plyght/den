import { loadConfig, saveConfig, type Config } from "../config.ts";
import { bold, cyan, gray } from "../utils.ts";
import { join } from "node:path";
import { homedir } from "node:os";

export async function configCommand(args: string[]): Promise<void> {
  const config = await loadConfig();

  if (args.length === 0) {
    showConfig(config);
    return;
  }

  if (args[0] === "set") {
    const key = args[1];
    const value = args[2];

    if (!key || !value) {
      console.log("Usage: den config set <key> <value>");
      console.log("  Keys: server, token");
      return;
    }

    if (key === "server") {
      config.server = value;
      await saveConfig(config);
      console.log(`${bold("server")} set to ${cyan(value)}`);
    } else if (key === "token") {
      config.token = value;
      await saveConfig(config);
      console.log(`${bold("token")} set.`);
    } else {
      console.log(`Unknown config key: ${key}`);
      console.log("Valid keys: server, token");
    }
    return;
  }

  console.log(`Unknown config subcommand: ${args[0]}`);
  console.log("Usage: den config [set <key> <value>]");
}

function showConfig(config: Config): void {
  const configPath = join(homedir(), ".den", "config.json");
  console.log(`${gray("Config file:")} ${configPath}\n`);
  console.log(`  ${bold("server")}  ${cyan(config.server)}`);
  console.log(
    `  ${bold("token")}   ${config.token ? gray("[set]") : gray("[not set]")}`,
  );
  if (!config.token) {
    console.log(
      `\nRun ${cyan("`den config set token <your-token>`")} to connect to your Den server.`,
    );
  }
}
