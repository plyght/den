import { useState, useEffect, useRef, useCallback } from "react";
import type { Note } from "../lib/api.js";

type Action =
  | { kind: "note"; note: Note }
  | {
      kind: "action";
      id: string;
      label: string;
      description: string;
      icon: string;
    };

interface CommandPaletteProps {
  notes: Note[];
  activeNote: Note | null;
  onClose: () => void;
  onSelectNote: (id: string) => void;
  onNewNote: () => void;
  onDeleteNote: (id: string) => void;
  onTogglePin: (id: string) => void;
}

export function CommandPalette({
  notes,
  activeNote,
  onClose,
  onSelectNote,
  onNewNote,
  onDeleteNote,
  onTogglePin,
}: CommandPaletteProps) {
  const [query, setQuery] = useState("");
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const staticActions: Action[] = [
    {
      kind: "action",
      id: "new",
      label: "New Note",
      description: "Create a new note",
      icon: "✦",
    },
    ...(activeNote
      ? [
          {
            kind: "action" as const,
            id: "delete",
            label: "Delete Note",
            description: `Delete "${activeNote.title || "Untitled"}"`,
            icon: "⌫",
          },
          {
            kind: "action" as const,
            id: "pin",
            label: activeNote.pinned ? "Unpin Note" : "Pin Note",
            description: activeNote.pinned
              ? "Remove from pinned"
              : "Pin to top",
            icon: "📌",
          },
        ]
      : []),
  ];

  const filteredItems: Action[] = query.trim()
    ? [
        ...staticActions.filter(
          (a) =>
            a.kind === "action" &&
            (a.label.toLowerCase().includes(query.toLowerCase()) ||
              a.description.toLowerCase().includes(query.toLowerCase())),
        ),
        ...notes
          .filter(
            (n) =>
              n.title.toLowerCase().includes(query.toLowerCase()) ||
              n.content.toLowerCase().includes(query.toLowerCase()),
          )
          .slice(0, 8)
          .map((n): Action => ({ kind: "note", note: n })),
      ]
    : [
        ...staticActions,
        ...notes.slice(0, 8).map((n): Action => ({ kind: "note", note: n })),
      ];

  const clampedIndex = Math.min(selectedIndex, filteredItems.length - 1);

  const handleSelect = useCallback(
    (item: Action) => {
      if (item.kind === "note") {
        onSelectNote(item.note.id);
        onClose();
      } else {
        if (item.id === "new") {
          onNewNote();
          onClose();
        } else if (item.id === "delete" && activeNote) {
          if (confirm(`Delete "${activeNote.title || "Untitled"}"?`)) {
            onDeleteNote(activeNote.id);
          }
          onClose();
        } else if (item.id === "pin" && activeNote) {
          onTogglePin(activeNote.id);
          onClose();
        }
      }
    },
    [activeNote, onClose, onDeleteNote, onNewNote, onSelectNote, onTogglePin],
  );

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Escape") {
        onClose();
      } else if (e.key === "ArrowDown") {
        e.preventDefault();
        setSelectedIndex((i) => Math.min(i + 1, filteredItems.length - 1));
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        setSelectedIndex((i) => Math.max(i - 1, 0));
      } else if (e.key === "Enter") {
        e.preventDefault();
        const item = filteredItems[clampedIndex];
        if (item) handleSelect(item);
      }
    },
    [clampedIndex, filteredItems, handleSelect, onClose],
  );

  useEffect(() => {
    setSelectedIndex(0);
  }, [query]);

  return (
    <div className="palette-overlay" onClick={onClose}>
      <div className="palette" onClick={(e) => e.stopPropagation()}>
        <div className="palette__input-row">
          <svg className="palette__search-icon" viewBox="0 0 16 16" fill="none">
            <circle
              cx="6.5"
              cy="6.5"
              r="4.5"
              stroke="currentColor"
              strokeWidth="1.5"
            />
            <path
              d="M10 10l3 3"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
            />
          </svg>
          <input
            ref={inputRef}
            className="palette__input"
            placeholder="Search notes or actions..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            spellCheck={false}
          />
          <kbd className="palette__esc">esc</kbd>
        </div>
        <div className="palette__results">
          {filteredItems.length === 0 && (
            <div className="palette__empty">No results</div>
          )}
          {filteredItems.map((item, i) =>
            item.kind === "action" ? (
              <button
                key={item.id}
                className={`palette__item palette__item--action ${i === clampedIndex ? "palette__item--selected" : ""}`}
                onClick={() => handleSelect(item)}
                onMouseEnter={() => setSelectedIndex(i)}
              >
                <span className="palette__item-icon">{item.icon}</span>
                <span className="palette__item-label">{item.label}</span>
                <span className="palette__item-desc">{item.description}</span>
              </button>
            ) : (
              <button
                key={item.note.id}
                className={`palette__item ${i === clampedIndex ? "palette__item--selected" : ""}`}
                onClick={() => handleSelect(item)}
                onMouseEnter={() => setSelectedIndex(i)}
              >
                <span className="palette__item-icon">◈</span>
                <span className="palette__item-label">
                  {item.note.title || "Untitled"}
                </span>
                {item.note.pinned && (
                  <span className="palette__item-pin">📌</span>
                )}
              </button>
            ),
          )}
        </div>
        <div className="palette__footer">
          <span>↑↓ navigate</span>
          <span>↵ select</span>
          <span>esc close</span>
        </div>
      </div>
    </div>
  );
}
