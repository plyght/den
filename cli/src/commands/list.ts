import type { Config } from "../config.ts";
import { listNotes, type Note } from "../api.ts";
import { timeAgo, truncate, terminalWidth, c, bold, gray } from "../utils.ts";

function formatNote(note: Note, width: number): string {
  const idPart = note.id.slice(0, 4);
  const pin = note.pinned ? "📌 " : "   ";
  const title = note.title ?? note.content.split("\n")[0] ?? "(no content)";
  const time = timeAgo(note.updatedAt);

  const timeWidth = time.length + 2;
  const idWidth = 4 + 2;
  const pinWidth = note.pinned ? 3 : 3;
  const titleWidth = Math.max(10, width - pinWidth - idWidth - timeWidth - 4);

  const titleTrunc = truncate(title, titleWidth);
  const titlePadded = titleTrunc.padEnd(titleWidth);

  return `${pin}${bold(idPart)}  ${titlePadded}  ${gray(time)}`;
}

export async function list(
  config: Config,
  opts: { all?: boolean; pinned?: boolean },
): Promise<void> {
  const limit = opts.all ? 1000 : 20;
  const result = await listNotes(config, {
    limit,
    pinned: opts.pinned ? true : undefined,
  });

  if (!result) return;

  if (result.notes.length === 0) {
    console.log(opts.pinned ? "No pinned notes." : "No notes yet.");
    return;
  }

  const width = terminalWidth();
  for (const note of result.notes) {
    console.log(formatNote(note, width));
  }

  if (!opts.all && result.total > result.notes.length) {
    console.log(
      `\n${gray(`Showing ${result.notes.length} of ${result.total}. Use --all to see all.`)}`,
    );
  }
}
