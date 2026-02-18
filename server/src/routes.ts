import {
  dbCreateNote,
  dbDeleteNote,
  dbGetNote,
  dbListNotes,
  dbUpdateNote,
} from "./db";
import type { CreateNoteBody, ListQuery, Note, UpdateNoteBody } from "./types";
import { jsonResponse } from "./auth";
import { broadcast } from "./ws";

function deriveTitleFromContent(content: string): string {
  const firstLine = content.split("\n")[0] ?? "";
  return firstLine.replace(/^#+\s*/, "").trim();
}

export async function handleCreateNote(req: Request): Promise<Response> {
  let body: CreateNoteBody;
  try {
    body = (await req.json()) as CreateNoteBody;
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }

  if (typeof body.content !== "string") {
    return jsonResponse({ error: "content is required" }, 400);
  }

  const title =
    body.title?.trim() || deriveTitleFromContent(body.content) || "Untitled";

  const now = new Date().toISOString();
  const note: Note = {
    id: crypto.randomUUID(),
    title,
    content: body.content,
    pinned: body.pinned ?? false,
    tags: body.tags ?? [],
    created_at: now,
    updated_at: now,
  };

  const created = dbCreateNote(note);
  broadcast({ type: "note:created", note: created });
  return jsonResponse(created, 201);
}

export async function handleListNotes(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const q = Object.fromEntries(url.searchParams.entries()) as ListQuery;

  const limit = Math.min(parseInt(q.limit ?? "50", 10) || 50, 200);
  const offset = parseInt(q.offset ?? "0", 10) || 0;
  const pinned = q.pinned !== undefined ? q.pinned === "true" : undefined;
  const search = q.search?.trim() || undefined;

  const result = dbListNotes({ limit, offset, pinned, search });
  return jsonResponse(result);
}

export async function handleGetNote(id: string): Promise<Response> {
  const note = dbGetNote(id);
  if (!note) return jsonResponse({ error: "Not found" }, 404);
  return jsonResponse(note);
}

export async function handleUpdateNote(
  req: Request,
  id: string,
): Promise<Response> {
  const existing = dbGetNote(id);
  if (!existing) return jsonResponse({ error: "Not found" }, 404);

  let body: UpdateNoteBody;
  try {
    body = (await req.json()) as UpdateNoteBody;
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }

  const fields: Partial<Omit<Note, "id" | "created_at">> = {};

  if (body.content !== undefined) {
    fields.content = body.content;
    if (body.title === undefined && !existing.title) {
      fields.title = deriveTitleFromContent(body.content) || "Untitled";
    }
  }
  if (body.title !== undefined) fields.title = body.title;
  if (body.pinned !== undefined) fields.pinned = body.pinned;
  if (body.tags !== undefined) fields.tags = body.tags;

  const updated = dbUpdateNote(id, fields);
  if (!updated) return jsonResponse({ error: "Not found" }, 404);

  broadcast({ type: "note:updated", note: updated });
  return jsonResponse(updated);
}

export async function handleDeleteNote(id: string): Promise<Response> {
  const note = dbGetNote(id);
  if (!note) return jsonResponse({ error: "Not found" }, 404);

  const deleted = dbDeleteNote(id);
  if (!deleted) return jsonResponse({ error: "Not found" }, 404);

  broadcast({ type: "note:deleted", note });
  return jsonResponse({ ok: true });
}
