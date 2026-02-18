import type { Config } from "../config.ts";
import { resolveIdPrefix, deleteNote } from "../api.ts";
import { printSuccess } from "../utils.ts";
import { readSync } from "node:fs";

export async function remove(config: Config, prefix: string): Promise<void> {
  const note = await resolveIdPrefix(config, prefix);
  if (!note) return;

  const title = note.title ?? note.content.slice(0, 50);
  process.stdout.write(`Delete "${title}"? [y/N] `);

  const buf = Buffer.alloc(8);
  let answer = "";
  try {
    const n = readSync(0, buf, 0, 8, null);
    answer = buf.slice(0, n).toString().trim().toLowerCase();
  } catch {
    answer = "";
  }

  if (answer !== "y" && answer !== "yes") {
    console.log("Cancelled.");
    return;
  }

  const ok = await deleteNote(config, note.id);
  if (ok) {
    printSuccess(`Deleted: ${title}`);
  }
}
