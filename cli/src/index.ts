#!/usr/bin/env bun
import { loadConfig, checkToken } from "./config.ts";
import { capture } from "./commands/capture.ts";
import { list } from "./commands/list.ts";
import { search } from "./commands/search.ts";
import { view } from "./commands/view.ts";
import { edit } from "./commands/edit.ts";
import { pin } from "./commands/pin.ts";
import { remove } from "./commands/remove.ts";
import { configCommand } from "./commands/config.ts";
import { bold, cyan, gray } from "./utils.ts";

function printHelp(): void {
  console.log(`
${bold("den")} — personal notes CLI

${bold("USAGE")}
  den <text>              Quick capture a note
  den ls                  List recent notes
  den ls --all            List all notes
  den ls --pinned         List pinned notes
  den search <query>      Search notes  (alias: s)
  den view <id>           View a note   (alias: v)
  den edit <id>           Edit in \$EDITOR (alias: e)
  den pin <id>            Toggle pin
  den rm <id>             Delete note
  den config              Show config
  den config set <k> <v>  Set config value

${bold("CONFIG KEYS")}
  server    Server URL (default: http://localhost:7745)
  token     Auth token

${bold("EXAMPLES")}
  den "quick thought"
  den ls --pinned
  den search "meeting"
  den view a3f2
  den edit b7e1
  den pin c4d9
  den rm e8f3
  den config set token my-secret-token
`);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  if (args.length === 0 || args[0] === "--help" || args[0] === "-h") {
    printHelp();
    return;
  }

  const cmd = args[0];

  if (cmd === "config") {
    await configCommand(args.slice(1));
    return;
  }

  const config = await loadConfig();

  if (cmd === "ls" || cmd === "list") {
    if (!checkToken(config)) return;
    const all = args.includes("--all");
    const pinned = args.includes("--pinned");
    await list(config, { all, pinned });
    return;
  }

  if (cmd === "search" || cmd === "s") {
    if (!checkToken(config)) return;
    const query = args[1];
    if (!query) {
      console.log("Usage: den search <query>");
      return;
    }
    await search(config, query);
    return;
  }

  if (cmd === "view" || cmd === "v") {
    if (!checkToken(config)) return;
    const prefix = args[1];
    if (!prefix) {
      console.log("Usage: den view <id-prefix>");
      return;
    }
    await view(config, prefix);
    return;
  }

  if (cmd === "edit" || cmd === "e") {
    if (!checkToken(config)) return;
    const prefix = args[1];
    if (!prefix) {
      console.log("Usage: den edit <id-prefix>");
      return;
    }
    await edit(config, prefix);
    return;
  }

  if (cmd === "pin") {
    if (!checkToken(config)) return;
    const prefix = args[1];
    if (!prefix) {
      console.log("Usage: den pin <id-prefix>");
      return;
    }
    await pin(config, prefix);
    return;
  }

  if (cmd === "rm" || cmd === "delete") {
    if (!checkToken(config)) return;
    const prefix = args[1];
    if (!prefix) {
      console.log("Usage: den rm <id-prefix>");
      return;
    }
    await remove(config, prefix);
    return;
  }

  if (cmd?.startsWith("-")) {
    console.log(`Unknown flag: ${cmd}`);
    printHelp();
    return;
  }

  if (!checkToken(config)) return;
  await capture(config, args.join(" "));
}

main().catch((err) => {
  console.error("Unexpected error:", err);
  process.exit(1);
});
