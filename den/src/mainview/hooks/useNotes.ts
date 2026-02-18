import { useState, useCallback, useRef, useEffect } from "react";
import * as api from "../lib/api.js";
import type { Note } from "../lib/api.js";
import type { WsEvent } from "./useWebSocket.js";

const LAST_NOTE_KEY = "den:lastNote";
const LAST_NOTE_TIME_KEY = "den:lastNoteTime";
const CACHE_KEY = "den:notesCache";

function loadCachedNotes(): Note[] {
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    if (raw) return JSON.parse(raw) as Note[];
  } catch (_) {
    return [];
  }
  return [];
}

function saveCachedNotes(notes: Note[]) {
  try {
    localStorage.setItem(CACHE_KEY, JSON.stringify(notes));
  } catch (_) {
    return;
  }
}

export function useNotes() {
  const [notes, setNotes] = useState<Note[]>(loadCachedNotes);
  const [activeNoteId, setActiveNoteIdRaw] = useState<string | null>(() => {
    const id = localStorage.getItem(LAST_NOTE_KEY);
    const ts = localStorage.getItem(LAST_NOTE_TIME_KEY);
    if (id && ts && Date.now() - Number(ts) < 5 * 60 * 1000) return id;
    return null;
  });
  const [serverOnline, setServerOnline] = useState(true);
  const saveQueueRef = useRef<Map<string, Partial<api.Note>>>(new Map());
  const saveTimersRef = useRef<Map<string, ReturnType<typeof setTimeout>>>(
    new Map(),
  );

  const setActiveNoteId = useCallback((id: string | null) => {
    setActiveNoteIdRaw(id);
    if (id) {
      localStorage.setItem(LAST_NOTE_KEY, id);
      localStorage.setItem(LAST_NOTE_TIME_KEY, String(Date.now()));
    } else {
      localStorage.removeItem(LAST_NOTE_KEY);
      localStorage.removeItem(LAST_NOTE_TIME_KEY);
    }
  }, []);

  const refreshNotes = useCallback(async () => {
    try {
      const res = await api.fetchNotes({ limit: 200 });
      const sorted = res.notes.sort(
        (a, b) =>
          new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime(),
      );
      setNotes(sorted);
      saveCachedNotes(sorted);
      setServerOnline(true);
    } catch (_) {
      setServerOnline(false);
    }
  }, []);

  useEffect(() => {
    void refreshNotes();
  }, [refreshNotes]);

  const activeNote = notes.find((n) => n.id === activeNoteId) ?? null;

  const createNote = useCallback(async () => {
    const optimistic: Note = {
      id: `optimistic-${Date.now()}`,
      title: "Untitled",
      content: "",
      pinned: false,
      tags: [],
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    setNotes((prev) => [optimistic, ...prev]);
    setActiveNoteId(optimistic.id);
    try {
      const created = await api.createNote({ title: "Untitled", content: "" });
      setNotes((prev) =>
        prev.map((n) => (n.id === optimistic.id ? created : n)),
      );
      setActiveNoteId(created.id);
      return created;
    } catch (_) {
      setServerOnline(false);
      return optimistic;
    }
  }, [setActiveNoteId]);

  const flushSave = useCallback(async (id: string) => {
    const data = saveQueueRef.current.get(id);
    if (!data) return;
    saveQueueRef.current.delete(id);
    try {
      const updated = await api.updateNote(id, data);
      setNotes((prev) =>
        prev
          .map((n) => (n.id === id ? updated : n))
          .sort(
            (a, b) =>
              new Date(b.updated_at).getTime() -
              new Date(a.updated_at).getTime(),
          ),
      );
      setServerOnline(true);
    } catch (_) {
      setServerOnline(false);
    }
  }, []);

  const saveNote = useCallback(
    (
      id: string,
      data: Partial<Pick<Note, "title" | "content" | "pinned" | "tags">>,
    ) => {
      setNotes((prev) =>
        prev.map((n) =>
          n.id === id
            ? { ...n, ...data, updated_at: new Date().toISOString() }
            : n,
        ),
      );

      const existing = saveQueueRef.current.get(id) ?? {};
      saveQueueRef.current.set(id, { ...existing, ...data });

      const existing_timer = saveTimersRef.current.get(id);
      if (existing_timer) clearTimeout(existing_timer);
      saveTimersRef.current.set(
        id,
        setTimeout(() => void flushSave(id), 500),
      );
    },
    [flushSave],
  );

  const deleteNote = useCallback(
    async (id: string) => {
      setNotes((prev) => prev.filter((n) => n.id !== id));
      if (activeNoteId === id) setActiveNoteId(null);
      try {
        await api.deleteNote(id);
      } catch (_) {
        setServerOnline(false);
      }
    },
    [activeNoteId, setActiveNoteId],
  );

  const togglePin = useCallback(
    (id: string) => {
      const note = notes.find((n) => n.id === id);
      if (!note) return;
      saveNote(id, { pinned: !note.pinned });
    },
    [notes, saveNote],
  );

  const handleWsEvent = useCallback(
    (event: WsEvent) => {
      if (event.type === "note:created") {
        setNotes((prev) => {
          if (prev.find((n) => n.id === event.note.id)) return prev;
          return [event.note, ...prev];
        });
      } else if (event.type === "note:updated") {
        setNotes((prev) =>
          prev.map((n) => (n.id === event.note.id ? event.note : n)),
        );
      } else if (event.type === "note:deleted") {
        setNotes((prev) => prev.filter((n) => n.id !== event.note.id));
        if (activeNoteId === event.note.id) setActiveNoteId(null);
      }
    },
    [activeNoteId, setActiveNoteId],
  );

  const pinnedNotes = notes.filter((n) => n.pinned);
  const recentNotes = notes.filter((n) => !n.pinned);

  return {
    notes,
    pinnedNotes,
    recentNotes,
    activeNote,
    activeNoteId,
    serverOnline,
    setActiveNoteId,
    createNote,
    saveNote,
    deleteNote,
    togglePin,
    handleWsEvent,
    refreshNotes,
  };
}
