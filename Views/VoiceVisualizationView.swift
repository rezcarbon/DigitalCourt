import SwiftUI
internal import AVFAudio

struct VoiceVisualizationView: View {
    @StateObject private var voiceService = VoiceService.shared
    @State private var animationAmount = 1.0
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Voice Status Header
            HStack {
                Image(systemName: voiceService.isListening ? "mic.fill" : voiceService.isSpeaking ? "speaker.wave.3.fill" : "mic.slash.fill")
                    .font(.title2)
                    .foregroundColor(statusColor)
                
                Text(statusText)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                if voiceService.voiceSettings.conversationMode {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(pulseAnimation ? 360 : 0))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: pulseAnimation)
                }
            }
            
            // Audio Visualization
            if voiceService.isListening {
                listeningVisualization
            } else if voiceService.isSpeaking {
                speakingVisualization
            } else {
                idleVisualization
            }
            
            // Recognized Text Display
            if !voiceService.recognizedText.isEmpty {
                recognizedTextView
            }
            
            // Voice Controls
            voiceControlsView
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: statusColor.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private var statusColor: Color {
        if voiceService.isListening {
            return .red
        } else if voiceService.isSpeaking {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var statusText: String {
        if voiceService.isListening {
            return "Listening..."
        } else if voiceService.isSpeaking {
            return "Speaking..."
        } else if !voiceService.isAuthorized {
            return "Authorization Required"
        } else if !voiceService.speechRecognitionAvailable {
            return "Speech Recognition Unavailable"
        } else {
            return "Ready"
        }
    }
    
    private var listeningVisualization: some View {
        HStack(spacing: 4) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 4)
                    .frame(height: CGFloat.random(in: 10...60) * CGFloat((1 + CGFloat(voiceService.audioLevel))))
                    .animation(.easeInOut(duration: 0.3).repeatForever(), value: voiceService.audioLevel)
            }
        }
        .frame(height: 80)
    }
    
    private var speakingVisualization: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 12, height: 12)
                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.1), value: pulseAnimation)
            }
        }
        .frame(height: 80)
    }
    
    private var idleVisualization: some View {
        Image(systemName: "waveform")
            .font(.system(size: 40))
            .foregroundColor(.gray.opacity(0.5))
            .frame(height: 80)
    }
    
    private var recognizedTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recognized:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ScrollView {
                Text(voiceService.recognizedText)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 100)
        }
    }
    
    private var voiceControlsView: some View {
        VStack(spacing: 12) {
            // Authorization Required Message
            if !voiceService.isAuthorized {
                VStack(spacing: 8) {
                    Text("🎤 Voice Features Require Permission")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Tap the button below to enable speech recognition and microphone access.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("Enable Voice Features") {
                        Task {
                            let _ = await voiceService.requestSpeechRecognitionAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            } else {
                // Primary Controls (only show when authorized)
                HStack(spacing: 20) {
                    // Listen Button
                    Button(action: {
                        if voiceService.isListening {
                            voiceService.stopListening()
                        } else {
                            Task {
                                try? await voiceService.startListening()
                            }
                        }
                    }) {
                        Image(systemName: voiceService.isListening ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(voiceService.isListening ? .red : .blue)
                    }
                    .disabled(!voiceService.speechRecognitionAvailable)
                    
                    // Speak Button
                    Button(action: {
                        if voiceService.isSpeaking {
                            voiceService.stopSpeaking()
                        } else {
                            Task {
                                await voiceService.speak("Hello! I'm ready to assist you.", priority: .immediate)
                            }
                        }
                    }) {
                        Image(systemName: voiceService.isSpeaking ? "stop.circle.fill" : "speaker.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(voiceService.isSpeaking ? .red : .green)
                    }
                    
                    // Conversation Mode Button
                    Button(action: {
                        if voiceService.voiceSettings.conversationMode {
                            voiceService.stopConversationMode()
                        } else {
                            Task {
                                try? await voiceService.startConversationMode()
                            }
                        }
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(voiceService.voiceSettings.conversationMode ? .purple : .gray)
                    }
                    .disabled(!voiceService.speechRecognitionAvailable)
                }
                
                // Secondary Controls
                HStack(spacing: 15) {
                    // Pause/Resume Speaking
                    if voiceService.isSpeaking {
                        Button("Pause") {
                            voiceService.pauseSpeaking()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Resume") {
                            voiceService.resumeSpeaking()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }
}

// MARK: - Voice Settings View

struct VoiceSettingsView: View {
    @StateObject private var voiceService = VoiceService.shared
    @State private var testText = "Hello! This is a voice test. How do I sound?"
    @State private var showingAuthorizationAlert = false
    @State private var authorizationMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Speech Recognition")) {
                HStack {
                    Text("Authorization Status")
                    Spacer()
                    Text(voiceService.isAuthorized ? "✅ Authorized" : "❌ Not Authorized")
                        .foregroundColor(voiceService.isAuthorized ? .green : .red)
                }
                
                if !voiceService.isAuthorized {
                    Button("Request Speech Recognition Permission") {
                        requestSpeechAuthorization()
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.white)
                }
                
                HStack {
                    Text("Recognition Available")
                    Spacer()
                    Text(voiceService.speechRecognitionAvailable ? "✅ Available" : "❌ Unavailable")
                        .foregroundColor(voiceService.speechRecognitionAvailable ? .green : .red)
                }
                
                if !voiceService.speechRecognitionAvailable {
                    Text("Speech recognition may not be available on this device or in this region.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Toggle("Prefer On-Device Recognition", isOn: .init(
                    get: { voiceService.voiceSettings.preferOnDeviceRecognition },
                    set: { voiceService.voiceSettings.preferOnDeviceRecognition = $0 }
                ))
                .disabled(!voiceService.isAuthorized)
                
                Toggle("Enable Voice Commands", isOn: .init(
                    get: { voiceService.voiceSettings.enableVoiceCommands },
                    set: { 
                        voiceService.voiceSettings.enableVoiceCommands = $0
                        if $0 {
                            Task {
                                await voiceService.enableVoiceCommands()
                            }
                        }
                    }
                ))
                .disabled(!voiceService.isAuthorized)
            }
            
            Section(header: Text("Microphone Access")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Microphone access is required for speech recognition.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !voiceService.isAuthorized {
                        Text("To enable voice features:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("1. Tap 'Request Speech Recognition Permission' above")
                            .font(.caption)
                        Text("2. Allow microphone access when prompted")
                            .font(.caption)
                        Text("3. Allow speech recognition when prompted")
                            .font(.caption)
                    }
                }
            }
            
            Section(header: Text("Text-to-Speech")) {
                if !voiceService.voiceSettings.availableVoices.isEmpty {
                    Picker("Voice", selection: .init(
                        get: { voiceService.voiceSettings.selectedVoice ?? voiceService.voiceSettings.availableVoices.first! },
                        set: { voiceService.voiceSettings.selectedVoice = $0 }
                    )) {
                        ForEach(voiceService.voiceSettings.availableVoices, id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))")
                                .tag(voice)
                        }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Speech Rate: \(voiceService.voiceSettings.speechRate, specifier: "%.2f")")
                    Slider(value: .init(
                        get: { voiceService.voiceSettings.speechRate },
                        set: { voiceService.voiceSettings.speechRate = $0 }
                    ), in: 0.1...1.0)
                }
                
                VStack(alignment: .leading) {
                    Text("Pitch: \(voiceService.voiceSettings.pitch, specifier: "%.2f")")
                    Slider(value: .init(
                        get: { voiceService.voiceSettings.pitch },
                        set: { voiceService.voiceSettings.pitch = $0 }
                    ), in: 0.5...2.0)
                }
                
                VStack(alignment: .leading) {
                    Text("Volume: \(voiceService.voiceSettings.volume, specifier: "%.2f")")
                    Slider(value: .init(
                        get: { voiceService.voiceSettings.volume },
                        set: { voiceService.voiceSettings.volume = $0 }
                    ), in: 0.1...1.0)
                }
                
                Picker("Personality Voice", selection: .init(
                    get: { voiceService.voiceSettings.personalityVoice },
                    set: { voiceService.voiceSettings.personalityVoice = $0 }
                )) {
                    Text("Neutral").tag(PersonalityVoice.neutral)
                    Text("Friendly").tag(PersonalityVoice.friendly)
                    Text("Professional").tag(PersonalityVoice.professional)
                    Text("Expressive").tag(PersonalityVoice.expressive)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Toggle("Use Voice Effects", isOn: .init(
                    get: { voiceService.voiceSettings.useVoiceEffects },
                    set: { voiceService.voiceSettings.useVoiceEffects = $0 }
                ))
            }
            
            Section(header: Text("Test Voice")) {
                TextField("Test Text", text: $testText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Test Voice") {
                    Task {
                        await voiceService.speak(testText, priority: .immediate)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if voiceService.isSpeaking {
                    Button("Stop Test") {
                        voiceService.stopSpeaking()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Language")) {
                Text("Current: \(voiceService.currentLanguage)")
                
                Button("Change Language") {
                    Task {
                        await voiceService.changeLanguage("en-US")
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Section(header: Text("Troubleshooting")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If voice features aren't working:")
                        .fontWeight(.medium)
                    
                    Text("• Check that microphone access is enabled in Settings > Privacy & Security > Microphone")
                        .font(.caption)
                    
                    Text("• Check that speech recognition is enabled in Settings > Privacy & Security > Speech Recognition")
                        .font(.caption)
                    
                    Text("• Restart the app after granting permissions")
                        .font(.caption)
                    
                    Text("• Ensure you have a stable internet connection (for cloud-based recognition)")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Voice Settings")
        .alert("Speech Recognition", isPresented: $showingAuthorizationAlert) {
            Button("OK") { }
        } message: {
            Text(authorizationMessage)
        }
        .task {
            // Initialize voice service when view appears
            await voiceService.initializeIfNeeded()
        }
    }
    
    private func requestSpeechAuthorization() {
        Task {
            let authorized = await voiceService.requestSpeechRecognitionAuthorization()
            
            await MainActor.run {
                if authorized {
                    authorizationMessage = "Speech recognition has been authorized! You can now use voice features."
                } else {
                    authorizationMessage = "Speech recognition was not authorized. Please check your privacy settings and try again."
                }
                showingAuthorizationAlert = true
            }
        }
    }
}

struct VoiceVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceVisualizationView()
            .padding()
    }
}