import type { Note } from "../lib/api.js";

function relativeTime(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const s = Math.floor(diff / 1000);
  if (s < 60) return "just now";
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d === 1) return "yesterday";
  if (d < 7) return `${d}d ago`;
  return new Date(dateStr).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
}

function contentPreview(content: string): string {
  if (!content) return "";
  try {
    const blocks = JSON.parse(content) as Array<{
      content?: Array<{ text?: string }>;
    }>;
    const lines: string[] = [];
    for (const block of blocks) {
      if (block.content) {
        const text = block.content.map((c) => c.text ?? "").join("");
        if (text.trim()) lines.push(text.trim());
      }
      if (lines.length >= 1) break;
    }
    return lines[0] ?? "";
  } catch (_) {
    return content.split("\n").find((l) => l.trim()) ?? "";
  }
}

interface NoteItemProps {
  note: Note;
  active: boolean;
  onSelect: (id: string) => void;
}

export function NoteItem({ note, active, onSelect }: NoteItemProps) {
  const preview = contentPreview(note.content);

  return (
    <button
      className={`note-item ${active ? "note-item--active" : ""}`}
      onClick={() => onSelect(note.id)}
    >
      <div className="note-item__header">
        <span className="note-item__title">{note.title || "Untitled"}</span>
        <span className="note-item__time">{relativeTime(note.updated_at)}</span>
      </div>
      {preview && <span className="note-item__preview">{preview}</span>}
    </button>
  );
}
