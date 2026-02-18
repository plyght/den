import { useRef } from "react";
import type { Note } from "../lib/api.js";
import { NoteItem } from "./NoteItem.js";
import { SearchInput } from "./SearchInput.js";

interface SidebarProps {
  pinnedNotes: Note[];
  recentNotes: Note[];
  activeNoteId: string | null;
  searchQuery: string;
  filteredNotes: Note[];
  serverOnline: boolean;
  onSelectNote: (id: string) => void;
  onNewNote: () => void;
  onSearchChange: (q: string) => void;
}

export function Sidebar({
  pinnedNotes,
  recentNotes,
  activeNoteId,
  searchQuery,
  filteredNotes,
  serverOnline,
  onSelectNote,
  onNewNote,
  onSearchChange,
}: SidebarProps) {
  const searchRef = useRef<HTMLInputElement>(null);

  const showFiltered = searchQuery.trim().length > 0;

  return (
    <aside className="sidebar">
      <div className="sidebar__header electrobun-webkit-app-region-drag">
        <div className="sidebar__brand">
          <span className="sidebar__brand-icon">◈</span>
          <span className="sidebar__brand-name">Den</span>
          <span
            className={`sidebar__status-dot ${serverOnline ? "sidebar__status-dot--online" : "sidebar__status-dot--offline"}`}
            title={serverOnline ? "Server connected" : "Server unreachable"}
          />
        </div>
      </div>

      <div className="sidebar__search">
        <SearchInput
          value={searchQuery}
          onChange={onSearchChange}
          inputRef={searchRef}
        />
      </div>

      <div className="sidebar__notes">
        {showFiltered ? (
          <>
            <div className="sidebar__section-label">Results</div>
            {filteredNotes.length === 0 ? (
              <div className="sidebar__empty">No notes found</div>
            ) : (
              filteredNotes.map((note) => (
                <NoteItem
                  key={note.id}
                  note={note}
                  active={note.id === activeNoteId}
                  onSelect={onSelectNote}
                />
              ))
            )}
          </>
        ) : (
          <>
            {pinnedNotes.length > 0 && (
              <>
                <div className="sidebar__section-label">
                  <span className="sidebar__pin-icon">📌</span> Pinned
                </div>
                {pinnedNotes.map((note) => (
                  <NoteItem
                    key={note.id}
                    note={note}
                    active={note.id === activeNoteId}
                    onSelect={onSelectNote}
                  />
                ))}
              </>
            )}

            {recentNotes.length > 0 && (
              <>
                <div className="sidebar__section-label">Recent</div>
                {recentNotes.map((note) => (
                  <NoteItem
                    key={note.id}
                    note={note}
                    active={note.id === activeNoteId}
                    onSelect={onSelectNote}
                  />
                ))}
              </>
            )}

            {pinnedNotes.length === 0 && recentNotes.length === 0 && (
              <div className="sidebar__empty">
                <span>No notes yet</span>
                <span className="sidebar__empty-hint">
                  Press ⌘N to create one
                </span>
              </div>
            )}
          </>
        )}
      </div>

      <div className="sidebar__footer">
        <button className="sidebar__new-btn" onClick={onNewNote}>
          <svg viewBox="0 0 16 16" fill="none">
            <path
              d="M8 3v10M3 8h10"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
            />
          </svg>
          New Note
          <kbd>⌘N</kbd>
        </button>
      </div>
    </aside>
  );
}
