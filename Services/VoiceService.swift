import Foundation
import Speech
import AVFoundation
import Combine

/// Enhanced Voice Service
/// Provides complete speech-to-text and text-to-speech capabilities
@MainActor
class VoiceService: NSObject, ObservableObject {
    static let shared = VoiceService()
    
    // Published properties for UI binding
    @Published private(set) var isListening = false
    @Published private(set) var isSpeaking = false
    @Published private(set) var recognizedText = ""
    @Published private(set) var audioLevel: Float = 0.0
    @Published private(set) var isAuthorized = false
    @Published private(set) var speechRecognitionAvailable = false
    @Published private(set) var currentLanguage = "en-US"
    @Published private(set) var isInitialized = false
    
    // Speech Recognition
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Text-to-Speech
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var speechQueue: [VoiceSpeechRequest] = []
    private var currentSpeechRequest: VoiceSpeechRequest?
    
    // Audio Session
    private var audioSession: AVAudioSession = .sharedInstance()
    
    // Voice Configuration
    @Published var voiceSettings = VoiceSettings()
    
    private override init() {
        super.init()
        // Don't initialize speech services immediately to avoid privacy crash
        // Only set up the synthesizer since it doesn't require permissions
        speechSynthesizer.delegate = self
        print("✅ VoiceService initialized (minimal setup)")
    }
    
    // MARK: - Lazy Initialization
    
    func initializeIfNeeded() async {
        guard !isInitialized else { return }
        
        await setupSpeechRecognition()
        await setupTextToSpeech()
        await setupAudioSession()
        
        isInitialized = true
        print("✅ VoiceService fully initialized")
    }
    
    // MARK: - Initialization
    
    private func setupSpeechRecognition() async {
        // Only set up speech recognizer, don't request authorization
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
        speechRecognizer?.delegate = self
        speechRecognitionAvailable = speechRecognizer?.isAvailable ?? false
        
        print("🎤 Speech recognizer setup complete (authorization not requested)")
    }
    
    private func setupTextToSpeech() async {
        await loadAvailableVoices()
        print("🔊 Text-to-speech setup complete")
    }
    
