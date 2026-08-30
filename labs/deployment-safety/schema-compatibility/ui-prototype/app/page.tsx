"use client";

import { useEffect, useMemo, useState } from "react";

// PROTOTYPE: Three schema-compatibility replay layouts, switchable with ?variant=.
type ScenarioId = "unsafe" | "safe" | "rollback";
type VariantId = "control" | "traffic" | "brief";

type Scenario = {
  id: ScenarioId;
  tab: string;
  title: string;
  transition: string;
  verdict: "BLOCK" | "ALLOW";
  verdictDetail: string;
  migration: string;
  migrationState: "danger" | "safe";
  requests: { passed: number; failed: number };
  persistence: string;
  recovery: string;
  events: { at: number; title: string; detail: string; tone: "neutral" | "danger" | "safe" }[];
};

const scenarios: Record<ScenarioId, Scenario> = {
  unsafe: {
    id: "unsafe", tab: "Unsafe rename", title: "A green rollout can still hide a red request path.",
    transition: "Rename customer_name → buyer_name", verdict: "BLOCK",
    verdictDetail: "The old revision still receives traffic after its column disappears.", migration: "Destructive rename", migrationState: "danger",
    requests: { passed: 24, failed: 6 }, persistence: "Failed requests were not persisted", recovery: "Restore schema, then roll back the image",
    events: [
      { at: 0, title: "Migration applied", detail: "customer_name renamed to buyer_name", tone: "danger" },
      { at: 2, title: "Synthetic check begins", detail: "30 order requests begin flowing through Service", tone: "neutral" },
      { at: 4, title: "v1 receives traffic", detail: "Old Pod asks for customer_name → 500", tone: "danger" },
      { at: 10, title: "v2 becomes Ready", detail: "New Pod uses buyer_name", tone: "safe" },
      { at: 15, title: "Rollout completes", detail: "Kubernetes reports success", tone: "safe" },
      { at: 16, title: "Gate blocks deployment", detail: "A real request and persistence check failed", tone: "danger" },
    ],
  },
  safe: {
    id: "safe", tab: "Safe expand", title: "Both revisions can serve traffic while the schema grows.",
    transition: "Add nullable buyer_name", verdict: "ALLOW",
    verdictDetail: "Both revisions use a schema they understand during the rollout.", migration: "Compatible expand", migrationState: "safe",
    requests: { passed: 30, failed: 0 }, persistence: "Every created order was persisted", recovery: "v1 can safely ignore the extra column",
    events: [
      { at: 0, title: "Migration applied", detail: "Nullable buyer_name column added", tone: "safe" },
      { at: 2, title: "Synthetic check begins", detail: "30 order requests begin flowing through Service", tone: "neutral" },
      { at: 4, title: "v1 receives traffic", detail: "v1 continues using customer_name", tone: "safe" },
      { at: 10, title: "v2 becomes Ready", detail: "v2 writes both compatible columns", tone: "safe" },
      { at: 15, title: "Rollout completes", detail: "Kubernetes reports success", tone: "safe" },
      { at: 16, title: "Gate allows deployment", detail: "All requests and persistence checks passed", tone: "safe" },
    ],
  },
  rollback: {
    id: "rollback", tab: "Safe rollback", title: "An expand change keeps the previous revision recoverable.",
    transition: "Roll back v2 → v1 after safe expand", verdict: "ALLOW",
    verdictDetail: "v1 ignores buyer_name and continues to create orders.", migration: "No destructive schema change", migrationState: "safe",
    requests: { passed: 30, failed: 0 }, persistence: "Every post-rollback order was persisted", recovery: "Image-only rollback is sufficient",
    events: [
      { at: 0, title: "Rollback requested", detail: "Deployment template returns to v1", tone: "neutral" },
      { at: 2, title: "Synthetic check begins", detail: "Requests continue while Pods are replaced", tone: "neutral" },
      { at: 5, title: "v1 receives traffic", detail: "Extra buyer_name column is ignored", tone: "safe" },
      { at: 10, title: "v1 becomes Ready", detail: "Previous revision is fully available", tone: "safe" },
      { at: 15, title: "Rollback completes", detail: "Kubernetes reports the earlier template", tone: "safe" },
      { at: 16, title: "Gate allows recovery", detail: "All requests and persistence checks passed", tone: "safe" },
    ],
  },
};

const variantOrder: VariantId[] = ["control", "traffic", "brief"];
const variantNames: Record<VariantId, string> = { control: "Control room", traffic: "Request stream", brief: "Decision brief" };

