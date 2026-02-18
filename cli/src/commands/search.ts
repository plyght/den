import type { Config } from "../config.ts";
import { listNotes } from "../api.ts";
import { timeAgo, truncate, terminalWidth, bold, gray } from "../utils.ts";

export async function search(config: Config, query: string): Promise<void> {
  const result = await listNotes(config, { search: query, limit: 50 });
  if (!result) return;

  if (result.notes.length === 0) {
    console.log(`No notes found for "${query}".`);
    return;
  }

  const width = terminalWidth();
  console.log(
    `${gray(`Found ${result.notes.length} note(s) for "${query}":\n`)}`,
  );

  for (const note of result.notes) {
    const idPart = note.id.slice(0, 4);
    const pin = note.pinned ? "📌 " : "   ";
    const title = note.title ?? note.content.split("\n")[0] ?? "(no content)";
    const time = timeAgo(note.updatedAt);
    const timeWidth = time.length + 2;
    const titleWidth = Math.max(10, width - 3 - 6 - timeWidth - 4);
    const titleTrunc = truncate(title, titleWidth).padEnd(titleWidth);
    console.log(`${pin}${bold(idPart)}  ${titleTrunc}  ${gray(time)}`);
  }
}
