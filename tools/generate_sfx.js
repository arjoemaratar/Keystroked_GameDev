// Generates the gameplay sound effects (original, synthesized):
//   hit_left/down/up/right.wav  pitched "tok" per lane (rival and player notes)
//   hit_perfect.wav             sparkle + snap layered on top for PERFECT hits
//   miss.wav                    sour "bwomp" with a little scratch for misses
//
//   node tools/generate_sfx.js     (run from the project folder, then Godot --import)
//
// Lane pitches are root / 4th / 5th / octave of C. In game the Conductor
// transposes them to each stage's key (chart "sfx_key", in semitones), and
// those intervals fit both major and minor keys, so hits always sit in the music.

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SR = 44100;
const TAU = Math.PI * 2;
const mtof = m => 440 * Math.pow(2, (m - 69) / 12);

let seed = 12345;
const noise = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 2147483648 - 1; };

function render(seconds, fn) {
    const out = new Float32Array(Math.floor(seconds * SR));
    for (let i = 0; i < out.length; i++) out[i] = fn(i / SR, i);
    return out;
}

function normalize(buf, peak) {
    let m = 0;
    for (const v of buf) m = Math.max(m, Math.abs(v));
    const g = peak / m;
    for (let i = 0; i < buf.length; i++) buf[i] *= g;
    // tiny fade-out to avoid clicks
    const fade = Math.floor(0.01 * SR);
    for (let i = 0; i < fade; i++) buf[buf.length - 1 - i] *= i / fade;
    return buf;
}

function writeWav(name, samples) {
    const header = Buffer.alloc(44);
    const dataSize = samples.length * 2;
    header.write('RIFF', 0); header.writeUInt32LE(36 + dataSize, 4); header.write('WAVE', 8);
    header.write('fmt ', 12); header.writeUInt32LE(16, 16); header.writeUInt16LE(1, 20); header.writeUInt16LE(1, 22);
    header.writeUInt32LE(SR, 24); header.writeUInt32LE(SR * 2, 28); header.writeUInt16LE(2, 32); header.writeUInt16LE(16, 34);
    header.write('data', 36); header.writeUInt32LE(dataSize, 40);
    const data = Buffer.alloc(dataSize);
    for (let i = 0; i < samples.length; i++) {
        const s = Math.max(-1, Math.min(1, samples[i]));
        data.writeInt16LE(Math.round(s < 0 ? s * 32768 : s * 32767), i * 2);
    }
    const file = path.join(ROOT, 'assets/audio', name);
    fs.writeFileSync(file, Buffer.concat([header, data]));
    console.log('wrote', name, (samples.length / SR).toFixed(2) + 's');
}

// ---- Lane "tok": a woody mallet with a small pitch drop for punch and a
// snappy transient so it reads as a percussive hit, not a beep.
function tok(midi) {
    const f = mtof(midi);
    let prevN = 0;
    return normalize(render(0.32, t => {
        // phase with a quick downward pitch glide (6% -> 0)
        const ph = TAU * f * (t + (0.06 / 55) * (1 - Math.exp(-55 * t)));
        const body = Math.sin(ph) * Math.exp(-t * 16)
            + 0.45 * Math.sin(2 * ph) * Math.exp(-t * 28)
            + 0.18 * Math.sin(3.01 * ph) * Math.exp(-t * 45);
        const n = noise(); const hp = n - prevN; prevN = n;
        const snap = hp * Math.exp(-t * 260) * 0.55;
        return body + snap;
    }), 0.82);
}

// ---- Perfect layer: bright two-note "ting" an octave+ above the lane
// notes, plus a crisp three-stage hand-clap snap.
function perfectLayer() {
    const f1 = mtof(96), f2 = mtof(103); // C7 + G7
    let prevN = 0;
    return normalize(render(0.55, t => {
        const shimmer = 1 + 0.15 * Math.sin(TAU * 11 * t);
        const ting = (Math.sin(TAU * f1 * t) * 0.5 + Math.sin(TAU * f2 * t) * 0.35) * Math.exp(-t * 8) * shimmer;
        const n = noise(); const hp = n - prevN; prevN = n;
        let clapEnv = Math.exp(-t * 24) * 0.35;
        for (const d of [0, 0.009, 0.018]) if (t >= d) clapEnv += Math.exp(-(t - d) * 190) * 0.7;
        return ting * 0.55 + hp * clapEnv * 0.9;
    }), 0.62);
}

// ---- Miss: a short, sour downward "bwomp" (two slightly detuned voices
// sliding down an octave) with a quick vinyl-scratch rasp on top.
function miss() {
    let prevN = 0;
    const dur = 0.32;
    return normalize(render(dur, t => {
        const slide = (f0, f1) => {
            // exponential glide f0 -> f1 over 0.22s, phase integrated
            const k = Math.log(f1 / f0) / 0.22;
            const tt = Math.min(t, 0.22);
            let ph = f0 * (Math.exp(k * tt) - 1) / k;
            if (t > 0.22) ph += f1 * (t - 0.22);
            return TAU * ph;
        };
        const voice = p => Math.sin(p) + 0.35 * Math.sin(2 * p) + 0.15 * Math.sin(3 * p);
        const env = Math.min(1, t / 0.008) * Math.exp(-t * 7);
        const bwomp = (voice(slide(233, 110)) + 0.7 * voice(slide(247, 104))) * env;
        const n = noise(); const hp = n - prevN; prevN = n;
        const scratchEnv = t < 0.09 ? Math.sin(Math.PI * t / 0.09) : 0;
        const scratch = hp * scratchEnv * (0.5 + 0.5 * Math.sin(TAU * 38 * t)) * 0.35;
        return bwomp * 0.6 + scratch;
    }), 0.55);
}

const LANES = { left: 72, down: 77, up: 79, right: 84 }; // C5, F5, G5, C6
for (const [dir, midi] of Object.entries(LANES)) writeWav(`hit_${dir}.wav`, tok(midi));
writeWav('hit_perfect.wav', perfectLayer());
writeWav('miss.wav', miss());
