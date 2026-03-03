import AVFoundation

class SoundManager: NSObject, AVSpeechSynthesizerDelegate {
    private var engine: AVAudioEngine?
    private var musicPlayer: AVAudioPlayerNode?
    private var effectPlayer: AVAudioPlayerNode?
    private var format: AVAudioFormat?
    private let sampleRate: Double = 44100
    private var isPlaying = false
    private var currentTrack: GameTrack = .original
    private var activeSynthesizers: [AVSpeechSynthesizer] = []

    func setup() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default)
        try? session.setActive(true)

        let eng = AVAudioEngine()
        let music = AVAudioPlayerNode()
        let fx = AVAudioPlayerNode()
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        eng.attach(music)
        eng.attach(fx)
        eng.connect(music, to: eng.mainMixerNode, format: fmt)
        eng.connect(fx, to: eng.mainMixerNode, format: fmt)

        music.volume = 0.18
        fx.volume = 0.45

        engine = eng
        musicPlayer = music
        effectPlayer = fx
        format = fmt
    }

    func startMusic() {
        guard !isPlaying else { return }
        do {
            try engine?.start()
            musicPlayer?.play()
            effectPlayer?.play()
            isPlaying = true
        } catch { return }
        let track = currentTrack
        let player = musicPlayer
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self, let buffer = self.generateMusicLoop(track: track) else { return }
            player?.scheduleBuffer(buffer, at: nil, options: .loops)
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        effectPlayer?.stop()
        engine?.stop()
        isPlaying = false
    }

    // B6 - Switch music track
    func switchTrack(_ track: GameTrack) {
        currentTrack = track
        guard isPlaying else { return }
        musicPlayer?.stop()
        let player = musicPlayer
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self, let buffer = self.generateMusicLoop(track: track) else { return }
            player?.scheduleBuffer(buffer, at: nil, options: .loops)
            player?.play()
        }
    }

    func pauseMusic() {
        musicPlayer?.pause()
    }

    func resumeMusic() {
        musicPlayer?.play()
    }

    func setMusicVolume(_ volume: Float) {
        musicPlayer?.volume = volume
    }

    func playEffect(_ effect: SoundEffect) {
        guard let buffer = generateEffectBuffer(effect) else { return }
        effectPlayer?.scheduleBuffer(buffer, at: nil)
    }

    private func makeBuffer(duration: Double) -> (buffer: AVAudioPCMBuffer, data: UnsafeMutablePointer<Float>, frameCount: Int)? {
        let count = AVAudioFrameCount(sampleRate * duration)
        guard let fmt = format,
              let buffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: count) else { return nil }
        buffer.frameLength = count
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let n = Int(count)
        for i in 0..<n { data[i] = 0 }
        return (buffer, data, n)
    }

    private func generateMusicLoop(track: GameTrack) -> AVAudioPCMBuffer? {
        switch track {
        case .original:
            return generateOriginalLoop()
        case .jazz:
            return generateJazzLoop()
        case .electronic:
            return generateElectronicLoop()
        case .lofi:
            return generateLofiLoop()
        case .reggae:
            return generateReggaeLoop()
        case .hiphop:
            return generateHipHopLoop()
        case .latin:
            return generateLatinLoop()
        case .ambient:
            return generateAmbientLoop()
        }
    }

    private func generateOriginalLoop() -> AVAudioPCMBuffer? {
        let bpm: Double = 135
        let bars = 4
        let beatsPerBar = 4
        let totalBeats = bars * beatsPerBar
        let beatDur = 60.0 / bpm
        let totalDur = Double(totalBeats) * beatDur

        guard let (buffer, data, frameCount) = makeBuffer(duration: totalDur) else { return nil }

        let bassNotes: [(beat: Double, freq: Double)] = [
            (0, 130.8), (1, 130.8), (2, 164.8), (3, 196.0),
            (4, 130.8), (5, 164.8), (6, 196.0), (7, 164.8),
            (8, 110.0), (9, 130.8), (10, 164.8), (11, 196.0),
            (12, 130.8), (13, 196.0), (14, 164.8), (15, 130.8),
        ]
        for note in bassNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: beatDur * 0.7,
                    freq: note.freq, amp: 0.18, wave: .triangle)
        }

        let melodyNotes: [(beat: Double, freq: Double, dur: Double)] = [
            (0, 523.3, 0.5), (0.5, 659.3, 0.5),
            (2, 784.0, 1.0),
            (4, 523.3, 0.5), (4.5, 440.0, 0.5),
            (6, 392.0, 1.5),
            (8, 440.0, 0.5), (8.5, 523.3, 0.5),
            (10, 659.3, 1.0),
            (12, 392.0, 0.5), (12.5, 523.3, 0.5),
            (14, 440.0, 1.5),
        ]
        for note in melodyNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: note.dur * beatDur,
                    freq: note.freq, amp: 0.08, wave: .square)
        }

        for beat in 0..<totalBeats {
            addTone(to: data, frameCount: frameCount,
                    start: Double(beat) * beatDur, duration: 0.05,
                    freq: 8000, amp: 0.04, wave: .noise)

            if beat % 4 == 0 {
                addTone(to: data, frameCount: frameCount,
                        start: Double(beat) * beatDur, duration: 0.1,
                        freq: 55, amp: 0.25, wave: .sine)
            }
            if beat % 4 == 2 {
                addTone(to: data, frameCount: frameCount,
                        start: Double(beat) * beatDur, duration: 0.08,
                        freq: 200, amp: 0.12, wave: .noise)
            }

            addTone(to: data, frameCount: frameCount,
                    start: (Double(beat) + 0.5) * beatDur, duration: 0.03,
                    freq: 10000, amp: 0.025, wave: .noise)
        }

        return buffer
    }

    // B6 - Jazz: soft sine chords at 90 BPM
    private func generateJazzLoop() -> AVAudioPCMBuffer? {
        let bpm: Double = 90
        let totalBeats = 16
        let beatDur = 60.0 / bpm
        let totalDur = Double(totalBeats) * beatDur

        guard let (buffer, data, frameCount) = makeBuffer(duration: totalDur) else { return nil }

        // Chord progressions (major 7th style)
        let chords: [(beat: Double, freqs: [Double])] = [
            (0, [261.6, 329.6, 392.0, 493.9]),
            (4, [220.0, 277.2, 329.6, 415.3]),
            (8, [196.0, 246.9, 293.7, 369.9]),
            (12, [233.1, 293.7, 349.2, 440.0]),
        ]
        for chord in chords {
            for freq in chord.freqs {
                addTone(to: data, frameCount: frameCount,
                        start: chord.beat * beatDur, duration: beatDur * 3.5,
                        freq: freq, amp: 0.06, wave: .sine)
            }
        }

        // Soft walking bass
        let bassNotes: [(beat: Double, freq: Double)] = [
            (0, 65.4), (1, 73.4), (2, 82.4), (3, 87.3),
            (4, 55.0), (5, 65.4), (6, 73.4), (7, 82.4),
            (8, 49.0), (9, 55.0), (10, 61.7), (11, 65.4),
            (12, 58.3), (13, 65.4), (14, 73.4), (15, 82.4),
        ]
        for note in bassNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: beatDur * 0.8,
                    freq: note.freq, amp: 0.15, wave: .sine)
        }

        // Hi-hat on every beat
        for beat in 0..<totalBeats {
            addTone(to: data, frameCount: frameCount,
                    start: Double(beat) * beatDur, duration: 0.04,
                    freq: 7000, amp: 0.02, wave: .noise)
        }

        return buffer
    }

    // B6 - Electronic: square lead at 140 BPM
    private func generateElectronicLoop() -> AVAudioPCMBuffer? {
        let bpm: Double = 140
        let totalBeats = 16
        let beatDur = 60.0 / bpm
        let totalDur = Double(totalBeats) * beatDur

        guard let (buffer, data, frameCount) = makeBuffer(duration: totalDur) else { return nil }

        // Driving square bass
        let bassNotes: [(beat: Double, freq: Double)] = [
            (0, 110.0), (1, 110.0), (2, 130.8), (3, 146.8),
            (4, 110.0), (5, 164.8), (6, 130.8), (7, 110.0),
            (8, 98.0),  (9, 98.0),  (10, 110.0), (11, 130.8),
            (12, 110.0), (13, 130.8), (14, 164.8), (15, 110.0),
        ]
        for note in bassNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: beatDur * 0.5,
                    freq: note.freq, amp: 0.20, wave: .square)
        }

        // Neon synth lead
        let leadNotes: [(beat: Double, freq: Double, dur: Double)] = [
            (0, 523.3, 0.5), (1, 659.3, 0.5), (2, 784.0, 0.25), (2.25, 880.0, 0.75),
            (4, 659.3, 1.0), (5, 523.3, 0.5), (6, 440.0, 1.0),
            (8, 784.0, 0.5), (8.5, 698.5, 0.5), (9, 659.3, 1.0),
            (12, 523.3, 0.5), (12.5, 587.3, 0.5), (13, 659.3, 0.5), (14, 784.0, 1.5),
        ]
        for note in leadNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: note.dur * beatDur,
                    freq: note.freq, amp: 0.10, wave: .square)
        }

        // Hard kick on 1 and 3
        for beat in 0..<totalBeats {
            if beat % 4 == 0 || beat % 4 == 2 {
                addTone(to: data, frameCount: frameCount,
                        start: Double(beat) * beatDur, duration: 0.1,
                        freq: 55, amp: 0.30, wave: .sine)
            }
            // Clap on 2 and 4
            if beat % 4 == 1 || beat % 4 == 3 {
                addTone(to: data, frameCount: frameCount,
                        start: Double(beat) * beatDur, duration: 0.07,
                        freq: 500, amp: 0.14, wave: .noise)
            }
            // 16th hi-hats
            addTone(to: data, frameCount: frameCount,
                    start: Double(beat) * beatDur, duration: 0.03,
                    freq: 10000, amp: 0.03, wave: .noise)
            addTone(to: data, frameCount: frameCount,
                    start: (Double(beat) + 0.5) * beatDur, duration: 0.02,
                    freq: 9000, amp: 0.02, wave: .noise)
        }

        return buffer
    }

    // B6 - Lo-fi: muffled noise, slow beats at 75 BPM
    private func generateLofiLoop() -> AVAudioPCMBuffer? {
        let bpm: Double = 75
        let totalBeats = 16
        let beatDur = 60.0 / bpm
        let totalDur = Double(totalBeats) * beatDur

        guard let (buffer, data, frameCount) = makeBuffer(duration: totalDur) else { return nil }

        // Mellow bass chords
        let chords: [(beat: Double, freqs: [Double])] = [
            (0, [130.8, 164.8, 196.0]),
            (4, [110.0, 138.6, 164.8]),
            (8, [98.0, 123.5, 146.8]),
            (12, [116.5, 146.8, 174.6]),
        ]
        for chord in chords {
            for freq in chord.freqs {
                addTone(to: data, frameCount: frameCount,
                        start: chord.beat * beatDur, duration: beatDur * 3.8,
                        freq: freq, amp: 0.10, wave: .triangle)
            }
        }

        // Soft melody
        let melodyNotes: [(beat: Double, freq: Double, dur: Double)] = [
            (0, 392.0, 1.5), (2, 349.2, 1.0), (3, 329.6, 0.5),
            (4, 293.7, 2.0), (6, 261.6, 1.5),
            (8, 329.6, 1.5), (10, 293.7, 1.0), (11, 261.6, 0.5),
            (12, 220.0, 2.0), (14, 246.9, 1.5),
        ]
        for note in melodyNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: note.dur * beatDur,
                    freq: note.freq, amp: 0.07, wave: .sine)
        }

        // Muffled kick and snare
        for beat in 0..<totalBeats {
            if beat % 4 == 0 {
                addTone(to: data, frameCount: frameCount,
                        start: Double(beat) * beatDur, duration: 0.15,
                        freq: 60, amp: 0.18, wave: .sine)
            }
            if beat % 4 == 2 {
                addTone(to: data, frameCount: frameCount,
                        start: Double(beat) * beatDur, duration: 0.12,
                        freq: 300, amp: 0.08, wave: .noise)
            }
            // Quiet vinyl crackle
            addTone(to: data, frameCount: frameCount,
                    start: Double(beat) * beatDur, duration: beatDur,
                    freq: 4000, amp: 0.008, wave: .noise)
        }

        return buffer
    }

    private func generateEffectBuffer(_ effect: SoundEffect) -> AVAudioPCMBuffer? {
        switch effect {
        case .pickup:
            return generateChord(freqs: [523.3, 659.3, 784.0], duration: 0.25, amp: 0.2, wave: .sine)
        case .delivery:
            return generateArpeggio(freqs: [523.3, 659.3, 784.0, 1046.5], duration: 0.5, amp: 0.25, wave: .sine)
        case .crash:
            return generateChord(freqs: [150], duration: 0.2, amp: 0.35, wave: .noise)
        case .policeSiren:
            return generateSiren(freqLow: 600, freqHigh: 900, duration: 0.6, amp: 0.15)
        case .catMeow:
            return generateCatMeow()
        case .glassCrash:
            return generateGlassCrash()
        }
    }

    private func generateChord(freqs: [Double], duration: Double, amp: Float, wave: Waveform) -> AVAudioPCMBuffer? {
        guard let (buffer, data, frameCount) = makeBuffer(duration: duration) else { return nil }
        let perNote = amp / Float(freqs.count)
        for freq in freqs {
            addTone(to: data, frameCount: frameCount, start: 0, duration: duration, freq: freq, amp: perNote, wave: wave)
        }
        return buffer
    }

    private func generateArpeggio(freqs: [Double], duration: Double, amp: Float, wave: Waveform) -> AVAudioPCMBuffer? {
        let noteDur = duration / Double(freqs.count)
        guard let (buffer, data, frameCount) = makeBuffer(duration: duration) else { return nil }
        for (idx, freq) in freqs.enumerated() {
            addTone(to: data, frameCount: frameCount,
                    start: Double(idx) * noteDur, duration: noteDur * 0.9,
                    freq: freq, amp: amp, wave: wave)
        }
        return buffer
    }

    private func generateSiren(freqLow: Double, freqHigh: Double, duration: Double, amp: Float) -> AVAudioPCMBuffer? {
        guard let (buffer, data, frameCount) = makeBuffer(duration: duration) else { return nil }

        var phase: Double = 0
        for i in 0..<frameCount {
            let t = Double(i) / Double(frameCount)
            let freq = freqLow + (freqHigh - freqLow) * (0.5 + 0.5 * sin(t * .pi * 4))
            let envelope = Float(min(1, min(t * 20, (1 - t) * 8)))
            data[i] = Float(sin(phase * 2 * .pi)) * amp * envelope
            phase += freq / sampleRate
        }
        return buffer
    }

    private func addTone(to buffer: UnsafeMutablePointer<Float>, frameCount: Int,
                         start: Double, duration: Double,
                         freq: Double, amp: Float, wave: Waveform) {
        let startFrame = max(0, Int(start * sampleRate))
        let endFrame = min(Int((start + duration) * sampleRate), frameCount)
        guard endFrame > startFrame else { return }
        let total = endFrame - startFrame

        var phase: Double = 0
        let phaseInc = freq / sampleRate

        for i in startFrame..<endFrame {
            let t = Float(i - startFrame) / Float(total)
            let envelope = min(1, min(t * 40, (1 - t) * 12))

            let sample: Float
            switch wave {
            case .sine:
                sample = Float(sin(phase * 2 * .pi))
            case .square:
                let p = phase.truncatingRemainder(dividingBy: 1.0)
                sample = p < 0.5 ? 0.8 : -0.8
            case .triangle:
                let p = phase.truncatingRemainder(dividingBy: 1.0)
                sample = Float(4.0 * abs(p - 0.5) - 1.0)
            case .noise:
                sample = Float.random(in: -1...1)
            }

            buffer[i] += sample * amp * envelope
            phase += phaseInc
        }
    }

    // MARK: - New Music Tracks

    // Reggae: 80 BPM, offbeat skank guitar, walking bass, gentle hi-hats
    private func generateReggaeLoop() -> AVAudioPCMBuffer? {
        let bpm: Double = 80
        let totalBeats = 16
        let beatDur = 60.0 / bpm
        let totalDur = Double(totalBeats) * beatDur

        guard let (buffer, data, frameCount) = makeBuffer(duration: totalDur) else { return nil }

        // Walking bass on beats 1 and 3 of each bar (0-indexed: beat 0, 2, 4, 6, ...)
        let bassNotes: [(beat: Double, freq: Double)] = [
            (0, 82.4), (2, 87.3),
            (4, 73.4), (6, 82.4),
            (8, 65.4), (10, 73.4),
            (12, 77.8), (14, 87.3),
        ]
        for note in bassNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: beatDur * 0.7,
                    freq: note.freq, amp: 0.20, wave: .sine)
        }

        // Offbeat reggae skank: square chop on the "and" of beats 2 and 4
        // Per bar: offset 1.5 and 3.5 beats
        let skanksPerBar: [Double] = [0.5, 1.5, 2.5, 3.5]
        for bar in 0..<(totalBeats / 4) {
            for offset in skanksPerBar {
                // Only the "and" of 2 and 4 get the real chop (offbeat reggae feel)
                if offset == 1.5 || offset == 3.5 {
                    let beat = Double(bar * 4) + offset
                    // Chord skank: two square waves close in frequency for a richer chop
                    addTone(to: data, frameCount: frameCount,
                            start: beat * beatDur, duration: 0.08,
                            freq: 493.9, amp: 0.09, wave: .square)
                    addTone(to: data, frameCount: frameCount,
                            start: beat * beatDur, duration: 0.08,
                            freq: 392.0, amp: 0.07, wave: .square)
                } else {
                    // Lighter ghost strum on "and" of 1 and 3
                    let beat = Double(bar * 4) + offset
                    addTone(to: data, frameCount: frameCount,
                            start: beat * beatDur, duration: 0.06,
                            freq: 440.0, amp: 0.04, wave: .square)
                }
            }
        }

        // Gentle hi-hat noise on every quarter beat
        let quarterCount = totalBeats * 2
        for q in 0..<quarterCount {
            addTone(to: data, frameCount: frameCount,
                    start: Double(q) * beatDur * 0.5, duration: 0.03,
                    freq: 6000, amp: 0.015, wave: .noise)
        }

        // Slow, mellow melody: sine notes over 2-beat spans
        let melodyNotes: [(beat: Double, freq: Double, dur: Double)] = [
            (0, 329.6, 2.0), (2, 293.7, 1.5),
            (4, 261.6, 2.0), (6, 246.9, 1.5),
            (8, 293.7, 2.0), (10, 329.6, 1.5),
            (12, 261.6, 2.0), (14, 293.7, 1.8),
        ]
        for note in melodyNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: note.dur * beatDur,
                    freq: note.freq, amp: 0.07, wave: .sine)
        }

        return buffer
    }

    // Hip-Hop: 95 BPM, 808 kick, snare, trap hi-hats, syncopated bass
    private func generateHipHopLoop() -> AVAudioPCMBuffer? {
        let bpm: Double = 95
        let totalBeats = 16
        let beatDur = 60.0 / bpm
        let totalDur = Double(totalBeats) * beatDur

        guard let (buffer, data, frameCount) = makeBuffer(duration: totalDur) else { return nil }

        // 808 kick: deep sine boom on beats 0 and 2.5 of each bar
        for bar in 0..<(totalBeats / 4) {
            let barBase = Double(bar * 4)
            for kickOffset in [0.0, 2.5] {
                addTone(to: data, frameCount: frameCount,
                        start: (barBase + kickOffset) * beatDur, duration: 0.3,
                        freq: 50, amp: 0.30, wave: .sine)
            }
        }

        // Snare: noise burst on beats 1 and 3 of each bar
        for bar in 0..<(totalBeats / 4) {
            let barBase = Double(bar * 4)
            for snareOffset in [1.0, 3.0] {
                addTone(to: data, frameCount: frameCount,
                        start: (barBase + snareOffset) * beatDur, duration: 0.08,
                        freq: 800, amp: 0.20, wave: .noise)
            }
        }

        // Fast trap hi-hats: every 0.25 beats
        let hihatCount = totalBeats * 4
        for h in 0..<hihatCount {
            addTone(to: data, frameCount: frameCount,
                    start: Double(h) * beatDur * 0.25, duration: 0.03,
                    freq: 9000, amp: 0.02, wave: .noise)
        }

        // Syncopated bass line: square wave low frequencies
        let bassNotes: [(beat: Double, freq: Double, dur: Double)] = [
            (0, 90.0, 0.5), (0.75, 110.0, 0.3),
            (2, 98.0, 0.5), (2.75, 130.8, 0.3),
            (4, 90.0, 0.5), (4.5, 110.0, 0.4),
            (6, 98.0, 0.6), (7.0, 82.4, 0.3),
            (8, 90.0, 0.5), (8.75, 110.0, 0.3),
            (10, 98.0, 0.5), (10.5, 123.5, 0.3),
            (12, 90.0, 0.5), (12.75, 110.0, 0.3),
            (14, 98.0, 0.6), (15.0, 82.4, 0.5),
        ]
        for note in bassNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: note.dur * beatDur,
                    freq: note.freq, amp: 0.18, wave: .square)
        }

        // Melodic trap phrase: square notes, upper register
        let melodyNotes: [(beat: Double, freq: Double, dur: Double)] = [
            (0, 523.3, 0.25), (0.25, 587.3, 0.25), (0.5, 659.3, 0.5),
            (2, 587.3, 0.5), (2.5, 523.3, 0.5),
            (4, 440.0, 0.5), (4.5, 523.3, 0.25), (4.75, 587.3, 0.25),
            (6, 523.3, 1.0),
            (8, 659.3, 0.25), (8.25, 587.3, 0.25), (8.5, 523.3, 0.5),
            (10, 587.3, 0.5), (10.5, 440.0, 0.5),
            (12, 523.3, 0.5), (12.5, 587.3, 0.5),
            (14, 659.3, 1.5),
        ]
        for note in melodyNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: note.dur * beatDur,
                    freq: note.freq, amp: 0.09, wave: .square)
        }

        return buffer
    }

    // Latin: 120 BPM, clave pattern, brass stabs, bouncy bass
    private func generateLatinLoop() -> AVAudioPCMBuffer? {
        let bpm: Double = 120
        let totalBeats = 16
        let beatDur = 60.0 / bpm
        let totalDur = Double(totalBeats) * beatDur

        guard let (buffer, data, frameCount) = makeBuffer(duration: totalDur) else { return nil }

        // Clave pattern: sharp noise bursts (son clave 3-2: beats 0, 0.75, 1.5, 2.5, 3 per bar)
        let claveOffsets: [Double] = [0, 0.75, 1.5, 2.5, 3.0]
        for bar in 0..<(totalBeats / 4) {
            let barBase = Double(bar * 4)
            for offset in claveOffsets {
                addTone(to: data, frameCount: frameCount,
                        start: (barBase + offset) * beatDur, duration: 0.04,
                        freq: 2000, amp: 0.12, wave: .noise)
            }
        }

        // Bouncy bass: triangle wave, 4-beat pattern
        let bassNotes: [(beat: Double, freq: Double)] = [
            (0, 130.8), (1, 164.8), (2, 196.0), (3, 164.8),
            (4, 146.8), (5, 174.6), (6, 196.0), (7, 174.6),
            (8, 130.8), (9, 146.8), (10, 164.8), (11, 196.0),
            (12, 174.6), (13, 196.0), (14, 164.8), (15, 146.8),
        ]
        for note in bassNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: beatDur * 0.75,
                    freq: note.freq, amp: 0.17, wave: .triangle)
        }

        // Brass stabs: square wave chords on strong beats
        let brassBeats: [Double] = [0, 4, 8, 12]
        let brassFreqs: [Double] = [523.3, 659.3, 784.0]
        for beat in brassBeats {
            for freq in brassFreqs {
                addTone(to: data, frameCount: frameCount,
                        start: beat * beatDur, duration: 0.15,
                        freq: freq, amp: 0.06, wave: .square)
            }
        }

        // Melody: sine wave with fast runs (16th-note passages)
        let melodyNotes: [(beat: Double, freq: Double, dur: Double)] = [
            (0, 523.3, 0.25), (0.25, 587.3, 0.25), (0.5, 659.3, 0.25), (0.75, 698.5, 0.25),
            (1, 784.0, 0.5), (1.5, 698.5, 0.25), (1.75, 659.3, 0.25),
            (2, 587.3, 0.5), (2.5, 523.3, 0.5),
            (4, 659.3, 0.25), (4.25, 698.5, 0.25), (4.5, 784.0, 0.5),
            (5, 880.0, 0.5), (5.5, 784.0, 0.25), (5.75, 698.5, 0.25),
            (6, 659.3, 0.5), (6.5, 587.3, 0.5),
            (8, 523.3, 0.25), (8.25, 587.3, 0.25), (8.5, 659.3, 0.25), (8.75, 587.3, 0.25),
            (9, 523.3, 1.0),
            (12, 784.0, 0.25), (12.25, 698.5, 0.25), (12.5, 659.3, 0.25), (12.75, 587.3, 0.25),
            (13, 523.3, 0.5), (13.5, 440.0, 0.5),
            (14, 523.3, 1.5),
        ]
        for note in melodyNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: note.dur * beatDur,
                    freq: note.freq, amp: 0.08, wave: .sine)
        }

        return buffer
    }

    // Ambient: 60 BPM, slow pad chords, long melodic notes, atmospheric hiss
    private func generateAmbientLoop() -> AVAudioPCMBuffer? {
        let bpm: Double = 60
        let totalBeats = 16
        let beatDur = 60.0 / bpm
        let totalDur = Double(totalBeats) * beatDur

        guard let (buffer, data, frameCount) = makeBuffer(duration: totalDur) else { return nil }

        // Pad chords: 3-4 sine frequencies held for 4 beats each
        let padChords: [(beat: Double, freqs: [Double])] = [
            (0, [220.0, 261.6, 329.6, 392.0]),
            (4, [196.0, 246.9, 293.7, 369.9]),
            (8, [174.6, 220.0, 261.6, 329.6]),
            (12, [207.7, 261.6, 311.1, 392.0]),
        ]
        for chord in padChords {
            for freq in chord.freqs {
                addTone(to: data, frameCount: frameCount,
                        start: chord.beat * beatDur, duration: beatDur * 4.0,
                        freq: freq, amp: 0.05, wave: .sine)
            }
        }

        // Slow melody: long sine notes (2-3 beat duration)
        let melodyNotes: [(beat: Double, freq: Double, dur: Double)] = [
            (0, 392.0, 3.0),
            (3, 349.2, 2.0),
            (5, 329.6, 2.5),
            (8, 293.7, 3.0),
            (11, 329.6, 2.0),
            (13, 349.2, 3.0),
        ]
        for note in melodyNotes {
            addTone(to: data, frameCount: frameCount,
                    start: note.beat * beatDur, duration: note.dur * beatDur,
                    freq: note.freq, amp: 0.06, wave: .sine)
        }

        // Subtle atmospheric hiss: very low amplitude noise throughout
        addTone(to: data, frameCount: frameCount,
                start: 0, duration: totalDur,
                freq: 3000, amp: 0.005, wave: .noise)

        return buffer
    }

    // MARK: - New SFX

    // Cat meow: FM sine glide 600→900→500 Hz with triangle harmonic
    private func generateCatMeow() -> AVAudioPCMBuffer? {
        let duration = 0.6
        guard let (buffer, data, frameCount) = makeBuffer(duration: duration) else { return nil }

        var phase: Double = 0
        var harmPhase: Double = 0
        let rampUpEnd = Int(0.1 * sampleRate)
        let fadeStart = Int((duration - 0.15) * sampleRate)

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate

            // Frequency curve: glide up to 900 Hz in first 0.3s, then down to 500 Hz
            let freq: Double
            if t <= 0.3 {
                // Ease from 600 to 900 Hz
                let progress = t / 0.3
                freq = 600.0 + (900.0 - 600.0) * progress
            } else {
                // Ease from 900 to 500 Hz
                let progress = (t - 0.3) / 0.3
                freq = 900.0 - (900.0 - 500.0) * progress
            }

            // Amplitude envelope
            let env: Float
            if i < rampUpEnd {
                env = Float(i) / Float(rampUpEnd)
            } else if i >= fadeStart {
                env = Float(frameCount - i) / Float(frameCount - fadeStart)
            } else {
                env = 1.0
            }

            // Primary sine
            let mainSample = Float(sin(phase * 2 * .pi))

            // Triangle harmonic at half frequency, amp 0.04
            let harmFreq = freq * 0.5
            let hp = harmPhase.truncatingRemainder(dividingBy: 1.0)
            let harmSample = Float(4.0 * abs(hp - 0.5) - 1.0)

            data[i] += (mainSample * 0.25 + harmSample * 0.04) * env

            phase += freq / sampleRate
            harmPhase += harmFreq / sampleRate
        }

        return buffer
    }

    // Glass crash: initial noise impact + decaying high-freq tinkle
    private func generateGlassCrash() -> AVAudioPCMBuffer? {
        let duration = 0.5
        guard let (buffer, data, frameCount) = makeBuffer(duration: duration) else { return nil }

        let impactEnd = Int(0.05 * sampleRate)
        let tinkleEnd = frameCount

        // Part 1: initial noise impact
        for i in 0..<impactEnd {
            let t = Float(i) / Float(impactEnd)
            let env = 1.0 - t  // decay quickly
            data[i] += Float.random(in: -1...1) * 0.4 * env
        }

        // Part 2: decaying tinkle of high-freq noise bursts
        let burstInterval = Int(0.018 * sampleRate)  // ~18ms between bursts
        let burstLength = Int(0.008 * sampleRate)    // ~8ms each burst
        var burstStart = impactEnd
        while burstStart < tinkleEnd {
            let tinkleProgress = Float(burstStart - impactEnd) / Float(tinkleEnd - impactEnd)
            let decayAmp = 0.3 * (1.0 - tinkleProgress)
            let end = min(burstStart + burstLength, tinkleEnd)
            for i in burstStart..<end {
                data[i] += Float.random(in: -1...1) * decayAmp
            }
            burstStart += burstInterval + Int.random(in: 0...Int(0.005 * sampleRate))
        }

        return buffer
    }

    // MARK: - AVSpeechSynthesizer "Hey!"

    func speakHey() {
        let utterance = AVSpeechUtterance(string: "Hey! What's going on!")
        utterance.rate = 0.55
        utterance.pitchMultiplier = 1.2
        utterance.volume = 0.9
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        synthesizer.speak(utterance)
        activeSynthesizers.append(synthesizer)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        activeSynthesizers.removeAll { $0 === synthesizer }
    }
}
