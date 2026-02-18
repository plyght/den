import type { Config } from "./config.ts";
import { printError } from "./utils.ts";

export interface Note {
  id: string;
  title: string | null;
  content: string;
  pinned: boolean;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

export interface NotesResponse {
  notes: Note[];
  total: number;
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

function headers(token: string): Record<string, string> {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  };
}

async function request<T>(
  config: Config,
  method: string,
  path: string,
  body?: unknown,
): Promise<T | null> {
  const url = `${config.server}${path}`;
  try {
    const res = await fetch(url, {
      method,
      headers: headers(config.token),
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      printError(`Server returned ${res.status}: ${text}`);
      return null;
    }

    if (res.status === 204) return null;
    return (await res.json()) as T;
  } catch (err) {
    if (err instanceof TypeError && err.message.includes("fetch")) {
      printError(`Cannot reach server at ${config.server}. Is it running?`);
    } else {
      printError(String(err));
    }
    return null;
  }
}

export async function createNote(
  config: Config,
  body: CreateNoteBody,
): Promise<Note | null> {
  return request<Note>(config, "POST", "/api/notes", body);
}

export async function listNotes(
  config: Config,
  opts: { limit?: number; offset?: number; pinned?: boolean; search?: string },
): Promise<NotesResponse | null> {
  const params = new URLSearchParams();
  if (opts.limit !== undefined) params.set("limit", String(opts.limit));
  if (opts.offset !== undefined) params.set("offset", String(opts.offset));
  if (opts.pinned !== undefined) params.set("pinned", String(opts.pinned));
  if (opts.search) params.set("search", opts.search);
  const qs = params.toString();
  return request<NotesResponse>(
    config,
    "GET",
    `/api/notes${qs ? `?${qs}` : ""}`,
  );
}

export async function getNote(
  config: Config,
  id: string,
): Promise<Note | null> {
  return request<Note>(config, "GET", `/api/notes/${id}`);
}

export async function updateNote(
  config: Config,
  id: string,
  body: UpdateNoteBody,
): Promise<Note | null> {
  return request<Note>(config, "PUT", `/api/notes/${id}`, body);
}

export async function deleteNote(config: Config, id: string): Promise<boolean> {
  const res = await request<null>(config, "DELETE", `/api/notes/${id}`);
  return res !== null || true;
}

export async function resolveIdPrefix(
  config: Config,
  prefix: string,
): Promise<Note | null> {
  const result = await listNotes(config, { limit: 200 });
  if (!result) return null;

  const matches = result.notes.filter((n) => n.id.startsWith(prefix));

  if (matches.length === 0) {
    printError(`No note found with ID prefix "${prefix}"`);
    return null;
  }

  if (matches.length > 1) {
    console.log(`Multiple notes match prefix "${prefix}":`);
    for (const m of matches) {
      const title = m.title ?? m.content.slice(0, 40);
      console.log(`  ${m.id.slice(0, 8)}  ${title}`);
    }
    console.log("Be more specific.");
    return null;
  }

  return matches[0] ?? null;
}
