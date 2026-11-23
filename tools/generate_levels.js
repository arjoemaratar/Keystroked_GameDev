// Generates every stage's chart (data/charts/<id>.json) and its original
// backing track (assets/audio/music_<id>.wav).
//
//   node tools/generate_levels.js            (run from the project folder)
//
// Each chart row is one 4/4 measure. The music is rendered so that measure 0 is
// the 4-beat count-in and measure N is chart row N-1, so the track's arrangement
// (drum fills, crashes, extra instruments) follows the chart's level changes.
// Beat 0 of the audio is exactly sample 0, so first_beat_offset_ms is 0.

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SR = 44100;

// ---------------------------------------------------------------- charts ---

const DIRS = { l: 'left', d: 'down', u: 'up', r: 'right' };

function parsePhrase(str) {
    return str.trim().split(/\s+/).map(tok => {
        if (tok === 'R') return { dir: 'rest', type: 'R' };
        const [type, d] = tok.split(':');
        return { dir: DIRS[d], type };
    });
}

// Each stage: 5 levels, each level = list of phrases. A phrase becomes a
// LISTEN row (rival shows it) followed by a PLAY row (you echo it).
const STAGES = {
    tutorial: {
        bpm: 90, title: "Beats' Extremely Normal Dance Lesson", sfxKey: 0, opponent: 'beats', style: 'tutorial', seed: 11,
        levels: [
            { listen: 'WATCH BEATS: LEFT ARROWS [<-]', play: 'YOUR TURN: PRESS LEFT [<-] OR [A] IN TIME!',
              phrases: ['Q:l Q:l Q:l Q:l', 'Q:r Q:r Q:r Q:r'] },
            { listen: 'WATCH BEATS: DOWN [v] AND UP [^]', play: 'YOUR TURN: DOWN [v] AND UP [^]!',
              phrases: ['Q:d Q:u Q:d Q:u', 'Q:l Q:r Q:l Q:r'] },
            { listen: 'WATCH BEATS: 4-WAY ARROW COMBO!', play: 'CLAP: HIT ALL 4 ARROWS IN ORDER!',
              phrases: ['Q:l Q:d Q:u Q:r', 'Q:r Q:u Q:d Q:l'] },
            { listen: "WATCH OUT FOR RESTS! (DON'T PRESS Zz)", play: 'SKIP THE RESTS - DO NOT PRESS!',
              phrases: ['Q:l R Q:r R', 'R Q:d R Q:u'] },
            { listen: "BEATS' FINALE: DOUBLE TAPS!", play: 'FINISH THE LESSON WITH STYLE!',
              phrases: ['Q:l E2:d E2:u Q:r', 'E2:l Q:d E2:r Q:u'] },
        ],
        hype: ['AGAIN! NICE AND STEADY!', 'YOU GOT THIS!', 'FEEL THE BEAT!'],
    },
    week1: {
        bpm: 100, title: 'Straight Time', sfxKey: -3, opponent: 'straight_man', style: 'straight', seed: 21,
        levels: [
            { listen: 'THE STRAIGHT MAN: PRECISE STEADY TIME', play: 'CLAP: MATCH HIS PERFECT TIMING!',
              phrases: ['Q:l Q:d Q:u Q:r', 'Q:r Q:u Q:d Q:l', 'Q:l Q:r Q:l Q:r'] },
            { listen: 'THE STRAIGHT MAN: EIGHTH NOTE PATTERNS', play: 'CLAP: KEEP THE GROOVE ROLLING!',
              phrases: ['E2:l Q:u E2:r Q:d', 'Q:d E2:u Q:d E2:l', 'E2:r Q:l E2:u Q:d'] },
            { listen: 'THE STRAIGHT MAN: SYNCED DOUBLE CUTS', play: 'ANSWER WITH FULL EXPRESSION!',
              phrases: ['E2:u E2:d Q:l Q:r', 'Q:l Q:r E2:d E2:u', 'E2:l E2:r E2:l Q:u'] },
            { listen: 'THE STRAIGHT MAN: THE FINAL CHALLENGE', play: 'PROVE HUMAN GROOVE BEATS PERFECT!',
              phrases: ['E2:l E2:d E2:u Q:r', 'E2:r E2:u E2:d Q:l', 'Q:u E2:l E2:r Q:d'] },
            { listen: 'THE STRAIGHT MAN: SIXTEENTH-NOTE RUSH HOUR', play: 'WAKE HIM UP! FULL SPEED!',
              phrases: ['E2:l E2:d E2:u E2:r', 'S4:l Q:d E2:u Q:r', 'E2:r E2:u S4:d Q:l'] },
        ],
        hype: ['STAY ON THE GRID!', 'TIGHT! AGAIN!', 'KEEP IT STRAIGHT!'],
    },
    week2: {
        bpm: 110, title: 'Swing Shuffle', sfxKey: -7, opponent: 'swing_queen', style: 'swing', seed: 31,
        levels: [
            { listen: 'SWING QUEEN: WARM UP THE BAND', play: 'CLAP: EASY, ON THE BEAT!',
              phrases: ['Q:l Q:d Q:u Q:r', 'Q:u Q:u Q:d Q:d', 'Q:l Q:r Q:u Q:d'] },
            { listen: 'SWING QUEEN: ONE TRIPLET (TRI-PO-LET)', play: 'CLAP: THREE EVEN TAPS IN ONE BEAT!',
              phrases: ['TR:l Q:d Q:u Q:r', 'Q:l Q:d TR:u Q:r', 'TR:d Q:l TR:r Q:u'] },
            { listen: 'SWING QUEEN: DOUBLE TRIPLETS', play: 'CLAP: ROLL THEM OUT!',
              phrases: ['TR:l TR:d Q:u Q:r', 'Q:u Q:d TR:l TR:r', 'TR:u Q:l TR:d Q:r'] },
            { listen: 'SWING QUEEN: THREES MEET TWOS', play: 'CLAP: SWITCH THE FEEL!',
              phrases: ['TR:l Q:d TR:u Q:r', 'TR:r TR:u TR:d Q:l', 'E2:l TR:d E2:u TR:r'] },
            { listen: 'SWING QUEEN: THE SHOWSTOPPER', play: 'BRING DOWN THE HOUSE!',
              phrases: ['TR:l TR:d TR:u Q:r', 'TR:r E2:u TR:d E2:l', 'TR:u TR:d TR:l TR:r'] },
        ],
        hype: ['SWING IT!', 'SMOOTH! AGAIN!', 'DON\'T RUSH THE THREES!'],
    },
    week3: {
        bpm: 120, title: 'Syncopated Chaos', sfxKey: 4, opponent: 'syncopator', style: 'sync', seed: 41,
        levels: [
            { listen: 'THE SYNCOPATOR: HOLES IN THE BEAT', play: 'CLAP: LEAVE THE RESTS EMPTY!',
              phrases: ['Q:l R Q:r R', 'Q:u Q:d R Q:u', 'R Q:l R Q:r'] },
            { listen: 'THE SYNCOPATOR: HIT THE "AND"', play: 'CLAP: WAIT... THEN TAP ON THE AND!',
              phrases: ['ER:l Q:d ER:u Q:r', 'Q:l ER:r Q:d ER:u', 'ER:d ER:u Q:l Q:r'] },
            { listen: 'THE SYNCOPATOR: OFF-BEAT ALLEY', play: 'CLAP: FIND THE GAPS!',
              phrases: ['Q:l ER:d R ER:u', 'ER:r Q:l ER:d R', 'ER:l ER:d ER:u Q:r'] },
            { listen: 'THE SYNCOPATOR: GALLOPS', play: 'CLAP: GALLOP WITH HIM!',
              phrases: ['SE:l Q:d ER:u Q:r', 'Q:u ES:d R ER:l', 'ES:r Q:u SE:l Q:d'] },
            { listen: 'THE SYNCOPATOR: TOTAL CHAOS', play: 'TAKE BACK THE DRUM!',
              phrases: ['ER:l SE:d ER:u ES:r', 'SE:u R ES:d ER:l', 'ER:r ER:l SE:u Q:d'] },
        ],
        hype: ['DON\'T FALL FOR IT!', 'COUNT THE GAPS!', 'OFF-BEAT HERO!'],
    },
    week4: {
        bpm: 125, title: 'Twin Polyrhythm', sfxKey: 2, opponent: 'twins', style: 'poly', seed: 51,
        levels: [
            { listen: 'QUAD: FOUR STRAIGHT TICKS', play: 'CLAP: MATCH QUAD!',
              phrases: ['Q:l Q:d Q:u Q:r', 'TR:l Q:d TR:u Q:r', 'E2:l TR:d E2:u TR:r'] },
            { listen: 'TRI: NOW THREES, THEN TWOS', play: 'CLAP: SWITCH BETWEEN THEM!',
              phrases: ['TR:l E2:d TR:u E2:r', 'E2:u TR:d E2:l TR:r', 'TR:d TR:u E2:l E2:r'] },
            { listen: 'THE TWINS: GEARS TURNING', play: 'CLAP: KEEP BOTH CLOCKS!',
              phrases: ['TR:l TR:d TR:u E2:r', 'S4:l Q:d TR:u Q:r', 'TR:r S4:u TR:d Q:l'] },
            { listen: 'THE TWINS: THREE AGAINST FOUR', play: 'CLAP: DON\'T LOSE COUNT!',
              phrases: ['TR:l S4:d TR:u Q:r', 'S4:r TR:u S4:d Q:l', 'TR:u ER:d TR:l ER:r'] },
            { listen: 'THE TWINS: CLOCKWORK FRENZY', play: 'WAKE THEM BOTH!',
              phrases: ['TR:l S4:d TR:u S4:r', 'S4:u TR:d S4:l TR:r', 'TR:l TR:r S4:d Q:u'] },
        ],
        hype: ['THREE! FOUR! THREE!', 'BOTH CLOCKS!', 'GEARS LOCKED IN!'],
    },
    finale: {
        bpm: 130, title: 'The Master Clock', sfxKey: 0, opponent: 'metronome', style: 'finale', seed: 61,
        levels: [
            { listen: 'THE METRONOME: TICK. TOCK.', play: 'CLAP: SHOW HIM A HUMAN BEAT!',
              phrases: ['Q:l Q:d Q:u Q:r', 'E2:l E2:r Q:u Q:d', 'ER:l Q:d ER:u Q:r'] },
            { listen: 'THE METRONOME: EVERY RHYTHM AT ONCE', play: 'CLAP: REMEMBER YOUR TRAINING!',
              phrases: ['TR:l Q:d E2:u Q:r', 'SE:l Q:d ES:u Q:r', 'R E2:l R E2:r'] },
            { listen: 'THE METRONOME: ACCELERATING GEARS', play: 'CLAP: STAY WITH HIM!',
              phrases: ['E2:l TR:d ER:u Q:r', 'S4:l Q:r S4:u Q:d', 'TR:u ER:d TR:l ER:r'] },
            { listen: 'THE METRONOME: PERFECT QUANTIZATION', play: 'CLAP: BREAK THE GRID!',
              phrases: ['SE:l ES:d TR:u Q:r', 'ER:r S4:u ER:d TR:l', 'E2:u TR:d S4:l Q:r'] },
            { listen: 'THE METRONOME: THE LAST TICK', play: 'STOP THE CLOCK!',
              phrases: ['S4:l TR:d S4:u TR:r', 'ES:r SE:u ER:d S4:l', 'TR:l S4:d TR:u Q:r'] },
        ],
        hype: ['TEMPO CITY IS WATCHING!', 'FEEL IT, DON\'T COUNT IT!', 'ALMOST THERE!'],
    },
};

