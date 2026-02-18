export function getAuthToken(): string {
  const existing = process.env.DEN_AUTH_TOKEN;
  if (existing && existing.trim().length > 0) {
    return existing.trim();
  }
  const generated = crypto.randomUUID().replace(/-/g, "");
  process.env.DEN_AUTH_TOKEN = generated;
  return generated;
}

export function validateAuthHeader(request: Request): boolean {
  const authHeader = request.headers.get("Authorization");
  if (!authHeader) return false;
  const parts = authHeader.split(" ");
  if (parts.length !== 2 || parts[0] !== "Bearer") return false;
  return parts[1] === getAuthToken();
}

export function validateWsToken(token: string | null): boolean {
  if (!token) return false;
  return token === getAuthToken();
}

export function unauthorizedResponse(): Response {
  return new Response(JSON.stringify({ error: "Unauthorized" }), {
    status: 401,
    headers: corsHeaders({ "Content-Type": "application/json" }),
  });
}

export function corsHeaders(
  extra: Record<string, string> = {},
): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    ...extra,
  };
}

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: corsHeaders({ "Content-Type": "application/json" }),
  });
}
