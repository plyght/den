import {
  getAuthToken,
  validateAuthHeader,
  validateWsToken,
  corsHeaders,
  jsonResponse,
} from "./auth";
import {
  handleCreateNote,
  handleDeleteNote,
  handleGetNote,
  handleListNotes,
  handleUpdateNote,
} from "./routes";
import { wsClose, wsMessage, wsOpen } from "./ws";
import type { WsData } from "./ws";
import { getDb } from "./db";

const PORT = parseInt(process.env.DEN_PORT ?? "7745", 10);
const AUTH_TOKEN = getAuthToken();

getDb();

const NOTE_ID_PATTERN = /^\/api\/notes\/([^/]+)$/;

const server = Bun.serve<WsData>({
  port: PORT,

  fetch(req, server) {
    const url = new URL(req.url);
    const path = url.pathname;
    const method = req.method.toUpperCase();

    if (method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: corsHeaders(),
      });
    }

    if (path === "/ws") {
      const token = url.searchParams.get("token");
      if (!validateWsToken(token)) {
        return new Response("Unauthorized", { status: 401 });
      }
      const upgraded = server.upgrade(req, {
        data: { id: crypto.randomUUID() },
      });
      if (upgraded) return undefined as unknown as Response;
      return new Response("WebSocket upgrade failed", { status: 500 });
    }

    if (path === "/health") {
      return jsonResponse({ ok: true, clients: server.pendingWebSockets });
    }

    if (!validateAuthHeader(req)) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    if (path === "/api/notes" && method === "POST") {
      return handleCreateNote(req);
    }

    if (path === "/api/notes" && method === "GET") {
      return handleListNotes(req);
    }

    const noteMatch = NOTE_ID_PATTERN.exec(path);
    if (noteMatch) {
      const id = noteMatch[1]!;
      if (method === "GET") return handleGetNote(id);
      if (method === "PUT") return handleUpdateNote(req, id);
      if (method === "DELETE") return handleDeleteNote(id);
    }

    return jsonResponse({ error: "Not found" }, 404);
  },

  websocket: {
    open: wsOpen,
    close: wsClose,
    message: wsMessage,
  },
});

console.log(`🏠 Den server running on http://localhost:${server.port}`);
console.log(`🔑 Auth token: ${AUTH_TOKEN}`);
console.log(`💾 Database: ${process.env.DEN_DB_PATH ?? "./den.db"}`);