function buildChart(id, st) {
    const rows = [];
    st.levels.forEach((lvl, li) => {
        lvl.phrases.forEach((p, pi) => {
            const tiles = parsePhrase(p);
            if (tiles.length !== 4) throw new Error(`${id} level ${li + 1} phrase "${p}" needs 4 tiles`);
            rows.push({ level: li + 1, phase: 'listen', instruction: lvl.listen, tiles });
            const playText = pi === 0 ? lvl.play : st.hype[(li + pi) % st.hype.length];
            rows.push({ level: li + 1, phase: 'play', instruction: playText, tiles });
        });
    });
    return {
        title: st.title,
        bpm: st.bpm,
        time_signature: [4, 4],
        first_beat_offset_ms: 0,
        sfx_key: st.sfxKey || 0, // semitones from C: hit sounds are transposed into the stage's key
        audio: `res://assets/audio/music_${id}.wav`,
        opponent: st.opponent,
        rows,
    };
}

// ----------------------------------------------------------------- synth ---

function makeRng(seed) {
    let s = seed >>> 0;
    return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; };
}
const mtof = m => 440 * Math.pow(2, (m - 69) / 12);
const TAU = Math.PI * 2;

class Mix {
    constructor(seconds, seed) {
        this.buf = new Float32Array(Math.ceil(seconds * SR));
        this.rand = makeRng(seed);
    }
    noise() { return this.rand() * 2 - 1; }
    // Adds fn(x) for x in [0, len) seconds starting at time t.
    add(t, len, fn) {
        const i0 = Math.round(t * SR);
        const n = Math.floor(len * SR);
        const b = this.buf;
        for (let i = 0; i < n; i++) {
            const j = i0 + i;
            if (j < 0) continue;
            if (j >= b.length) break;
            b[j] += fn(i / SR);
        }
    }
    // ---- drums
    kick(t, v = 1) {
        this.add(t, 0.38, x => {
            const ph = TAU * (48 * x + (115 / 32) * (1 - Math.exp(-32 * x)));
            const click = this.noise() * Math.exp(-x * 400) * 0.15;
            return (Math.sin(ph) * Math.exp(-x * 9) + click) * 0.85 * v;
        });
    }
    box(t, v = 1) { // cardboard-box thump (tutorial)
        this.add(t, 0.3, x => {
            const ph = TAU * (70 * x + (60 / 20) * (1 - Math.exp(-20 * x)));
            return (Math.sin(ph) * Math.exp(-x * 14) + this.noise() * 0.12 * Math.exp(-x * 45)) * 0.7 * v;
        });
    }
    snare(t, v = 1) {
        let prev = 0;
        this.add(t, 0.25, x => {
            const n = this.noise(); const hp = n - prev * 0.6; prev = n;
            return (hp * Math.exp(-x * 22) * 0.45 + Math.sin(TAU * 185 * x) * Math.exp(-x * 30) * 0.35) * v;
        });
    }
    clap(t, v = 1) {
        let prev = 0;
        this.add(t, 0.3, x => {
            const n = this.noise(); const hp = n - prev; prev = n;
            let e = Math.exp(-x * 18) * 0.5;
            for (const d of [0, 0.011, 0.022]) if (x >= d) e += Math.exp(-(x - d) * 160) * 0.6;
            return hp * e * 0.4 * v;
        });
    }
    stick(t, v = 1) { // rim / stick tap
        this.add(t, 0.08, x => (Math.sin(TAU * 820 * x) * 0.5 + Math.sin(TAU * 1650 * x) * 0.2) * Math.exp(-x * 60) * 0.5 * v);
    }
    hat(t, v = 1, open = false) {
        let prev = 0;
        const dec = open ? 11 : 85;
        this.add(t, open ? 0.35 : 0.07, x => {
            const n = this.noise(); const hp = n - prev; prev = n;
            return hp * Math.exp(-x * dec) * 0.16 * v;
        });
    }
    ride(t, v = 1) {
        let prev = 0;
        this.add(t, 0.5, x => {
            const n = this.noise(); const hp = n - prev; prev = n;
            const ping = Math.sin(TAU * 3200 * x) * 0.06 + Math.sin(TAU * 5100 * x) * 0.04;
            return (hp * 0.09 + ping) * Math.exp(-x * 7) * v;
        });
    }
    crash(t, v = 1) {
        let prev = 0;
        this.add(t, 2.2, x => {
            const n = this.noise(); const hp = n - prev; prev = n;
            return hp * Math.exp(-x * 2.2) * 0.17 * v;
        });
    }
    tick(t, v = 1, accent = false) { // metronome / clock tick
        const f = accent ? 2400 : 1700;
        this.add(t, 0.05, x => (Math.sin(TAU * f * x) + 0.4 * Math.sin(TAU * f * 2.3 * x)) * Math.exp(-x * 140) * 0.28 * v);
    }
    bell(t, midi, v = 1) { // cowbell/clock bell
        const f = mtof(midi);
        this.add(t, 0.6, x => (Math.sin(TAU * f * x) + 0.5 * Math.sin(TAU * f * 2.76 * x) * Math.exp(-x * 6) + 0.25 * Math.sin(TAU * f * 5.4 * x) * Math.exp(-x * 12)) * Math.exp(-x * 7) * 0.12 * v);
    }
    // ---- tones
    tone(t, dur, midi, v, type, rel = 0.06) {
        const f = mtof(midi);
        const atk = type === 'pad' ? 0.08 : (type === 'bass' ? 0.004 : 0.006);
        this.add(t, dur + rel, x => {
            let env = Math.min(1, x / atk);
            if (x > dur) env *= Math.max(0, 1 - (x - dur) / rel);
            const p = TAU * f * x;
            let s;
            switch (type) {
                case 'bass': s = (Math.sin(p) + 0.45 * Math.sin(2 * p) + 0.18 * Math.sin(3 * p)) * Math.exp(-x * 2.2); break;
                case 'sawbass': { s = 0; for (let k = 1; k <= 7; k++) s += Math.sin(k * p) / k * Math.exp(-x * k * 1.4); s *= 0.8; break; }
                case 'marimba': s = (Math.sin(p) + 0.25 * Math.sin(4 * p) * Math.exp(-x * 30)) * Math.exp(-x * 7); break;
                case 'pluck': { s = 0; for (let k = 1; k <= 6; k++) s += Math.sin(k * p) / k * Math.exp(-x * k * 4); s *= Math.exp(-x * 3.5); break; }
                case 'square': s = Math.tanh(2.5 * Math.sin(p)) * 0.6; break;
                case 'lead': { const vib = 0.5 * Math.sin(TAU * 5.5 * x) * Math.min(1, x / 0.25); s = 0; for (let k = 1; k <= 5; k++) s += Math.sin(k * (p + vib)) / (k * k) * 1.2; break; }
                case 'rhodes': s = Math.sin(p + 1.3 * Math.exp(-x * 3.5) * Math.sin(p)) * Math.exp(-x * 1.6); break;
                case 'organ': s = (Math.sin(p) + 0.5 * Math.sin(2 * p) + 0.3 * Math.sin(3 * p)) * 0.6; break;
                case 'pad': { s = 0; for (const det of [-0.004, 0.004]) { const q = p * (1 + det); for (let k = 1; k <= 4; k++) s += Math.sin(k * q) / (k * 1.6); } s *= 0.4; break; }
                case 'stab': { s = 0; for (let k = 1; k <= 6; k++) s += Math.sin(k * p) / k; s *= Math.exp(-x * 9) * 0.7; break; }
                default: s = Math.sin(p);
            }
            return s * env * v;
        });
    }
    chord(t, dur, notes, v, type, rel) { for (const m of notes) this.tone(t, dur, m, v / Math.sqrt(notes.length), type, rel); }
}

