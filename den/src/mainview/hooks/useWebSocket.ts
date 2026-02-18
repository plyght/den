import { useEffect, useRef, useCallback } from "react";
import type { Note } from "../lib/api.js";
import { getConfig } from "../lib/config.js";

export type WsEvent =
  | { type: "note:created"; note: Note }
  | { type: "note:updated"; note: Note }
  | { type: "note:deleted"; note: Note };

type Handler = (event: WsEvent) => void;

export function useWebSocket(onEvent: Handler, enabled: boolean = true) {
  const wsRef = useRef<WebSocket | null>(null);
  const onEventRef = useRef<Handler>(onEvent);
  const reconnectTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const mountedRef = useRef(true);

  useEffect(() => {
    onEventRef.current = onEvent;
  }, [onEvent]);

  const connect = useCallback(() => {
    if (!enabled || !mountedRef.current) return;

    const { serverUrl, authToken } = getConfig();
    const wsUrl =
      serverUrl.replace(/^http/, "ws") +
      "/ws" +
      (authToken ? `?token=${authToken}` : "");

    try {
      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      ws.onmessage = (e) => {
        try {
          const event = JSON.parse(e.data as string) as WsEvent;
          onEventRef.current(event);
        } catch (_) {
          return;
        }
      };

      ws.onclose = () => {
        if (mountedRef.current) {
          reconnectTimer.current = setTimeout(connect, 3000);
        }
      };

      ws.onerror = () => {
        ws.close();
      };
    } catch {
      if (mountedRef.current) {
        reconnectTimer.current = setTimeout(connect, 5000);
      }
    }
  }, [enabled]);

  useEffect(() => {
    mountedRef.current = true;
    connect();

    return () => {
      mountedRef.current = false;
      if (reconnectTimer.current) clearTimeout(reconnectTimer.current);
      wsRef.current?.close();
    };
  }, [connect]);
}