function variantFromSearch(): VariantId {
  if (typeof window === "undefined") return "control";
  const value = new URLSearchParams(window.location.search).get("variant");
  return variantOrder.includes(value as VariantId) ? (value as VariantId) : "control";
}
function ResultPill({ tone, children }: { tone: "safe" | "danger" | "neutral"; children: React.ReactNode }) { return <span className={`result-pill ${tone}`}>{children}</span>; }
function Gate({ scenario, compact = false }: { scenario: Scenario; compact?: boolean }) {
  const tone = scenario.verdict === "ALLOW" ? "safe" : "danger";
  return <section className={`gate ${tone} ${compact ? "gate-compact" : ""}`} aria-label="Deployment gate result"><div className="eyebrow">Deployment Gate</div><div className="gate-main"><span className="gate-symbol">{tone === "safe" ? "✓" : "×"}</span>{scenario.verdict}</div><p>{scenario.verdictDetail}</p></section>;
}
function MiniMetric({ label, value, detail, tone = "neutral" }: { label: string; value: string; detail: string; tone?: "safe" | "danger" | "neutral" }) { return <div className={`mini-metric ${tone}`}><span>{label}</span><strong>{value}</strong><small>{detail}</small></div>; }
function Progress({ elapsed, scenario }: { elapsed: number; scenario: Scenario }) { const percent = Math.min((elapsed / 16) * 100, 100); return <div className="replay-progress" aria-label={`Replay progress: ${Math.round(percent)} percent`}><div className="progress-track"><span style={{ width: `${percent}%` }} /></div><span>{elapsed.toString().padStart(2, "0")}s / 16s</span><span className={scenario.verdict === "ALLOW" ? "text-safe" : "text-danger"}>{scenario.verdict}</span></div>; }
function Timeline({ scenario, elapsed }: { scenario: Scenario; elapsed: number }) { return <ol className="timeline" aria-label="Deployment replay timeline">{scenario.events.map((event) => <li key={event.title} className={`${event.tone} ${event.at <= elapsed ? "active" : ""}`}><time>{event.at.toString().padStart(2, "0")}s</time><span className="timeline-dot" aria-hidden="true" /><div><strong>{event.title}</strong><p>{event.detail}</p></div></li>)}</ol>; }
function Pod({ revision, mode, active, error }: { revision: "v1" | "v2"; mode: string; active: boolean; error?: boolean }) { return <div className={`pod ${active ? "pod-active" : ""} ${error ? "pod-error" : ""}`}><div className="pod-head"><span>{revision}</span><ResultPill tone={error ? "danger" : "safe"}>{error ? "500" : "Ready"}</ResultPill></div><strong>Order API</strong><small>{mode}</small><div className="pod-dots"><i /><i /><i /></div></div>; }
function Database({ scenario }: { scenario: Scenario }) { const safe = scenario.migrationState === "safe"; return <div className={`database ${safe ? "database-safe" : "database-danger"}`}><div className="db-top">PostgreSQL</div><div className="db-body"><span>orders</span><code>id</code><code className={safe ? "schema-kept" : "schema-removed"}>customer_name</code><code className="schema-new">buyer_name {safe ? "NULL" : ""}</code></div></div>; }

function ControlRoom({ scenario, elapsed }: { scenario: Scenario; elapsed: number }) {
  const failing = scenario.id === "unsafe" && elapsed >= 4;
  return <main className="control-room"><section className="headline-row"><div><span className="prototype-tag">Prototype · representative replay</span><h1>{scenario.title}</h1><p>{scenario.transition}</p></div><Gate scenario={scenario} compact /></section><section className="metrics-grid" aria-label="Experiment summary"><MiniMetric label="Rollout" value="SUCCESS" detail="Deployment reaches desired replicas" tone="safe" /><MiniMetric label="Synthetic requests" value={`${scenario.requests.passed} / 30`} detail={scenario.requests.failed ? `${scenario.requests.failed} failures observed` : "No failures"} tone={scenario.requests.failed ? "danger" : "safe"} /><MiniMetric label="Persistence" value={scenario.requests.failed ? "INCOMPLETE" : "VERIFIED"} detail={scenario.persistence} tone={scenario.requests.failed ? "danger" : "safe"} /><MiniMetric label="Recovery" value={scenario.id === "unsafe" ? "SCHEMA FIRST" : "IMAGE OK"} detail={scenario.recovery} tone={scenario.id === "unsafe" ? "danger" : "safe"} /></section><section className="system-map" aria-label="Request path and schema state"><div className="map-label">Service traffic</div><div className="service-box">order-api<br /><small>load balances requests</small></div><div className="connector connector-left" /><div className="connector connector-right" /><div className="pod-stack"><Pod revision="v1" mode="uses customer_name" active={elapsed >= 2} error={failing} /><Pod revision="v2" mode={scenario.id === "unsafe" ? "uses buyer_name" : "writes both columns"} active={elapsed >= 10} /></div><div className="connector connector-db" /><Database scenario={scenario} /></section><section className="bottom-grid"><div className="panel timeline-panel"><div className="panel-title">What happened</div><Timeline scenario={scenario} elapsed={elapsed} /></div><div className="panel evidence-panel"><div className="panel-title">Evidence drawer</div><p>Raw container logs stay available as proof, but the decision is made from the contract result.</p><dl><div><dt>Migration</dt><dd>{scenario.migration}</dd></div><div><dt>Request result</dt><dd>{scenario.requests.failed ? "5xx observed" : "30 successful creates"}</dd></div><div><dt>Storage check</dt><dd>{scenario.persistence}</dd></div></dl></div></section></main>;
}

