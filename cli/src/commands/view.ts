import type { Config } from "../config.ts";
import { resolveIdPrefix } from "../api.ts";
import { renderMarkdown, bold, gray, cyan, timeAgo, c } from "../utils.ts";

export async function view(config: Config, prefix: string): Promise<void> {
  const note = await resolveIdPrefix(config, prefix);
  if (!note) return;

  const sep = "─".repeat(Math.min(60, process.stdout.columns ?? 60));

  console.log(`\n${gray(sep)}`);
  if (note.title) {
    console.log(`${bold(cyan(note.title))}`);
  }
  console.log(
    `${gray(`ID: ${note.id}  |  ${note.pinned ? "📌 pinned  |  " : ""}Updated: ${timeAgo(note.updatedAt)}`)}`,
  );
  if (note.tags && note.tags.length > 0) {
    console.log(`${gray(`Tags: ${note.tags.join(", ")}`)}`);
  }
  console.log(`${gray(sep)}\n`);
  console.log(renderMarkdown(note.content));
  console.log(`\n${gray(sep)}\n`);
}