const QUALITY = { M: [0, 4, 7], m: [0, 3, 7], m7: [0, 3, 7, 10], 7: [0, 4, 7, 10], maj7: [0, 4, 7, 11] };

// Per-style musical settings (all original material)
const STYLE = {
    tutorial: { prog: [[48, 'M'], [53, 'M'], [55, 'M'], [48, 'M']], scale: [0, 2, 4, 7, 9], leadType: 'marimba', leadOct: 24, leadFrom: 2, chordType: 'marimba' },
    straight: { prog: [[45, 'm'], [41, 'M'], [48, 'M'], [43, 'M']], scale: [0, 2, 3, 5, 7, 8, 10], leadType: 'square', leadOct: 24, leadFrom: 3, chordType: 'organ' },
    swing: { prog: [[43, 'm7'], [48, '7'], [41, 'maj7'], [50, '7']], scale: [0, 2, 4, 5, 7, 9, 10], leadType: 'lead', leadOct: 24, leadFrom: 3, chordType: 'rhodes' },
    sync: { prog: [[40, 'm'], [48, 'M'], [50, 'M'], [47, 'm']], scale: [0, 2, 3, 5, 7, 9, 10], leadType: 'pluck', leadOct: 24, leadFrom: 2, chordType: 'pluck' },
    poly: { prog: [[38, 'm'], [46, 'M'], [43, 'm'], [45, 'M']], scale: [0, 2, 3, 5, 7, 8, 10], leadType: 'marimba', leadOct: 24, leadFrom: 2, chordType: 'pad' },
    finale: { prog: [[36, 'm'], [44, 'M'], [39, 'M'], [46, 'M']], scale: [0, 2, 3, 5, 7, 8, 10], leadType: 'lead', leadOct: 24, leadFrom: 2, chordType: 'pad' },
};

