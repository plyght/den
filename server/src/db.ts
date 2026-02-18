import { Database } from "bun:sqlite";
import type { Note, NoteRow } from "./types";

const DB_PATH = process.env.DEN_DB_PATH ?? "./den.db";

let _db: Database | null = null;

export function getDb(): Database {
  if (!_db) {
    _db = new Database(DB_PATH, { create: true });
    _db.exec("PRAGMA journal_mode=WAL;");
    _db.exec("PRAGMA foreign_keys=ON;");
    migrate(_db);
  }
  return _db;
}

function migrate(db: Database): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS notes (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL DEFAULT '',
      pinned INTEGER NOT NULL DEFAULT 0,
      tags TEXT NOT NULL DEFAULT '[]',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
      id UNINDEXED,
      title,
      content,
      content='notes',
      content_rowid='rowid'
    );

    CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
      INSERT INTO notes_fts(rowid, id, title, content)
      VALUES (new.rowid, new.id, new.title, new.content);
    END;

    CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
      INSERT INTO notes_fts(notes_fts, rowid, id, title, content)
      VALUES ('delete', old.rowid, old.id, old.title, old.content);
    END;

    CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
      INSERT INTO notes_fts(notes_fts, rowid, id, title, content)
      VALUES ('delete', old.rowid, old.id, old.title, old.content);
      INSERT INTO notes_fts(rowid, id, title, content)
      VALUES (new.rowid, new.id, new.title, new.content);
    END;
  `);
}

function rowToNote(row: NoteRow): Note {
  return {
    id: row.id,
    title: row.title,
    content: row.content,
    pinned: row.pinned === 1,
    tags: JSON.parse(row.tags) as string[],
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export function dbCreateNote(note: Note): Note {
  const db = getDb();
  db.prepare(
    `INSERT INTO notes (id, title, content, pinned, tags, created_at, updated_at)
     VALUES ($id, $title, $content, $pinned, $tags, $created_at, $updated_at)`,
  ).run({
    $id: note.id,
    $title: note.title,
    $content: note.content,
    $pinned: note.pinned ? 1 : 0,
    $tags: JSON.stringify(note.tags),
    $created_at: note.created_at,
    $updated_at: note.updated_at,
  });
  return note;
}

export function dbGetNote(id: string): Note | null {
  const db = getDb();
  const row = db
    .prepare<NoteRow, string>(`SELECT * FROM notes WHERE id = ?`)
    .get(id);
  if (!row) return null;
  return rowToNote(row);
}

export interface ListOptions {
  limit: number;
  offset: number;
  pinned?: boolean;
  search?: string;
}

export interface ListResult {
  notes: Note[];
  total: number;
}

export function dbListNotes(opts: ListOptions): ListResult {
  const db = getDb();

  if (opts.search && opts.search.trim().length > 0) {
    const term = opts.search.trim().replace(/"/g, '""');
    const ftsQuery = `"${term}"*`;

    let whereClause = "";
    const params: Record<string, string | number | boolean> = {
      $fts: ftsQuery,
      $limit: opts.limit,
      $offset: opts.offset,
    };

    if (opts.pinned !== undefined) {
      whereClause = `AND n.pinned = $pinned`;
      params.$pinned = opts.pinned ? 1 : 0;
    }

    const rows = db
      .prepare<NoteRow, Record<string, string | number | boolean>>(
        `SELECT n.* FROM notes n
       JOIN notes_fts f ON n.rowid = f.rowid
       WHERE notes_fts MATCH $fts ${whereClause}
       ORDER BY n.pinned DESC, n.updated_at DESC
       LIMIT $limit OFFSET $offset`,
      )
      .all(params);

    const countRow = db
      .prepare<{ total: number }, Record<string, string | number | boolean>>(
        `SELECT COUNT(*) as total FROM notes n
       JOIN notes_fts f ON n.rowid = f.rowid
       WHERE notes_fts MATCH $fts ${whereClause}`,
      )
      .get(params);

    return {
      notes: rows.map(rowToNote),
      total: countRow?.total ?? 0,
    };
  }

  let whereClause = "";
  const params: Record<string, number | boolean> = {
    $limit: opts.limit,
    $offset: opts.offset,
  };

  if (opts.pinned !== undefined) {
    whereClause = `WHERE pinned = $pinned`;
    params.$pinned = opts.pinned ? 1 : 0;
  }

  const rows = db
    .prepare<NoteRow, Record<string, number | boolean>>(
      `SELECT * FROM notes ${whereClause}
     ORDER BY pinned DESC, updated_at DESC
     LIMIT $limit OFFSET $offset`,
    )
    .all(params);

  const countRow = db
    .prepare<
      { total: number },
      Record<string, number | boolean>
    >(`SELECT COUNT(*) as total FROM notes ${whereClause}`)
    .get(params);

  return {
    notes: rows.map(rowToNote),
    total: countRow?.total ?? 0,
  };
}

export function dbUpdateNote(
  id: string,
  fields: Partial<Omit<Note, "id" | "created_at">>,
): Note | null {
  const db = getDb();
  const existing = dbGetNote(id);
  if (!existing) return null;

  const updated: Note = {
    ...existing,
    ...fields,
    id: existing.id,
    created_at: existing.created_at,
    updated_at: new Date().toISOString(),
  };

  db.prepare(
    `UPDATE notes SET title=$title, content=$content, pinned=$pinned, tags=$tags, updated_at=$updated_at
     WHERE id=$id`,
  ).run({
    $id: updated.id,
    $title: updated.title,
    $content: updated.content,
    $pinned: updated.pinned ? 1 : 0,
    $tags: JSON.stringify(updated.tags),
    $updated_at: updated.updated_at,
  });

  return updated;
}

export function dbDeleteNote(id: string): boolean {
  const db = getDb();
  const result = db.prepare(`DELETE FROM notes WHERE id = ?`).run(id);
  return result.changes > 0;
}
