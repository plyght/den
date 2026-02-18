export const c = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
  white: "\x1b[37m",
  gray: "\x1b[90m",
};

export function bold(s: string): string {
  return `${c.bold}${s}${c.reset}`;
}

export function dim(s: string): string {
  return `${c.dim}${s}${c.reset}`;
}

export function red(s: string): string {
  return `${c.red}${s}${c.reset}`;
}

export function green(s: string): string {
  return `${c.green}${s}${c.reset}`;
}

export function yellow(s: string): string {
  return `${c.yellow}${s}${c.reset}`;
}

export function cyan(s: string): string {
  return `${c.cyan}${s}${c.reset}`;
}

export function gray(s: string): string {
  return `${c.gray}${s}${c.reset}`;
}

export function timeAgo(dateStr: string): string {
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHr = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHr / 24);

  if (diffSec < 60) return "just now";
  if (diffMin < 60) return `${diffMin} min ago`;
  if (diffHr < 24) return `${diffHr} hr ago`;
  if (diffDay === 1) return "yesterday";
  if (diffDay < 7) return `${diffDay} days ago`;
  if (diffDay < 30) return `${Math.floor(diffDay / 7)} wk ago`;
  if (diffDay < 365) return `${Math.floor(diffDay / 30)} mo ago`;
  return `${Math.floor(diffDay / 365)} yr ago`;
}

export function truncate(s: string, maxLen: number): string {
  if (s.length <= maxLen) return s;
  return s.slice(0, maxLen - 1) + "…";
}

export function terminalWidth(): number {
  return process.stdout.columns ?? 80;
}

export function renderMarkdown(content: string): string {
  const lines = content.split("\n");
  return lines
    .map((line) => {
      if (line.startsWith("# ")) return `${c.bold}${c.cyan}${line}${c.reset}`;
      if (line.startsWith("## ")) return `${c.bold}${c.blue}${line}${c.reset}`;
      if (line.startsWith("### ")) return `${c.bold}${line}${c.reset}`;
      if (line.startsWith("- ") || line.startsWith("* "))
        return `${c.yellow}•${c.reset} ${line.slice(2)}`;
      if (/^\d+\. /.test(line)) return `${c.yellow}${line}${c.reset}`;
      return line;
    })
    .join("\n");
}

export function printError(msg: string): void {
  console.error(`${c.red}Error:${c.reset} ${msg}`);
}

export function printSuccess(msg: string): void {
  console.log(`${c.green}✓${c.reset} ${msg}`);
}
