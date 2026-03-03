import AVFoundation

class SoundManager {
    private var engine: AVAudioEngine?
    private var musicPlayer: AVAudioPlayerNode?
    private var effectPlayer: AVAudioPlayerNode?
    private var format: AVAudioFormat?
    private let sampleRate: Double = 44100
    private var isPlaying = false

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
            if let buffer = generateMusicLoop() {
                musicPlayer?.scheduleBuffer(buffer, at: nil, options: .loops)
            }
            isPlaying = true
        } catch {}
    }

    func stopMusic() {
        musicPlayer?.stop()
        effectPlayer?.stop()
        engine?.stop()
        isPlaying = false
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

    private func generateMusicLoop() -> AVAudioPCMBuffer? {
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
}
