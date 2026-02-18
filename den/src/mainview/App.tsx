import { useState, useEffect, useCallback } from "react";
import { Sidebar } from "./components/Sidebar.js";
import { Editor } from "./components/Editor.js";
import { CommandPalette } from "./components/CommandPalette.js";
import { useNotes } from "./hooks/useNotes.js";
import { useSearch } from "./hooks/useSearch.js";
import { useWebSocket } from "./hooks/useWebSocket.js";

import "./styles/globals.css";

export function App() {
  const {
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
  } = useNotes();

  const [searchQuery, setSearchQuery] = useState("");
  const [paletteOpen, setPaletteOpen] = useState(false);

  const filteredNotes = useSearch(notes, searchQuery);

  useWebSocket(handleWsEvent, true);

  const handleNewNote = useCallback(async () => {
    await createNote();
  }, [createNote]);

  const handleDeleteNote = useCallback(
    async (id: string) => {
      await deleteNote(id);
    },
    [deleteNote],
  );

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const meta = e.metaKey || e.ctrlKey;
      if (meta && e.key === "k") {
        e.preventDefault();
        setPaletteOpen((o) => !o);
      } else if (meta && e.key === "n") {
        e.preventDefault();
        void handleNewNote();
      } else if (meta && e.key === "Backspace" && activeNoteId) {
        e.preventDefault();
        if (confirm("Delete this note?")) {
          void handleDeleteNote(activeNoteId);
        }
      } else if (meta && e.shiftKey && e.key === "p" && activeNoteId) {
        e.preventDefault();
        togglePin(activeNoteId);
      } else if (meta && e.key === "f") {
        e.preventDefault();
        const el = document.querySelector<HTMLInputElement>(".search-input");
        el?.focus();
      } else if (e.key === "Escape" && paletteOpen) {
        setPaletteOpen(false);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [activeNoteId, handleDeleteNote, handleNewNote, paletteOpen, togglePin]);

  return (
    <div className="app">
      <Sidebar
        pinnedNotes={pinnedNotes}
        recentNotes={recentNotes}
        activeNoteId={activeNoteId}
        searchQuery={searchQuery}
        filteredNotes={filteredNotes}
        serverOnline={serverOnline}
        onSelectNote={setActiveNoteId}
        onNewNote={() => void handleNewNote()}
        onSearchChange={setSearchQuery}
      />
      <main className="main">
        <Editor note={activeNote} onSave={saveNote} />
      </main>
      {paletteOpen && (
        <CommandPalette
          notes={notes}
          activeNote={activeNote}
          onClose={() => setPaletteOpen(false)}
          onSelectNote={setActiveNoteId}
          onNewNote={() => void handleNewNote()}
          onDeleteNote={(id) => void handleDeleteNote(id)}
          onTogglePin={togglePin}
        />
      )}
    </div>
  );
}
