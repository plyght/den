import type { Config } from "../config.ts";
import { createNote } from "../api.ts";
import { green, printError } from "../utils.ts";

export async function capture(config: Config, text: string): Promise<void> {
  const content = text.replace(/\\n/g, "\n");

  const lines = content.split("\n");
  let title: string | undefined;
  let noteContent = content;

  if (lines[0]?.startsWith("# ")) {
    title = lines[0].slice(2).trim();
    noteContent = lines.slice(1).join("\n").trim();
    if (!noteContent) noteContent = content;
  }

  const note = await createNote(config, { title, content: noteContent });
  if (!note) return;

  const display = note.title ?? note.content.slice(0, 50);
  console.log(`${green("✓")} Note saved: ${display}`);
  console.log(`  ID: ${note.id.slice(0, 8)}`);
}
