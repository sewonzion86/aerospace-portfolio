import React, { useMemo, useState, useCallback } from "react";
import {
  LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid,
  ResponsiveContainer, ReferenceLine, Cell
} from "recharts";
import { Waves, Radio, Activity, Play, RefreshCw } from "lucide-react";

// ---------- palette (LIGO control-room, not decorative) ----------
const C = {
  bg: "#0D1120",
  panel: "#141A2E",
  panelEdge: "#262F4D",
  text: "#E7EAF3",
  muted: "#8892B0",
  faint: "#4B547A",
  strain: "#49D8C8",     // true chirp / matched template
  raw: "#3E4874",        // raw noisy trace
  naive: "#7C8CE0",      // Gaussian-only negative
  hard: "#E8A33D",       // realistic glitch negative
  bad: "#E1547E",        // false alarm / adversarial flag
};

const mono = "'IBM Plex Mono','SF Mono',Consolas,monospace";
const sans = "'Inter',-apple-system,'Segoe UI',sans-serif";

// ---------- signal generation ----------
const FS = 256;
const BUF_DUR = 1.5;
const N = Math.round(FS * BUF_DUR);      // 384
const MORPH_DUR = 0.75;
const M = Math.round(FS * MORPH_DUR);    // 192

function randn() {
  let u = 0, v = 0;
  while (u === 0) u = Math.random();
  while (v === 0) v = Math.random();
  return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
}
const noiseBuffer = (n) => Array.from({ length: n }, () => randn());

function unitEnergy(sig) {
  const e = Math.sqrt(sig.reduce((s, v) => s + v * v, 0)) || 1;
  return sig.map((v) => v / e);
}

// idealized BBH-like chirp: rising freq/amplitude inspiral -> ringdown decay
function makeChirp() {
  const n = M, dt = 1 / FS, tc = MORPH_DUR * 0.82, f0 = 35, f1 = 250;
  let phase = 0;
  const sig = new Array(n);
  for (let i = 0; i < n; i++) {
    const t = i * dt;
    let freq, amp;
    if (t < tc) {
      const x = t / tc;
      freq = f0 + (f1 - f0) * Math.pow(x, 3);
      amp = Math.min(3, Math.pow(Math.max(tc - t, 0.005) / MORPH_DUR, -0.22));
    } else {
      freq = f1 * 0.92;
      amp = 3 * Math.exp(-(t - tc) / 0.05);
    }
    phase += 2 * Math.PI * freq * dt;
    sig[i] = amp * Math.sin(phase);
  }
  return unitEnergy(sig);
}

// real LIGO/Gravity-Spy style glitch morphologies: broadband, non-chirping
function makeGlitch(type) {
  const n = M, dt = 1 / FS, tc = MORPH_DUR / 2;
  const sig = new Array(n);
  for (let i = 0; i < n; i++) {
    const t = i * dt;
    let v = 0;
    if (type === "blip") {
      const env = Math.exp(-Math.pow((t - tc) / (MORPH_DUR * 0.06), 2));
      v = env * Math.sin(2 * Math.PI * 180 * t);
    } else if (type === "scattered") {
      const env = Math.exp(-Math.pow((t - tc) / (MORPH_DUR * 0.28), 2));
      v = env * (Math.sin(2 * Math.PI * 8 * t) + 0.6 * Math.sin(2 * Math.PI * 14 * t + 1));
    } else {
      const decay = t > tc ? Math.exp(-(t - tc) / (MORPH_DUR * 0.1)) : 1;
      const env = Math.exp(-Math.pow((t - tc) / (MORPH_DUR * 0.15), 2)) * decay;
      v = env * (Math.sin(2 * Math.PI * 90 * t) + 0.5 * Math.sin(2 * Math.PI * 180 * t) + 0.3 * Math.sin(2 * Math.PI * 270 * t));
    }
    sig[i] = v;
  }
  return unitEnergy(sig);
}

function embed(buffer, morph, offset, amp) {
  const out = buffer.slice();
  for (let i = 0; i < morph.length; i++) out[offset + i] += amp * morph[i];
  return out;
}

// simplified local-RMS whitening (illustrative stand-in for PSD whitening)
function whiten(buf, w = 24) {
  const n = buf.length, out = new Array(n);
  for (let i = 0; i < n; i++) {
    let s = 0, c = 0;
    for (let j = Math.max(0, i - w); j <= Math.min(n - 1, i + w); j++) { s += buf[j] * buf[j]; c++; }
    out[i] = buf[i] / (Math.sqrt(s / c) || 1e-6);
  }
  return out;
}

