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
    buffer.writeUInt32LE(16, 16); // Subchunk1Size (16 for PCM)
    buffer.writeUInt16LE(1, 20);  // AudioFormat (1 = PCM)
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

// 1. Click (Woodblock / metronome click, 0.08s)
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

// 2. Clap (Rhythmic hand clap, multi-burst noise + pop, 0.18s)
{
    const duration = 0.18;
    const len = Math.floor(sampleRate * duration);
    const samples = new Float32Array(len);
    for (let i = 0; i < len; i++) {
        const t = i / sampleRate;
        // multiple rapid bursts for realism
        let env = 0;
        if (t < 0.015) env += Math.exp(-t * 120) * 0.4;
        if (t > 0.01 && t < 0.035) env += Math.exp(-(t - 0.01) * 100) * 0.6;
        if (t > 0.02) env += Math.exp(-(t - 0.02) * 35) * 0.8;
        
        const noise = (Math.random() * 2 - 1);
        const pop = Math.sin(2 * Math.PI * 450 * t) * Math.exp(-t * 40);
        samples[i] = (noise * 0.75 + pop * 0.25) * env;
    }
    writeWav('assets/audio/clap.wav', samples);
}

// 3. Miss Thud (dull error thunk, 0.2s)
{
    const duration = 0.20;
    const len = Math.floor(sampleRate * duration);
    const samples = new Float32Array(len);
    for (let i = 0; i < len; i++) {
        const t = i / sampleRate;
        const env = Math.exp(-t * 25);
        const pitch = 130 * Math.exp(-t * 15);
        const tone = Math.sin(2 * Math.PI * pitch * t);
        const noise = (Math.random() * 2 - 1) * 0.2 * Math.exp(-t * 40);
        samples[i] = (tone + noise) * env * 0.7;
    }
    writeWav('assets/audio/miss.wav', samples);
}

// 4. Backing Track at 100 BPM
// 100 BPM -> beat = 0.6s. 4 beats/measure = 2.4s.
// Total measures: 1 count-in + 8 rows (each 1 measure) + 2 outro = 11 measures = 26.4s
{
    const bpm = 100;
    const beatSec = 60 / bpm;
    const totalMeasures = 12;
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

        // Kick on beat 1 and 3
        if (beatInMeasure < 0.2 || (beatInMeasure >= 2.0 && beatInMeasure < 2.2)) {
            const kt = (beatInMeasure < 1 ? beatInMeasure : beatInMeasure - 2.0) * beatSec;
            if (kt < 0.2) {
                const kEnv = Math.exp(-kt * 22);
                const kPitch = 120 * Math.exp(-kt * 30) + 45;
                mix += Math.sin(2 * Math.PI * kPitch * kt) * kEnv * 0.55;
            }
        }

        // Snare / rimshot on beat 2 and 4
        if ((beatInMeasure >= 1.0 && beatInMeasure < 1.25) || (beatInMeasure >= 3.0 && beatInMeasure < 3.25)) {
            const st = (beatInMeasure >= 3.0 ? beatInMeasure - 3.0 : beatInMeasure - 1.0) * beatSec;
            if (st < 0.18) {
                const sEnv = Math.exp(-st * 25);
                const sNoise = (Math.random() * 2 - 1) * 0.35;
                const sTone = Math.sin(2 * Math.PI * 220 * st) * 0.3;
                mix += (sNoise + sTone) * sEnv * 0.5;
            }
        }

        // Hi-hat on every eighth note (0.0 and 0.5 of each beat)
        const eighthFrac = (currentBeatFloat * 2) % 1;
        const ht = eighthFrac * (beatSec / 2);
        if (ht < 0.05) {
            const hEnv = Math.exp(-ht * 80);
            const hNoise = (Math.random() * 2 - 1) * 0.22;
            mix += hNoise * hEnv;
        }

        // Funky bassline notes (root notes at 110Hz, 130Hz, 98Hz etc. synced to measures)
        const bassFreqs = [110.0, 110.0, 130.81, 146.83, 98.0, 110.0, 130.81, 164.81];
        const bassFreq = bassFreqs[measure % bassFreqs.length];
        const bEnv = Math.exp(-beatTime * 4.5);
        const bass = (Math.sin(2 * Math.PI * bassFreq * t) + 0.3 * Math.sin(2 * Math.PI * bassFreq * 2 * t)) * bEnv * 0.28;
        mix += bass;

        // Faint chord pad warmth
        const padChord = (measure % 2 === 0) ? [220, 261.6, 329.6] : [196, 246.9, 293.6];
        const pad = (Math.sin(2 * Math.PI * padChord[0] * t) +
                     Math.sin(2 * Math.PI * padChord[1] * t) +
                     Math.sin(2 * Math.PI * padChord[2] * t)) * 0.05;
        mix += pad;

        samples[i] = mix * 0.75;
    }
    writeWav('assets/audio/backing_100bpm.wav', samples);
}
console.log('Audio generation complete!');