// Melody rhythm (beat positions within a bar) per style
const LEAD_RHYTHM = {
    tutorial: [0, 1, 2, 2.5, 3],
    straight: [0, 0.5, 1.5, 2, 2.5, 3.5],
    swing: [0, 2 / 3, 1, 1 + 2 / 3, 2.5, 3, 3 + 2 / 3],
    sync: [0, 0.75, 1.5, 2.25, 3, 3.5],
    poly: [0, 2 / 3, 4 / 3, 2, 2 + 2 / 3, 3 + 1 / 3],
    finale: [0, 0.5, 0.75, 1.5, 2, 2.5, 3, 3.25, 3.5],
};

function makeMotifs(style, rng) {
    const cfg = STYLE[style];
    const rhythm = LEAD_RHYTHM[style];
    return cfg.prog.map(([root, q]) => {
        const chordPcs = QUALITY[q].map(i => (root + i) % 12);
        const keyRoot = cfg.prog[0][0] % 12;
        const scalePcs = cfg.scale.map(s => (keyRoot + s) % 12);
        const base = cfg.prog[0][0] + cfg.leadOct;
        // candidate pitches in a 1.5 octave range
        const pool = [];
        for (let m = base - 3; m <= base + 16; m++) if (scalePcs.includes(m % 12)) pool.push(m);
        let idx = pool.findIndex(m => chordPcs.includes(m % 12));
        if (idx < 0) idx = 0;
        return rhythm.map((pos, i) => {
            const onStrong = Number.isInteger(pos);
            let step = Math.floor(rng() * 5) - 2; // -2..2
            idx = Math.max(0, Math.min(pool.length - 1, idx + step));
            if (onStrong) { // snap to a chord tone on strong beats
                let best = idx, bestD = 99;
                pool.forEach((m, k) => { if (chordPcs.includes(m % 12) && Math.abs(k - idx) < bestD) { bestD = Math.abs(k - idx); best = k; } });
                idx = best;
            }
            const next = rhythm[i + 1] !== undefined ? rhythm[i + 1] : 4;
            return { pos, len: Math.min(next - pos, 1) * 0.85, midi: pool[idx] };
        });
    });
}

