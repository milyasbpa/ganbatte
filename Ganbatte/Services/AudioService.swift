import Foundation
import AVFoundation

final class AudioService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = AudioService()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var japaneseVoice: AVSpeechSynthesisVoice?
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        setupVoice()
    }
    
    private func setupVoice() {
        // Prefer enhanced or premium Japanese voices if installed, otherwise default ja-JP
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "ja-JP" }
        if let enhanced = voices.first(where: { $0.quality == .enhanced }) {
            japaneseVoice = enhanced
        } else {
            japaneseVoice = AVSpeechSynthesisVoice(language: "ja-JP")
        }
    }
    
    func speak(_ text: String, rate: Float = 0.45) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        #endif
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = japaneseVoice ?? AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
