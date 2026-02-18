import type { ServerWebSocket } from "bun";
import type { WsEvent } from "./types";

export interface WsData {
  id: string;
}

const clients = new Set<ServerWebSocket<WsData>>();

export function wsOpen(ws: ServerWebSocket<WsData>): void {
  clients.add(ws);
}

export function wsClose(ws: ServerWebSocket<WsData>): void {
  clients.delete(ws);
}

export function wsMessage(
  ws: ServerWebSocket<WsData>,
  message: string | Buffer,
): void {
  if (message === "ping") {
    ws.send("pong");
  }
}

export function broadcast(event: WsEvent): void {
  const payload = JSON.stringify(event);
  for (const client of clients) {
    try {
      client.send(payload);
    } catch {}
  }
}

export function getClientCount(): number {
  return clients.size;
}