// normalized matched filter (sliding template correlation)
function matchedFilter(whitened, template) {
  const lags = N - M + 1;
  let best = -Infinity, bestIdx = 0;
  const scores = new Array(lags);
  for (let lag = 0; lag < lags; lag++) {
    let dot = 0, energy = 0;
    for (let j = 0; j < M; j++) {
      const s = whitened[lag + j];
      dot += s * template[j];
      energy += s * s;
    }
    const score = dot / (Math.sqrt(energy) || 1e-6);
    scores[lag] = score;
    if (score > best) { best = score; bestIdx = lag; }
  }
  return { peak: best, peakIdx: bestIdx, scores };
}

function oneTrial(condition, ampLinear, glitchType, template) {
  const noise = noiseBuffer(N);
  const offset = Math.max(0, Math.min(N - M, Math.floor(N / 2 - M / 2 + (Math.random() - 0.5) * 40)));
  let buf = noise;
  if (condition === "chirp") buf = embed(noise, template, offset, ampLinear);
  else if (condition === "hard") buf = embed(noise, makeGlitch(glitchType), offset, ampLinear);
  const whitened = whiten(buf);
  const mf = matchedFilter(whitened, template);
  return { peak: mf.peak, buf, whitened, scores: mf.scores, offset };
}

function bootstrapCI(detections, B = 1000) {
  const n = detections.length;
  const means = new Array(B);
  for (let b = 0; b < B; b++) {
    let s = 0;
    for (let i = 0; i < n; i++) s += detections[Math.floor(Math.random() * n)] ? 1 : 0;
    means[b] = s / n;
  }
  means.sort((a, b) => a - b);
  return {
    lo: means[Math.floor(B * 0.025)],
    hi: means[Math.floor(B * 0.975)],
    dist: means,
  };
}

// ---------- UI bits ----------
function Panel({ title, icon: Icon, children }) {
  return (
    <div style={{ background: C.panel, border: `1px solid ${C.panelEdge}`, borderRadius: 4 }}>
      <div style={{
        display: "flex", alignItems: "center", gap: 8, padding: "10px 14px",
        borderBottom: `1px solid ${C.panelEdge}`, color: C.muted, fontSize: 12,
        fontFamily: mono, letterSpacing: 0.3,
      }}>
        {Icon && <Icon size={13} strokeWidth={2} />}
        {title}
      </div>
      <div style={{ padding: 14 }}>{children}</div>
    </div>
  );
}

