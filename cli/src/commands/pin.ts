import type { Config } from "../config.ts";
import { resolveIdPrefix, updateNote } from "../api.ts";
import { printSuccess } from "../utils.ts";

export async function pin(config: Config, prefix: string): Promise<void> {
  const note = await resolveIdPrefix(config, prefix);
  if (!note) return;

  const newPinned = !note.pinned;
  const updated = await updateNote(config, note.id, { pinned: newPinned });
  if (!updated) return;

  const title = note.title ?? note.content.slice(0, 40);
  printSuccess(newPinned ? `Pinned: ${title}` : `Unpinned: ${title}`);
}
