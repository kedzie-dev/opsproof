import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  return worker.fetch(new Request("http://localhost/", { headers: { accept: "text/html" } }), {
    ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) },
  }, { waitUntil() {}, passThroughOnException() {} });
}

test("server-renders the schema compatibility replay", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);
  const html = await response.text();
  assert.match(html, /<title>OpsProof Replay Prototype<\/title>/i);
  assert.match(html, /Schema Compatibility Lab/);
  assert.match(html, /A green rollout can still hide a red request path\./);
  assert.match(html, /Deployment Gate/);
  assert.doesNotMatch(html, /codex-preview|loading skeleton|react-loading-skeleton/i);
});

test("keeps the three layout choices explicit and shareable", async () => {
  const page = await readFile(new URL("../app/page.tsx", import.meta.url), "utf8");
  assert.match(page, /\?variant=/);
  assert.match(page, /Control room/);
  assert.match(page, /Request stream/);
  assert.match(page, /Decision brief/);
  assert.match(page, /Representative data, not a live cluster/);
});