function Slider({ label, value, min, max, step, onChange, suffix }) {
  return (
    <div style={{ marginBottom: 16 }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
        <span style={{ fontFamily: sans, fontSize: 12.5, color: C.muted }}>{label}</span>
        <span style={{ fontFamily: mono, fontSize: 12.5, color: C.text }}>{value}{suffix}</span>
      </div>
      <input
        type="range" min={min} max={max} step={step} value={value}
        onChange={(e) => onChange(parseFloat(e.target.value))}
        style={{ width: "100%", accentColor: C.strain }}
      />
    </div>
  );
}

function waveData(buf, whitened) {
  return buf.map((v, i) => ({ i, raw: v, wht: whitened ? whitened[i] * 0.6 : undefined }));
}

function CIRow({ label, rate, ci, color, flag }) {
  const pct = (x) => `${(x * 100).toFixed(1)}%`;
  return (
    <div style={{ marginBottom: 14 }}>
      <div style={{ display: "flex", justifyContent: "space-between", fontFamily: sans, fontSize: 12.5, color: C.muted, marginBottom: 5 }}>
        <span>{label}</span>
        <span style={{ fontFamily: mono, color: flag ? C.bad : C.text }}>
          {pct(rate)} <span style={{ color: C.faint }}>[{pct(ci.lo)}–{pct(ci.hi)}]</span>
        </span>
      </div>
      <div style={{ position: "relative", height: 8, background: "#1B2340", borderRadius: 4 }}>
        <div style={{
          position: "absolute", left: `${ci.lo * 100}%`, width: `${(ci.hi - ci.lo) * 100}%`,
          height: "100%", background: color, opacity: 0.35, borderRadius: 4,
        }} />
        <div style={{
          position: "absolute", left: `${rate * 100}%`, top: -2, width: 2, height: 12,
          background: flag ? C.bad : color,
        }} />
      </div>
    </div>
  );
}

const GLITCHES = [
  { id: "blip", label: "Blip" },
  { id: "scattered", label: "Scattered Light" },
  { id: "koi", label: "Koi Fish" },
];

export default function App() {
  const template = useMemo(() => makeChirp(), []);
  const [snrDb, setSnrDb] = useState(10);
  const [threshold, setThreshold] = useState(5);
  const [numTrials, setNumTrials] = useState(80);
  const [glitchType, setGlitchType] = useState("blip");
  const [running, setRunning] = useState(false);
  const [res, setRes] = useState(null);

  const run = useCallback(() => {
    setRunning(true);
    setTimeout(() => {
      const ampLinear = Math.pow(10, snrDb / 20) * 0.35;
      const conditions = { chirp: [], naive: [], hard: [] };
      const examples = {};
      ["chirp", "naive", "hard"].forEach((cond) => {
        for (let t = 0; t < numTrials; t++) {
          const trial = oneTrial(cond === "naive" ? "naive" : cond, ampLinear, glitchType, template);
          conditions[cond].push(trial.peak);
          if (t === 0) examples[cond] = trial;
        }
      });
      const out = {};
      ["chirp", "naive", "hard"].forEach((cond) => {
        const det = conditions[cond].map((p) => p > threshold);
        const rate = det.filter(Boolean).length / det.length;
        const ci = bootstrapCI(det);
        out[cond] = { rate, ci, peaks: conditions[cond], example: examples[cond] };
      });
      setRes(out);
      setRunning(false);
    }, 30);
  }, [snrDb, threshold, numTrials, glitchType, template]);

  const gapFlag = res && (res.hard.rate - res.naive.rate > 0.08);

  const histBins = useMemo(() => {
    if (!res) return [];
    const dist = res.hard.ci.dist;
    const bins = 16;
    const counts = new Array(bins).fill(0);
    dist.forEach((v) => {
      const idx = Math.min(bins - 1, Math.floor(v * bins));
      counts[idx]++;
    });
    return counts.map((c, i) => ({ x: (i / bins).toFixed(2), c }));
  }, [res]);

  return (
    <div style={{ background: C.bg, color: C.text, fontFamily: sans, minHeight: "100%", padding: "20px 16px" }}>
      <div style={{ maxWidth: 980, margin: "0 auto" }}>
        {/* header */}
        <div style={{ marginBottom: 20 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, color: C.strain, fontFamily: mono, fontSize: 12, marginBottom: 6 }}>
            <Waves size={14} /> ADVERSARIAL GW-ML VALIDATOR
          </div>
          <h1 style={{ fontSize: 22, fontWeight: 600, margin: 0, lineHeight: 1.3 }}>
            Does your detector survive real detector glitches?
          </h1>
          <p style={{ color: C.muted, fontSize: 13, maxWidth: 640, marginTop: 8, lineHeight: 1.55 }}>
            A from-scratch, in-browser reproduction of the pipeline's core test: inject a synthetic
            BBH-like chirp, whiten, matched-filter, then check whether the false-alarm rate against
            realistic glitches is hidden by testing only against Gaussian noise.
          </p>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "minmax(0,260px) minmax(0,1fr)", gap: 16 }}>
          {/* controls */}
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            <Panel title="INJECTION" icon={Radio}>
              <Slider label="Injected SNR" value={snrDb} min={4} max={20} step={1} suffix=" dB" onChange={setSnrDb} />
              <Slider label="Detection threshold ρ*" value={threshold} min={2} max={9} step={0.5} onChange={setThreshold} />
              <Slider label="Trials per condition" value={numTrials} min={20} max={250} step={10} onChange={setNumTrials} />
              <div style={{ marginBottom: 4 }}>
                <div style={{ fontSize: 12.5, color: C.muted, marginBottom: 6 }}>Hard-negative glitch class</div>
                <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                  {GLITCHES.map((g) => (
                    <button key={g.id} onClick={() => setGlitchType(g.id)}
                      style={{
                        fontFamily: mono, fontSize: 11, padding: "5px 9px", borderRadius: 3,
                        border: `1px solid ${glitchType === g.id ? C.hard : C.panelEdge}`,
                        background: glitchType === g.id ? "rgba(232,163,61,0.12)" : "transparent",
                        color: glitchType === g.id ? C.hard : C.muted, cursor: "pointer",
                      }}>{g.label}</button>
                  ))}
                </div>
              </div>
            </Panel>

            <button onClick={run} disabled={running} style={{
              display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
              background: C.strain, color: "#0A1015", border: "none", borderRadius: 4,
              padding: "11px 0", fontFamily: sans, fontWeight: 600, fontSize: 13.5,
              cursor: running ? "default" : "pointer", opacity: running ? 0.7 : 1,
            }}>
              {running ? <RefreshCw size={15} className="animate-spin" /> : <Play size={15} />}
              {running ? "Running validation…" : "Run validation"}
            </button>

            {res && (
              <Panel title="RESULT" icon={Activity}>
                <CIRow label="TPR — true chirp" rate={res.chirp.rate} ci={res.chirp.ci} color={C.strain} />
                <CIRow label="FAR — Gaussian noise only" rate={res.naive.rate} ci={res.naive.ci} color={C.naive} />
                <CIRow label={`FAR — ${GLITCHES.find(g=>g.id===glitchType).label} glitch`} rate={res.hard.rate} ci={res.hard.ci} color={C.hard} flag={gapFlag} />
                <div style={{ fontSize: 11.5, color: gapFlag ? C.bad : C.muted, lineHeight: 1.5, marginTop: 10, fontFamily: mono }}>
                  {gapFlag
                    ? `⚠ gap of ${((res.hard.rate - res.naive.rate) * 100).toFixed(1)}pp — Gaussian-only testing hides this glitch class`
                    : "no significant gap at this threshold/SNR — try lowering ρ* or SNR"}
                </div>
              </Panel>
            )}
          </div>

          {/* main viz */}
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            <Panel title="TEMPLATE — synthetic BBH-like chirp">
              <ResponsiveContainer width="100%" height={90}>
                <LineChart data={template.map((v, i) => ({ i, v }))}>
                  <Line type="monotone" dataKey="v" stroke={C.strain} dot={false} strokeWidth={1.5} isAnimationActive={false} />
                </LineChart>
              </ResponsiveContainer>
            </Panel>

            {res ? (
              <>
                <Panel title="EXAMPLE TRIAL — chirp + noise (whitened, ×0.6)">
                  <ResponsiveContainer width="100%" height={100}>
                    <LineChart data={waveData(res.chirp.example.buf, res.chirp.example.whitened)}>
                      <Line type="monotone" dataKey="raw" stroke={C.raw} dot={false} strokeWidth={1} isAnimationActive={false} />
                      <Line type="monotone" dataKey="wht" stroke={C.strain} dot={false} strokeWidth={1.3} isAnimationActive={false} />
                    </LineChart>
                  </ResponsiveContainer>
                </Panel>

                <Panel title={`EXAMPLE TRIAL — ${GLITCHES.find(g=>g.id===glitchType).label} glitch (hard negative)`}>
                  <ResponsiveContainer width="100%" height={100}>
                    <LineChart data={waveData(res.hard.example.buf, res.hard.example.whitened)}>
                      <Line type="monotone" dataKey="raw" stroke={C.raw} dot={false} strokeWidth={1} isAnimationActive={false} />
                      <Line type="monotone" dataKey="wht" stroke={C.hard} dot={false} strokeWidth={1.3} isAnimationActive={false} />
                    </LineChart>
                  </ResponsiveContainer>
                </Panel>

                <Panel title="BOOTSTRAP DISTRIBUTION — false-alarm rate on hard negative (1000 resamples)">
                  <ResponsiveContainer width="100%" height={130}>
                    <BarChart data={histBins}>
                      <CartesianGrid stroke={C.panelEdge} vertical={false} />
                      <XAxis dataKey="x" tick={{ fill: C.muted, fontSize: 10, fontFamily: mono }} interval={3} axisLine={{ stroke: C.panelEdge }} tickLine={false} />
                      <YAxis tick={{ fill: C.muted, fontSize: 10, fontFamily: mono }} axisLine={{ stroke: C.panelEdge }} tickLine={false} width={26} />
                      <Bar dataKey="c" isAnimationActive={false}>
                        {histBins.map((b, i) => (
                          <Cell key={i} fill={parseFloat(b.x) >= res.hard.ci.lo && parseFloat(b.x) <= res.hard.ci.hi ? C.hard : C.faint} />
                        ))}
                      </Bar>
                      <ReferenceLine x={res.naive.rate.toFixed(2)} stroke={C.naive} strokeDasharray="3 3" />
                    </BarChart>
                  </ResponsiveContainer>
                  <div style={{ fontSize: 10.5, color: C.muted, marginTop: 4, fontFamily: mono }}>
                    dashed line = Gaussian-only FAR point estimate, for comparison
                  </div>
                </Panel>
              </>
            ) : (
              <Panel title="AWAITING RUN">
                <div style={{ color: C.muted, fontSize: 12.5, padding: "20px 4px" }}>
                  Set your SNR, threshold and glitch class, then run the validation to generate
                  chirp / Gaussian-negative / hard-negative trials and their bootstrap CIs.
                </div>
              </Panel>
            )}
          </div>
        </div>

        <div style={{ marginTop: 20, fontSize: 11, color: C.faint, fontFamily: mono, lineHeight: 1.6 }}>
          Simplified in-browser reproduction — local-RMS whitening and a normalized matched-filter
          statistic stand in for full PSD whitening and template-bank search. The comparison it
          demonstrates (naive Gaussian negatives vs. realistic glitch negatives) is the same one
          the paper's audit was built around.
        </div>
      </div>
    </div>
  );
}