    private func setupAudioSession() async {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            print("🎵 Audio session configured")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Authorization (Manual)
    
    func requestSpeechRecognitionAuthorization() async -> Bool {
        await initializeIfNeeded()
        
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                DispatchQueue.main.async {
                    switch authStatus {
                    case .authorized:
                        self?.isAuthorized = true
                        print("✅ Speech recognition authorized")
                        continuation.resume(returning: true)
                    case .denied, .restricted, .notDetermined:
                        self?.isAuthorized = false
                        print("❌ Speech recognition not authorized: \(authStatus)")
                        continuation.resume(returning: false)
                    @unknown default:
                        self?.isAuthorized = false
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    // MARK: - Speech Recognition
    
    func startListening() async throws {
        await initializeIfNeeded()
        
        guard isAuthorized else {
            throw VoiceError.notAuthorized
        }
        
        guard !isListening else {
            print("⚠️ Already listening")
            return
        }
        
        // Cancel any ongoing recognition
        stopListening()
        
        // Configure and activate audio session for recording
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Failed to activate audio session: \(error)")
            throw VoiceError.audioEngineError
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.recognitionSetupFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = voiceSettings.preferOnDeviceRecognition
        
        // Setup audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
            
            // Update audio level for visualization
            self.updateAudioLevel(from: buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        guard let speechRecognizer = speechRecognizer else {
            throw VoiceError.recognizerNotAvailable
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.recognizedText = result.bestTranscription.formattedString
                    
                    // If final result, stop listening
                    if result.isFinal {
                        self?.stopListening()
                    }
                }
                
                if let error = error {
                    print("❌ Speech recognition error: \(error)")
                    self?.stopListening()
                }
            }
        }
        
        isListening = true
        recognizedText = ""
        print("🎤 Started listening...")
    }
    
    func stopListening() {
        guard isListening else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        audioLevel = 0.0
        
        // Reset audio session
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(false)
        } catch {
            print("❌ Failed to reset audio session: \(error)")
        }
        
        print("🔇 Stopped listening")
    }
    
    // MARK: - Text-to-Speech
    
    func speak(_ text: String, priority: SpeechPriority = .normal, completion: ((Bool) -> Void)? = nil) async {
        await initializeIfNeeded()
        
        let request = VoiceSpeechRequest(
            text: text,
            priority: priority,
            voice: voiceSettings.selectedVoice,
            rate: voiceSettings.speechRate,
            pitch: voiceSettings.pitch,
            volume: voiceSettings.volume,
            completion: completion
        )
        
        switch priority {
        case .immediate:
            // Stop current speech and speak immediately
            stopSpeaking()
            speechQueue.insert(request, at: 0)
        case .high:
            // Insert after current speech
            speechQueue.insert(request, at: 0)
        case .normal:
            // Add to end of queue
            speechQueue.append(request)
        }
        
        processNextSpeechRequest()
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechQueue.removeAll()
        currentSpeechRequest = nil
        isSpeaking = false
    }
    
    func pauseSpeaking() {
        speechSynthesizer.pauseSpeaking(at: .immediate)
    }
    
    func resumeSpeaking() {
        speechSynthesizer.continueSpeaking()
    }
    
    private func processNextSpeechRequest() {
        guard !isSpeaking, !speechQueue.isEmpty else { return }
        
        let request = speechQueue.removeFirst()
        currentSpeechRequest = request
        
        let utterance = AVSpeechUtterance(string: request.text)
        utterance.voice = request.voice
        utterance.rate = request.rate
        utterance.pitchMultiplier = request.pitch
        utterance.volume = request.volume
        
        // Apply voice effects if enabled
        if voiceSettings.useVoiceEffects {
            applyVoiceEffects(to: utterance)
        }
        
        isSpeaking = true
        speechSynthesizer.speak(utterance)
        
        print("🔊 Speaking: \(request.text.prefix(50))...")
    }
    
    private func applyVoiceEffects(to utterance: AVSpeechUtterance) {
        // Apply subtle voice modulation for AI personality
        switch voiceSettings.personalityVoice {
        case .neutral:
            break
        case .friendly:
            utterance.pitchMultiplier *= 1.1
            utterance.rate *= 0.95
        case .professional:
            utterance.pitchMultiplier *= 0.9
            utterance.rate *= 1.05
        case .expressive:
            utterance.pitchMultiplier *= 1.2
            utterance.rate *= 0.9
        }
    }
    
    // MARK: - Voice Commands
    
    func enableVoiceCommands() async {
        await initializeIfNeeded()
        // Set up voice command recognition patterns
        voiceSettings.enableVoiceCommands = true
        setupVoiceCommandRecognition()
    }
    
    private func setupVoiceCommandRecognition() {
        // This would set up specific phrase recognition for commands like:
        // "Hey Digital Court", "Stop speaking", "Repeat that", etc.
    }
    
    func processVoiceCommand(_ text: String) -> VoiceCommand? {
        let lowercasedText = text.lowercased()
        
        if lowercasedText.contains("stop") || lowercasedText.contains("quiet") {
            return .stopSpeaking
        } else if lowercasedText.contains("repeat") {
            return .repeatLast
        } else if lowercasedText.contains("louder") {
            return .increasVolume
        } else if lowercasedText.contains("quieter") || lowercasedText.contains("softer") {
            return .decreaseVolume
        } else if lowercasedText.contains("faster") {
            return .increaseSpeed
        } else if lowercasedText.contains("slower") {
            return .decreaseSpeed
        }
        
        return nil
    }
    
    // MARK: - Audio Level Monitoring
    
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0.0
        
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        
        let averageLevel = sum / Float(frameLength)
        let decibelLevel = 20 * log10(averageLevel)
        
        // Normalize to 0-1 range
        let normalizedLevel = max(0, min(1, (decibelLevel + 80) / 80))
        
        DispatchQueue.main.async {
            self.audioLevel = normalizedLevel
        }
    }
    
    // MARK: - Voice Configuration
    
    private func loadAvailableVoices() async {
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        await MainActor.run {
            voiceSettings.availableVoices = availableVoices
            
            // Set default voice based on system language
            if let defaultVoice = availableVoices.first(where: { $0.language == currentLanguage }) {
                voiceSettings.selectedVoice = defaultVoice
            } else if let firstVoice = availableVoices.first {
                voiceSettings.selectedVoice = firstVoice
            }
        }
    }
    
    func changeLanguage(_ languageCode: String) async {
        await initializeIfNeeded()
        currentLanguage = languageCode
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode))
        speechRecognitionAvailable = speechRecognizer?.isAvailable ?? false
        await loadAvailableVoices()
    }
    
    // MARK: - Conversation Mode
    
    func startConversationMode() async throws {
        await initializeIfNeeded()
        
        // Request authorization if not already done
        guard await requestSpeechRecognitionAuthorization() else {
            throw VoiceError.notAuthorized
        }
        
        voiceSettings.conversationMode = true
        try await startListening()
        
        // In conversation mode, automatically restart listening after speech
        NotificationCenter.default.addObserver(
            forName: .voiceServiceDidFinishSpeaking,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.voiceSettings.conversationMode == true {
                    try? await self.startListening()
                }
            }
        }
    }
    
    func stopConversationMode() {
        voiceSettings.conversationMode = false
        stopListening()
        stopSpeaking()
        
        NotificationCenter.default.removeObserver(self, name: .voiceServiceDidFinishSpeaking, object: nil)
    }
}