function RequestStream({ scenario, elapsed }: { scenario: Scenario; elapsed: number }) {
  const requests = useMemo(() => Array.from({ length: 30 }, (_, index) => index), []); const visible = Math.min(30, Math.max(0, Math.floor((elapsed / 16) * 30))); const failedStart = 8;
  return <main className="request-stream"><header className="stream-header"><div><span className="prototype-tag">Prototype · representative replay</span><h1>Follow the requests, not just the rollout.</h1><p>{scenario.transition}</p></div><Gate scenario={scenario} compact /></header><section className="stream-stage" aria-label="Thirty synthetic request outcomes"><div className="stream-source"><b>Synthetic<br />Check</b><span>30 order creates</span></div><div className="stream-wire"><span /></div><div className="stream-targets"><Pod revision="v1" mode="old revision" active={elapsed >= 2} error={scenario.id === "unsafe" && elapsed >= 4} /><Pod revision="v2" mode="new revision" active={elapsed >= 10} /></div><Database scenario={scenario} /></section><section className="request-ledger"><div className="ledger-heading"><div><span className="eyebrow">30 synthetic requests</span><h2>Every dot is one Order creation plus persistence check.</h2></div><ResultPill tone={scenario.requests.failed ? "danger" : "safe"}>{scenario.requests.failed ? `${scenario.requests.failed} failed` : "all persisted"}</ResultPill></div><div className="request-dots">{requests.map((request) => { const isVisible = request < visible; const isFailure = scenario.id === "unsafe" && request >= failedStart && request < failedStart + scenario.requests.failed; return <span key={request} className={`${isVisible ? "visible" : ""} ${isFailure ? "failed" : "passed"}`} title={`Request ${request + 1}: ${isFailure ? "failed" : "passed"}`} />; })}</div><div className="legend"><span><i className="legend-dot passed" />persisted</span><span><i className="legend-dot failed" />500 / not persisted</span><span><i className="legend-dot pending" />not replayed yet</span></div></section><section className="stream-conclusion"><span className="step-number">01</span><p><strong>Operational reading:</strong> {scenario.verdictDetail}</p><span className="step-number">02</span><p><strong>Recovery:</strong> {scenario.recovery}</p></section></main>;
}

