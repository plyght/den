import type { Config } from "../config.ts";
import { resolveIdPrefix, updateNote } from "../api.ts";
import { printError, printSuccess } from "../utils.ts";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { unlink } from "node:fs/promises";

export async function edit(config: Config, prefix: string): Promise<void> {
  const note = await resolveIdPrefix(config, prefix);
  if (!note) return;

  const editor = process.env["EDITOR"] ?? "vim";
  const tmpFile = join(tmpdir(), `den-note-${note.id.slice(0, 8)}.md`);

  await Bun.write(tmpFile, note.content);

  const proc = Bun.spawn([editor, tmpFile], {
    stdin: "inherit",
    stdout: "inherit",
    stderr: "inherit",
  });

  await proc.exited;

  const newContent = await Bun.file(tmpFile).text();

  try {
    await unlink(tmpFile);
  } catch {}

  if (newContent === note.content) {
    console.log("No changes made.");
    return;
  }

  const updated = await updateNote(config, note.id, { content: newContent });
  if (!updated) return;

  printSuccess("Note updated.");
}
