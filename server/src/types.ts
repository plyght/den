export interface Note {
  id: string;
  title: string;
  content: string;
  pinned: boolean;
  tags: string[];
  created_at: string;
  updated_at: string;
}

export interface NoteRow {
  id: string;
  title: string;
  content: string;
  pinned: number;
  tags: string;
  created_at: string;
  updated_at: string;
}

export interface CreateNoteBody {
  title?: string;
  content: string;
  pinned?: boolean;
  tags?: string[];
}

export interface UpdateNoteBody {
  title?: string;
  content?: string;
  pinned?: boolean;
  tags?: string[];
}

export interface ListQuery {
  limit?: string;
  offset?: string;
  pinned?: string;
  search?: string;
}

export interface WsEvent {
  type: "note:created" | "note:updated" | "note:deleted";
  note: Note;
}