function DecisionBrief({ scenario, elapsed }: { scenario: Scenario; elapsed: number }) {
  const finalEvent = scenario.events.filter((event) => event.at <= elapsed).at(-1);
  return <main className="decision-brief"><section className="brief-hero"><div><span className="prototype-tag">Prototype · representative replay</span><p className="brief-kicker">Deployment safety incident brief</p><h1>{scenario.verdict === "BLOCK" ? "Do not ship this rollout." : "This transition keeps the contract intact."}</h1><p className="brief-summary">{scenario.verdictDetail}</p></div><Gate scenario={scenario} /></section><section className="brief-facts"><div><span>01 — Change</span><strong>{scenario.transition}</strong></div><div><span>02 — Kubernetes</span><strong>Rollout succeeds</strong></div><div><span>03 — Contract</span><strong className={scenario.verdict === "ALLOW" ? "text-safe" : "text-danger"}>{scenario.requests.failed ? `${scenario.requests.failed} request failures` : "30 requests persisted"}</strong></div></section><section className="brief-body"><div className="brief-narrative"><span className="eyebrow">The important contradiction</span><h2>Readiness can be true while the deployment contract is false.</h2><p>The Service continues to send real Order creation requests throughout the RollingUpdate. The gate looks at those requests and their database persistence, not at readiness alone.</p><div className="now-card"><span>Replay moment · {elapsed}s</span><strong>{finalEvent?.title ?? "Waiting for replay"}</strong><p>{finalEvent?.detail ?? "Start the replay to reveal each piece of evidence."}</p></div></div><div className="brief-proof"><span className="eyebrow">Decision evidence</span><dl><div><dt>Migration</dt><dd>{scenario.migration}</dd></div><div><dt>Synthetic check</dt><dd>{scenario.requests.passed} pass · {scenario.requests.failed} fail</dd></div><div><dt>Persistence</dt><dd>{scenario.persistence}</dd></div><div><dt>Recovery scope</dt><dd>{scenario.recovery}</dd></div></dl><div className="recommendation">Recommended action <strong>{scenario.verdict === "BLOCK" ? "Stop, restore schema, then roll back." : "Proceed; v1 remains recoverable."}</strong></div></div></section><section className="brief-timeline"><span className="eyebrow">Evidence sequence</span><Timeline scenario={scenario} elapsed={elapsed} /></section></main>;
}

export default function Home() {
  const [scenarioId, setScenarioId] = useState<ScenarioId>("unsafe"); const [variant, setVariant] = useState<VariantId>("control"); const [elapsed, setElapsed] = useState(0); const [playing, setPlaying] = useState(false); const scenario = scenarios[scenarioId];
  useEffect(() => setVariant(variantFromSearch()), []);
  useEffect(() => { setElapsed(0); setPlaying(false); }, [scenarioId]);
  useEffect(() => { if (!playing) return; const timer = window.setInterval(() => setElapsed((current) => { if (current >= 16) { setPlaying(false); return 16; } return current + 1; }), 800); return () => window.clearInterval(timer); }, [playing]);
  useEffect(() => { const onKeyDown = (event: KeyboardEvent) => { const target = event.target as HTMLElement | null; if (target?.matches("input, textarea, [contenteditable=true]")) return; if (event.key === "ArrowLeft" || event.key === "ArrowRight") { const direction = event.key === "ArrowRight" ? 1 : -1; setVariant((current) => { const next = variantOrder[(variantOrder.indexOf(current) + direction + variantOrder.length) % variantOrder.length]; window.history.replaceState(null, "", `?variant=${next}`); return next; }); } }; window.addEventListener("keydown", onKeyDown); return () => window.removeEventListener("keydown", onKeyDown); }, []);
  function selectVariant(next: VariantId) { setVariant(next); window.history.replaceState(null, "", `?variant=${next}`); }
  const body = variant === "control" ? <ControlRoom scenario={scenario} elapsed={elapsed} /> : variant === "traffic" ? <RequestStream scenario={scenario} elapsed={elapsed} /> : <DecisionBrief scenario={scenario} elapsed={elapsed} />;
  return <div className={`app-shell variant-${variant}`}><header className="app-header"><a href="/" className="wordmark">OPS<span>PROOF</span></a><div className="scenario-tabs" role="tablist" aria-label="Replay scenario">{(Object.values(scenarios) as Scenario[]).map((item) => <button key={item.id} role="tab" aria-selected={scenarioId === item.id} className={scenarioId === item.id ? "selected" : ""} onClick={() => setScenarioId(item.id)}>{item.tab}</button>)}</div><span className="header-note">Schema Compatibility Lab</span></header><section className="replay-bar"><div><span className="live-dot" />Replay mode <small>Representative data, not a live cluster</small></div><Progress elapsed={elapsed} scenario={scenario} /><div className="replay-actions"><button className="reset-button" onClick={() => { setElapsed(0); setPlaying(false); }}>Reset</button><button className="play-button" onClick={() => setPlaying((current) => !current)}>{playing ? "Pause" : elapsed >= 16 ? "Replay again" : "Start replay"}</button></div></section>{body}<nav className="prototype-switcher" aria-label="Prototype layout switcher"><button aria-label="Previous prototype layout" onClick={() => selectVariant(variantOrder[(variantOrder.indexOf(variant) + variantOrder.length - 1) % variantOrder.length])}>←</button><span><b>{variantNames[variant]}</b><small>prototype layout</small></span><button aria-label="Next prototype layout" onClick={() => selectVariant(variantOrder[(variantOrder.indexOf(variant) + 1) % variantOrder.length])}>→</button></nav></div>;
}
