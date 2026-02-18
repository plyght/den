import {
  useCallback,
  useEffect,
  useRef,
  useState,
  useSyncExternalStore,
} from "react";
import { useCreateBlockNote } from "@blocknote/react";
import { BlockNoteView } from "@blocknote/mantine";
import type { Block } from "@blocknote/core";
import type { Note } from "../lib/api.js";

import "@blocknote/core/fonts/inter.css";
import "@blocknote/react/style.css";
import "@blocknote/mantine/style.css";

const darkQuery = window.matchMedia("(prefers-color-scheme: dark)");

function subscribeColorScheme(cb: () => void) {
  darkQuery.addEventListener("change", cb);
  return () => darkQuery.removeEventListener("change", cb);
}

function getColorScheme() {
  return darkQuery.matches ? ("dark" as const) : ("light" as const);
}

function parseContent(content: string): Block[] | undefined {
  if (!content) return undefined;
  try {
    const parsed = JSON.parse(content) as Block[];
    if (Array.isArray(parsed)) return parsed;
  } catch (_) {
    return undefined;
  }
  return undefined;
}

interface EditorInnerProps {
  note: Note;
  onSave: (id: string, data: { title?: string; content?: string }) => void;
}

function EditorInner({ note, onSave }: EditorInnerProps) {
  const theme = useSyncExternalStore(subscribeColorScheme, getColorScheme);
  const [title, setTitle] = useState(note.title);
  const titleRef = useRef<HTMLInputElement>(null);

  const editor = useCreateBlockNote({
    initialContent: parseContent(note.content),
  });

  const saveContent = useCallback(() => {
    const blocks = editor.document;
    const content = JSON.stringify(blocks);
    onSave(note.id, { content });
  }, [editor, note.id, onSave]);

  const handleTitleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const t = e.target.value;
      setTitle(t);
      onSave(note.id, { title: t });
    },
    [note.id, onSave],
  );

  const handleTitleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLInputElement>) => {
      if (e.key === "Enter") {
        editor.focus();
      }
    },
    [editor],
  );

  useEffect(() => {
    setTitle(note.title);
  }, [note.id, note.title]);

  return (
    <div className="editor">
      <div className="editor__title-row">
        <input
          ref={titleRef}
          className="editor__title"
          value={title}
          onChange={handleTitleChange}
          onKeyDown={handleTitleKeyDown}
          placeholder="Untitled"
          spellCheck={false}
        />
      </div>
      <div className="editor__body">
        <BlockNoteView editor={editor} onChange={saveContent} theme={theme} />
      </div>
    </div>
  );
}

interface EditorProps {
  note: Note | null;
  onSave: (id: string, data: { title?: string; content?: string }) => void;
}

export function Editor({ note, onSave }: EditorProps) {
  if (!note) {
    return (
      <div className="editor editor--empty">
        <div className="editor__placeholder">
          <div className="editor__placeholder-icon">◈</div>
          <div className="editor__placeholder-text">
            Select a note or press ⌘N to create one
          </div>
        </div>
      </div>
    );
  }

  return <EditorInner key={note.id} note={note} onSave={onSave} />;
}
