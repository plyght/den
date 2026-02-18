import { getConfig } from "./config.js";

export interface Note {
  id: string;
  title: string;
  content: string;
  pinned: boolean;
  tags: string[];
  created_at: string;
  updated_at: string;
}

export interface NotesResponse {
  notes: Note[];
  total: number;
}

function headers(): HeadersInit {
  const { authToken } = getConfig();
  const h: Record<string, string> = {
    "Content-Type": "application/json",
  };
  if (authToken) {
    h["Authorization"] = `Bearer ${authToken}`;
  }
  return h;
}

function baseUrl(): string {
  return getConfig().serverUrl;
}

export async function fetchNotes(params?: {
  limit?: number;
  offset?: number;
  search?: string;
  pinned?: boolean;
}): Promise<NotesResponse> {
  const url = new URL(`${baseUrl()}/api/notes`);
  if (params?.limit !== undefined)
    url.searchParams.set("limit", String(params.limit));
  if (params?.offset !== undefined)
    url.searchParams.set("offset", String(params.offset));
  if (params?.search) url.searchParams.set("search", params.search);
  if (params?.pinned !== undefined)
    url.searchParams.set("pinned", String(params.pinned));

  const res = await fetch(url.toString(), { headers: headers() });
  if (!res.ok) throw new Error(`Failed to fetch notes: ${res.status}`);
  return res.json() as Promise<NotesResponse>;
}

export async function getNote(id: string): Promise<Note> {
  const res = await fetch(`${baseUrl()}/api/notes/${id}`, {
    headers: headers(),
  });
  if (!res.ok) throw new Error(`Failed to get note: ${res.status}`);
  return res.json() as Promise<Note>;
}

export async function createNote(data: {
  title?: string;
  content: string;
  pinned?: boolean;
  tags?: string[];
}): Promise<Note> {
  const res = await fetch(`${baseUrl()}/api/notes`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(`Failed to create note: ${res.status}`);
  return res.json() as Promise<Note>;
}

export async function updateNote(
  id: string,
  data: {
    title?: string;
    content?: string;
    pinned?: boolean;
    tags?: string[];
  },
): Promise<Note> {
  const res = await fetch(`${baseUrl()}/api/notes/${id}`, {
    method: "PUT",
    headers: headers(),
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(`Failed to update note: ${res.status}`);
  return res.json() as Promise<Note>;
}

export async function deleteNote(id: string): Promise<void> {
  const res = await fetch(`${baseUrl()}/api/notes/${id}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) throw new Error(`Failed to delete note: ${res.status}`);
}
