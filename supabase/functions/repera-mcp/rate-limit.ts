export type QuotaRule = { key: string; limit: number; windowSeconds: number; cost: number };

const WRITE_TOOL = /^(create|update|delete|archive|restore|set|adjust)_/;
const TOOL_NAME = /^[a-z][a-z0-9_]{0,63}$/;
export const MAX_TOOL_CALLS_PER_REQUEST = 10;

/** Tool names invoked by a JSON-RPC message or batch; unknown shapes count as plain requests. */
export function toolCalls(raw: string): string[] {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return [];
  }
  const messages = Array.isArray(parsed) ? parsed : [parsed];
  return messages.flatMap((m) => {
    const msg = m as { method?: unknown; params?: { name?: unknown } };
    if (msg?.method !== "tools/call") return [];
    const name = msg.params?.name;
    return [typeof name === "string" && TOOL_NAME.test(name) ? name : "unknown"];
  });
}

export const isWriteTool = (name: string) => WRITE_TOOL.test(name);

/**
 * Per token, per owner (all tokens of the athlete), per write volume and per tool.
 * Keys embed the window so a rule change never reuses a counter with another window.
 */
export function quotaRules(ownerId: string, tokenId: string, tools: string[]): QuotaRule[] {
  const rules: QuotaRule[] = [
    { key: `token:${tokenId}:req:60`, limit: 120, windowSeconds: 60, cost: Math.max(1, tools.length) },
    { key: `owner:${ownerId}:req:60`, limit: 300, windowSeconds: 60, cost: Math.max(1, tools.length) },
  ];
  const writes = tools.filter(isWriteTool).length;
  if (writes) {
    rules.push(
      { key: `owner:${ownerId}:write:60`, limit: 30, windowSeconds: 60, cost: writes },
      { key: `owner:${ownerId}:write:86400`, limit: 400, windowSeconds: 86_400, cost: writes },
    );
  }
  const perTool = new Map<string, number>();
  for (const tool of tools) perTool.set(tool, (perTool.get(tool) ?? 0) + 1);
  for (const [tool, cost] of [...perTool.entries()].sort(([a], [b]) => a.localeCompare(b))) {
    rules.push({
      key: `token:${tokenId}:tool:${tool}:60`,
      limit: isWriteTool(tool) ? 15 : 40,
      windowSeconds: 60,
      cost,
    });
  }
  return rules;
}