// MARK: - Speech Recognizer Delegate

extension VoiceService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            self.speechRecognitionAvailable = available
        }
    }
}

// MARK: - Speech Synthesizer Delegate

extension VoiceService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.currentSpeechRequest?.completion?(true)
            self.currentSpeechRequest = nil
            self.isSpeaking = false
            
            // Process next speech request
            self.processNextSpeechRequest()
            
            // Post notification for conversation mode
            NotificationCenter.default.post(name: .voiceServiceDidFinishSpeaking, object: nil)
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.currentSpeechRequest?.completion?(false)
            self.currentSpeechRequest = nil
            self.isSpeaking = false
        }
    }
}

// MARK: - Supporting Models

struct VoiceSettings {
    var selectedVoice: AVSpeechSynthesisVoice?
    var availableVoices: [AVSpeechSynthesisVoice] = []
    var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    var pitch: Float = 1.0
    var volume: Float = 1.0
    var preferOnDeviceRecognition = true
    var enableVoiceCommands = false
    var conversationMode = false
    var useVoiceEffects = true
    var personalityVoice: PersonalityVoice = .neutral
}

enum PersonalityVoice {
    case neutral
    case friendly
    case professional
    case expressive
}

enum SpeechPriority {
    case immediate  // Stop current speech and speak now
    case high      // Speak after current utterance
    case normal    // Add to queue
}

enum VoiceCommand {
    case stopSpeaking
    case repeatLast
    case increasVolume
    case decreaseVolume
    case increaseSpeed
    case decreaseSpeed
}

struct VoiceSpeechRequest {
    let text: String
    let priority: SpeechPriority
    let voice: AVSpeechSynthesisVoice?
    let rate: Float
    let pitch: Float
    let volume: Float
    let completion: ((Bool) -> Void)?
}

// MARK: - Voice Errors

enum VoiceError: Error, LocalizedError {
    case notAuthorized
    case recognitionSetupFailed
    case recognizerNotAvailable
    case audioEngineError
    case speechSynthesisError
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .recognitionSetupFailed:
            return "Failed to setup speech recognition"
        case .recognizerNotAvailable:
            return "Speech recognizer not available"
        case .audioEngineError:
            return "Audio engine error"
        case .speechSynthesisError:
            return "Speech synthesis error"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let voiceServiceDidFinishSpeaking = Notification.Name("voiceServiceDidFinishSpeaking")
    static let voiceServiceDidRecognizeText = Notification.Name("voiceServiceDidRecognizeText")
}