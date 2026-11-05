const fs = require('fs');
const path = require('path');

function createWavHeader(numSamples, sampleRate = 44100, numChannels = 1, bitsPerSample = 16) {
    const byteRate = sampleRate * numChannels * (bitsPerSample / 8);
    const blockAlign = numChannels * (bitsPerSample / 8);
    const dataSize = numSamples * (bitsPerSample / 8);
    const buffer = Buffer.alloc(44);

    buffer.write('RIFF', 0);
    buffer.writeUInt32LE(36 + dataSize, 4);
    buffer.write('WAVE', 8);
    buffer.write('fmt ', 12);
    buffer.writeUInt32LE(16, 16);
    buffer.writeUInt16LE(1, 20);
    buffer.writeUInt16LE(numChannels, 22);
    buffer.writeUInt32LE(sampleRate, 24);
    buffer.writeUInt32LE(byteRate, 28);
    buffer.writeUInt16LE(blockAlign, 32);
    buffer.writeUInt16LE(bitsPerSample, 34);
    buffer.write('data', 36);
    buffer.writeUInt32LE(dataSize, 40);

    return buffer;
}

function writeWav(filePath, samples, sampleRate = 44100) {
    const header = createWavHeader(samples.length, sampleRate);
    const data = Buffer.alloc(samples.length * 2);
    for (let i = 0; i < samples.length; i++) {
        let s = Math.max(-1, Math.min(1, samples[i]));
        let val = Math.round(s < 0 ? s * 32768 : s * 32767);
        data.writeInt16LE(val, i * 2);
    }
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, Buffer.concat([header, data]));
    console.log(`Generated ${filePath} (${samples.length} samples)`);
}

const sampleRate = 44100;

// 1. Click (woodblock count-in click)
{
    const duration = 0.08;
    const len = Math.floor(sampleRate * duration);
    const samples = new Float32Array(len);
    for (let i = 0; i < len; i++) {
        const t = i / sampleRate;
        const env = Math.exp(-t * 60);
        const tone = Math.sin(2 * Math.PI * 1200 * t) * 0.7 + Math.sin(2 * Math.PI * 2400 * t) * 0.3;
        samples[i] = tone * env * 0.9;
    }
    writeWav('assets/audio/click.wav', samples);
}

// 2. Clap / General Hit
{
    const duration = 0.16;
    const len = Math.floor(sampleRate * duration);
    const samples = new Float32Array(len);
    for (let i = 0; i < len; i++) {
        const t = i / sampleRate;
        let env = 0;
        if (t < 0.015) env += Math.exp(-t * 120) * 0.4;
        if (t > 0.01 && t < 0.035) env += Math.exp(-(t - 0.01) * 100) * 0.6;
        if (t > 0.02) env += Math.exp(-(t - 0.02) * 40) * 0.8;
        const noise = (Math.random() * 2 - 1);
        const pop = Math.sin(2 * Math.PI * 520 * t) * Math.exp(-t * 40);
        samples[i] = (noise * 0.75 + pop * 0.25) * env;
    }
    writeWav('assets/audio/clap.wav', samples);
}

// 3. Directional Lane Hits (distinct pitch per direction)
const dirPitches = {
    left: 220,   // Low punchy Red
    down: 330,   // Mid-low Blue
    up: 440,     // Bright Green
    right: 554   // High Orange
};

for (const [dir, freq] of Object.entries(dirPitches)) {
    const duration = 0.14;
    const len = Math.floor(sampleRate * duration);
    const samples = new Float32Array(len);
    for (let i = 0; i < len; i++) {
        const t = i / sampleRate;
        const env = Math.exp(-t * 32);
        const tone = Math.sin(2 * Math.PI * freq * t) * 0.7 + Math.sin(2 * Math.PI * freq * 2 * t) * 0.3;
        const click = (Math.random() * 2 - 1) * Math.exp(-t * 120) * 0.35;
        samples[i] = (tone + click) * env * 0.8;
    }
    writeWav(`assets/audio/hit_${dir}.wav`, samples);
}

// 4. Cartoon Bonk / Miss Sound
{
    const duration = 0.22;
    const len = Math.floor(sampleRate * duration);
    const samples = new Float32Array(len);
    for (let i = 0; i < len; i++) {
        const t = i / sampleRate;
        const env = Math.exp(-t * 18);
        const pitch = 220 * Math.exp(-t * 22) + 70;
        const tone = Math.sin(2 * Math.PI * pitch * t);
        const rattle = Math.sin(2 * Math.PI * (pitch * 1.4) * t) * 0.4;
        samples[i] = (tone + rattle) * env * 0.85;
    }
    writeWav('assets/audio/miss.wav', samples);
}

