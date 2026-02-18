import { useMemo } from "react";
import type { Note } from "../lib/api.js";

export function useSearch(notes: Note[], query: string): Note[] {
  return useMemo(() => {
    if (!query.trim()) return notes;
    const q = query.toLowerCase();
    return notes.filter(
      (n) =>
        n.title.toLowerCase().includes(q) ||
        n.content.toLowerCase().includes(q),
    );
  }, [notes, query]);
}