function renderMusic(id, st, chart) {
    const style = st.style;
    const cfg = STYLE[style];
    const beat = 60 / st.bpm;
    const rows = chart.rows;
    const measures = 1 + rows.length + 2; // count-in + rows + outro
    const mix = new Mix(measures * 4 * beat + 2.5, st.seed);
    const rng = makeRng(st.seed * 7 + 3);
    const motifs = makeMotifs(style, rng);
    const T = (m, b) => (m * 4 + b) * beat;

    const levelOf = m => (m >= 1 && m <= rows.length ? rows[m - 1].level : 0);

    for (let m = 0; m < measures; m++) {
        const lvl = levelOf(m);
        const isIntro = m === 0;
        const isOutro = m > rows.length;
        const [root, q] = cfg.prog[(m - 1 + 400) % cfg.prog.length];
        const chordNotes = QUALITY[q].map(i => root + 12 + i);
        const nextLvl = levelOf(m + 1);
        const fill = !isIntro && !isOutro && (nextLvl > lvl || m === rows.length);
        const newSection = !isOutro && m >= 1 && lvl !== levelOf(m - 1);
        const phase = m >= 1 && m <= rows.length ? rows[m - 1].phase : '';

        if (isOutro) {
            if (m === rows.length + 1) {
                const [r0, q0] = cfg.prog[0];
                mix.kick(T(m, 0), 1);
                mix.crash(T(m, 0), 1.2);
                mix.chord(T(m, 0), 4 * beat, QUALITY[q0].map(i => r0 + 12 + i), 0.5, cfg.chordType === 'pluck' ? 'pad' : cfg.chordType, 1.2);
                mix.tone(T(m, 0), 3 * beat, r0, 0.5, 'bass', 0.6);
            }
            continue;
        }

        if (newSection && lvl >= 2) mix.crash(T(m, 0), 0.9);

        // ---------------- drums
        switch (style) {
            case 'tutorial':
                for (let b = 0; b < 4; b++) mix.box(T(m, b), isIntro ? 0.5 : 0.9);
                if (!isIntro) { mix.stick(T(m, 1), 1); mix.stick(T(m, 3), 1); }
                if (lvl >= 3) for (let b = 0; b < 4; b += 0.5) mix.hat(T(m, b), 0.7);
                if (lvl >= 5) for (let b = 0.25; b < 4; b += 0.5) mix.hat(T(m, b), 0.4);
                break;
            case 'straight':
                for (let b = 0; b < 4; b += 0.5) mix.hat(T(m, b), b % 1 === 0 ? 0.8 : 0.55);
                if (isIntro) break;
                mix.kick(T(m, 0)); mix.kick(T(m, 2));
                if (lvl >= 3) mix.kick(T(m, 2.5), 0.7);
                if (lvl >= 5) { mix.kick(T(m, 1.5), 0.6); for (let b = 0.25; b < 4; b += 0.5) mix.hat(T(m, b), 0.35); }
                mix.snare(T(m, 1)); mix.snare(T(m, 3));
                if (lvl >= 4) { mix.clap(T(m, 1), 0.7); mix.clap(T(m, 3), 0.7); }
                break;
            case 'swing':
                for (const b of [0, 1, 1 + 2 / 3, 2, 3, 3 + 2 / 3]) mix.ride(T(m, b), b % 1 === 0 ? 0.9 : 0.6);
                if (isIntro) break;
                mix.hat(T(m, 1), 0.8); mix.hat(T(m, 3), 0.8);
                mix.kick(T(m, 0), 0.6); mix.kick(T(m, 2), 0.45);
                if (lvl >= 2) { mix.stick(T(m, 1), 0.8); mix.stick(T(m, 3), 0.8); }
                if (lvl >= 3) { mix.snare(T(m, 2 + 2 / 3), 0.25); mix.snare(T(m, 3 + 2 / 3), 0.2); }
                if (lvl >= 5) { mix.kick(T(m, 1 + 2 / 3), 0.4); mix.snare(T(m, 3), 0.6); }
                break;
            case 'sync':
                for (const b of [0.5, 1.5, 2.5, 3.5]) mix.hat(T(m, b), 0.8, true);
                if (isIntro) break;
                mix.kick(T(m, 0)); mix.kick(T(m, 1.5), 0.8);
                if (lvl >= 3) mix.kick(T(m, 2.75), 0.7);
                mix.snare(T(m, 1)); mix.snare(T(m, 3));
                if (lvl >= 4) for (let b = 0; b < 4; b += 0.25) mix.hat(T(m, b), 0.3);
                if (lvl >= 5) mix.clap(T(m, 3.75), 0.8);
                break;
            case 'poly':
                for (let b = 0; b < 4; b += 0.5) mix.hat(T(m, b), 0.5);
                if (isIntro) break;
                mix.kick(T(m, 0)); mix.kick(T(m, 2));
                mix.snare(T(m, 1)); mix.snare(T(m, 3));
                // "Tri": a bell part in threes against the 4/4 drums
                { const step = lvl >= 4 ? 2 / 3 : 4 / 3; let k = 0; for (let b = 0; b < 3.99; b += step, k++) mix.bell(T(m, b), (k % 3 === 0 ? 86 : 81), 1); }
                if (lvl >= 2) for (let b = 0; b < 4; b++) mix.tick(T(m, b), 0.8, b === 0);
                if (lvl >= 5) for (let b = 0.25; b < 4; b += 0.5) mix.hat(T(m, b), 0.3);
                break;
            case 'finale':
                for (let b = 0; b < 4; b++) mix.tick(T(m, b), 1, b === 0);
                if (isIntro) break;
                for (let b = 0; b < 4; b++) mix.kick(T(m, b), b % 2 === 0 ? 1 : 0.8);
                mix.clap(T(m, 1)); mix.clap(T(m, 3));
                if (lvl >= 2) for (let b = 0; b < 4; b += 0.25) mix.hat(T(m, b), b % 0.5 === 0 ? 0.55 : 0.3);
                if (lvl >= 3) for (const b of [0.5, 1.5, 2.5, 3.5]) mix.hat(T(m, b), 0.6, true);
                break;
        }
        if (fill) { // snare fill into the next section
            for (let b = 3; b < 4; b += 0.25) mix.snare(T(m, b), 0.35 + (b - 3) * 0.5);
        }

        // ---------------- bass
        if (!isIntro) {
            const bassV = 0.55;
            switch (style) {
                case 'tutorial':
                    mix.tone(T(m, 0), beat * 0.9, root - 12, bassV, 'bass'); mix.tone(T(m, 2), beat * 0.9, root - 12 + 7, bassV, 'bass'); break;
                case 'straight':
                    if (lvl <= 2) { for (let b = 0; b < 4; b++) mix.tone(T(m, b), beat * 0.8, root - 12, bassV, 'bass'); }
                    else { for (let b = 0; b < 4; b += 0.5) mix.tone(T(m, b), beat * 0.4, root - 12 + (b % 1 ? 12 : 0), bassV * 0.9, 'bass'); }
                    break;
                case 'swing': { // walking bass
                    const nextRoot = cfg.prog[m % cfg.prog.length][0];
                    const third = QUALITY[q][1];
                    const walk = [root, root + third, root + 7, nextRoot + (nextRoot > root ? -1 : 1)];
                    walk.forEach((n, b) => mix.tone(T(m, b), beat * 0.85, n - 12, bassV, 'bass'));
                    break;
                }
                case 'sync':
                    [[0, 0], [0.75, 0], [1.5, 7], [2.5, 12], [3, 0], [3.5, 10]].forEach(([b, iv]) => mix.tone(T(m, b), beat * 0.4, root - 12 + iv, bassV, 'bass'));
                    break;
                case 'poly':
                    for (let b = 0; b < 4; b += 0.5) mix.tone(T(m, b), beat * 0.42, root - 12 + ((b * 2) % 2 ? 7 : 0), bassV * 0.85, 'bass');
                    break;
                case 'finale':
                    for (let b = 0; b < 4; b += 0.5) mix.tone(T(m, b), beat * 0.45, root - 12 + (b % 1 ? 12 : 0), bassV * 0.75, 'sawbass');
                    break;
            }
        } else {
            mix.tone(T(m, 0), beat * 3.5, root - 12, 0.3, 'bass', 0.3);
        }

        // ---------------- chords
        const chordFrom = style === 'tutorial' ? 4 : 2;
        if (!isIntro && lvl >= chordFrom) {
            switch (style) {
                case 'straight':
                    mix.chord(T(m, 0), beat * 3.9, chordNotes, 0.3, 'organ', 0.1);
                    if (lvl >= 4) for (const b of [1.5, 3.5]) mix.chord(T(m, b), beat * 0.3, chordNotes.map(n => n + 12), 0.3, 'stab', 0.05);
                    break;
                case 'swing':
                    for (const b of [0, 1 + 2 / 3, 3 + 2 / 3]) mix.chord(T(m, b), beat * 0.9, chordNotes, 0.4, 'rhodes', 0.15);
                    break;
                case 'sync':
                    for (const b of [0.5, 2, 2.5]) mix.chord(T(m, b), beat * 0.4, chordNotes.map(n => n + 12), 0.35, 'pluck', 0.08);
                    break;
                case 'tutorial':
                    for (const b of [0, 2]) mix.chord(T(m, b), beat * 1.5, chordNotes.map(n => n + 12), 0.3, 'marimba', 0.1);
                    break;
                default: // poly, finale
                    mix.chord(T(m, 0), beat * 3.95, chordNotes, style === 'finale' ? 0.32 : 0.26, 'pad', 0.15);
            }
        } else if (isIntro) {
            mix.chord(T(m, 0), beat * 3.8, chordNotes, 0.18, style === 'swing' ? 'rhodes' : 'pad', 0.2);
        }

        // ---------------- lead melody (call on LISTEN rows, answer on PLAY rows)
        if (!isIntro && lvl >= cfg.leadFrom) {
            const motif = motifs[(m - 1) % motifs.length];
            const answer = phase === 'play';
            motif.forEach((n, i) => {
                let midi = n.midi;
                if (answer && i === motif.length - 1) midi = root + cfg.leadOct + (QUALITY[q][0]); // resolve the answer
                if (answer && i % 2 === 1) midi += (style === 'swing' ? 0 : 12) * (lvl >= 5 ? 1 : 0);
                const v = style === 'finale' ? 0.22 : 0.26;
                mix.tone(T(m, n.pos), n.len * beat, midi, v, cfg.leadType, 0.05);
                if (lvl >= 5 && style !== 'swing') mix.tone(T(m, n.pos), n.len * beat, midi + 12, v * 0.35, cfg.leadType, 0.05);
            });
        }
    }

    // ---- master: soft clip and normalise to leave headroom for the hit sounds
    const b = mix.buf;
    let peak = 0;
    for (let i = 0; i < b.length; i++) { b[i] = Math.tanh(b[i] * 1.2); peak = Math.max(peak, Math.abs(b[i])); }
    const gain = 0.72 / peak;
    for (let i = 0; i < b.length; i++) b[i] *= gain;
    return { samples: b, seconds: b.length / SR };
}

function writeWav(filePath, samples) {
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
    fs.writeFileSync(filePath, Buffer.concat([header, data]));
}

// ------------------------------------------------------------------ main ---

const only = process.argv[2];
for (const [id, st] of Object.entries(STAGES)) {
    if (only && only !== id) continue;
    const chart = buildChart(id, st);
    fs.writeFileSync(path.join(ROOT, 'data/charts', `${id}.json`), JSON.stringify(chart, null, 2) + '\n');
    const { samples, seconds } = renderMusic(id, st, chart);
    writeWav(path.join(ROOT, 'assets/audio', `music_${id}.wav`), samples);
    const playSec = (1 + chart.rows.length) * 4 * 60 / st.bpm;
    console.log(`${id}: ${chart.rows.length} rows, ${st.bpm} BPM, gameplay ${playSec.toFixed(1)}s, track ${seconds.toFixed(1)}s`);
}