// 5. Backing Track at 100 BPM (Week 1)
{
    const bpm = 100;
    const beatSec = 60 / bpm;
    const totalMeasures = 14;
    const totalDuration = totalMeasures * 4 * beatSec;
    const len = Math.floor(sampleRate * totalDuration);
    const samples = new Float32Array(len);

    for (let i = 0; i < len; i++) {
        const t = i / sampleRate;
        const currentBeatFloat = t / beatSec;
        const measure = Math.floor(currentBeatFloat / 4);
        const beatInMeasure = currentBeatFloat % 4;
        const beatFrac = currentBeatFloat % 1;
        const beatTime = beatFrac * beatSec;

        let mix = 0;

        // Kick
        if (beatInMeasure < 0.2 || (beatInMeasure >= 2.0 && beatInMeasure < 2.2)) {
            const kt = (beatInMeasure < 1 ? beatInMeasure : beatInMeasure - 2.0) * beatSec;
            if (kt < 0.2) {
                const kEnv = Math.exp(-kt * 22);
                const kPitch = 120 * Math.exp(-kt * 30) + 45;
                mix += Math.sin(2 * Math.PI * kPitch * kt) * kEnv * 0.55;
            }
        }

        // Snare / clap
        if ((beatInMeasure >= 1.0 && beatInMeasure < 1.25) || (beatInMeasure >= 3.0 && beatInMeasure < 3.25)) {
            const st = (beatInMeasure >= 3.0 ? beatInMeasure - 3.0 : beatInMeasure - 1.0) * beatSec;
            if (st < 0.18) {
                const sEnv = Math.exp(-st * 25);
                const sNoise = (Math.random() * 2 - 1) * 0.35;
                const sTone = Math.sin(2 * Math.PI * 220 * st) * 0.3;
                mix += (sNoise + sTone) * sEnv * 0.5;
            }
        }

        // Hi-hat
        const eighthFrac = (currentBeatFloat * 2) % 1;
        const ht = eighthFrac * (beatSec / 2);
        if (ht < 0.05) {
            const hEnv = Math.exp(-ht * 80);
            const hNoise = (Math.random() * 2 - 1) * 0.2;
            mix += hNoise * hEnv;
        }

        // Bassline
        const bassFreqs = [110.0, 110.0, 130.81, 146.83, 98.0, 110.0, 130.81, 164.81];
        const bassFreq = bassFreqs[measure % bassFreqs.length];
        const bEnv = Math.exp(-beatTime * 4.5);
        const bass = (Math.sin(2 * Math.PI * bassFreq * t) + 0.3 * Math.sin(2 * Math.PI * bassFreq * 2 * t)) * bEnv * 0.28;
        mix += bass;

        // Faint keyboard chord
        const padChord = (measure % 2 === 0) ? [220, 261.6, 329.6] : [196, 246.9, 293.6];
        const pad = (Math.sin(2 * Math.PI * padChord[0] * t) +
                     Math.sin(2 * Math.PI * padChord[1] * t) +
                     Math.sin(2 * Math.PI * padChord[2] * t)) * 0.05;
        mix += pad;

        samples[i] = mix * 0.75;
    }
    writeWav('assets/audio/backing_100bpm.wav', samples);
}

// 6. Tutorial Music at 90 BPM ("Beats' Cardboard Drum Groove")
{
    const bpm = 90;
    const beatSec = 60 / bpm;
    const totalMeasures = 16;
    const totalDuration = totalMeasures * 4 * beatSec;
    const len = Math.floor(sampleRate * totalDuration);
    const samples = new Float32Array(len);

    for (let i = 0; i < len; i++) {
        const t = i / sampleRate;
        const currentBeatFloat = t / beatSec;
        const measure = Math.floor(currentBeatFloat / 4);
        const beatInMeasure = currentBeatFloat % 4;
        const beatFrac = currentBeatFloat % 1;
        const beatTime = beatFrac * beatSec;

        let mix = 0;

        // Cardboard Box Thump on every downbeat (hollow, funny box sound)
        if (beatFrac < 0.25) {
            const bt = beatFrac * beatSec;
            const bEnv = Math.exp(-bt * 20);
            const boxTone = Math.sin(2 * Math.PI * (90 * Math.exp(-bt * 15) + 50) * bt);
            const boxNoise = (Math.random() * 2 - 1) * 0.15 * Math.exp(-bt * 40);
            mix += (boxTone + boxNoise) * bEnv * 0.6;
        }

        // Stick tap on off-beats
        if (beatInMeasure >= 1.0 && beatInMeasure < 1.15 || beatInMeasure >= 3.0 && beatInMeasure < 3.15) {
            const st = (beatInMeasure >= 3.0 ? beatInMeasure - 3.0 : beatInMeasure - 1.0) * beatSec;
            const sEnv = Math.exp(-st * 50);
            const sTone = Math.sin(2 * Math.PI * 800 * st) * 0.4;
            mix += sTone * sEnv;
        }

        // Playful cartoon marimba melody
        const melodyNotes = [261.63, 293.66, 329.63, 392.00, 440.00, 392.00, 329.63, 293.66];
        const noteIdx = Math.floor(currentBeatFloat) % melodyNotes.length;
        const mFreq = melodyNotes[noteIdx];
        const mEnv = Math.exp(-beatTime * 6.0);
        const marimba = Math.sin(2 * Math.PI * mFreq * t) * mEnv * 0.25;
        mix += marimba;

        samples[i] = mix * 0.7;
    }
    writeWav('assets/audio/tutorial_music.wav', samples);
}

console.log('All audio generation complete!');
