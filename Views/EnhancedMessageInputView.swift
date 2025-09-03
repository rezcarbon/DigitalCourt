import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct EnhancedMessageInputView: View {
    @ObservedObject var viewModel: ChatChamberViewModel
    @ObservedObject var voiceService: VoiceService
    @Binding var showingVoiceControls: Bool
    
    @State private var showingImagePicker = false
    @State private var showingFilePicker = false
    @State private var isRecording = false
    @State private var showingVoiceError = false
    @State private var voiceErrorMessage = ""

    // Define the supported document types
    private let allowedDocumentTypes: [UTType] = [
        .commaSeparatedText,
        .pdf,
        .plainText,
        .html,
        UTType(filenameExtension: "md") ?? .text,
        .spreadsheet
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Attachment Previews
            if viewModel.attachedImageData != nil || viewModel.attachedDocument != nil {
                EnhancedAttachmentPreviewView(viewModel: viewModel)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            // Voice Controls Panel
            if showingVoiceControls {
                VoiceControlsPanel(voiceService: voiceService, isRecording: $isRecording)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            HStack(spacing: 12) {
                // Document Picker Button
                Button(action: { showingFilePicker = true }) {
                    Image(systemName: "paperclip")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .padding(.leading)
                
                // Image Picker Button
                Button(action: { showingImagePicker = true }) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                // Enhanced Text Field with voice integration
                HStack {
                    TextField("Type a message...", text: $viewModel.inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // Voice Input Button
                    Button(action: { toggleVoiceInput() }) {
                        Image(systemName: isRecording ? "mic.fill" : "mic")
                            .font(.title2)
                            .foregroundColor(isRecording ? .red : .blue)
                            .scaleEffect(isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                    }
                }

                // Enhanced Send Button
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(viewModel.isSendButtonDisabled ? .gray : .blue)
                }
                .disabled(viewModel.isSendButtonDisabled)
                .padding(.trailing)
            }
            .padding()
            .background(Color.black.opacity(0.2))
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotosPicker(
                selection: $viewModel.selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Select an Image")
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: allowedDocumentTypes
        ) { result in
            viewModel.attachDocument(result: result)
        }
        .alert("Voice Input Error", isPresented: $showingVoiceError) {
            Button("OK") { }
        } message: {
            Text(voiceErrorMessage)
        }
    }
    
    private func toggleVoiceInput() {
        if isRecording {
            stopVoiceInput()
        } else {
            startVoiceInput()
        }
    }
    
    private func startVoiceInput() {
        isRecording = true
        Task {
            do {
                try await voiceService.startListening()
                // The recognized text will be handled by VoiceService internally
                // For now, we'll just handle the recording state
                await MainActor.run {
                    isRecording = false
                }
            } catch {
                await MainActor.run {
                    voiceErrorMessage = error.localizedDescription
                    showingVoiceError = true
                    isRecording = false
                }
            }
        }
    }
    
    private func stopVoiceInput() {
        voiceService.stopListening()
        isRecording = false
    }
}

struct VoiceControlsPanel: View {
    @ObservedObject var voiceService: VoiceService
    @Binding var isRecording: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Voice Controls")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                // Simple status indicator
                Circle()
                    .fill(voiceService.isListening ? .green : .gray)
                    .frame(width: 8, height: 8)
                Text(voiceService.isListening ? "Listening" : "Idle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                // Recording indicator
                VStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.gray)
                        .frame(width: 20, height: 20)
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                    
                    Text(isRecording ? "Recording" : "Ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Audio level visualization
                if isRecording {
                    AudioLevelBar(level: voiceService.audioLevel)
                }
                
                Spacer()
                
                // Voice settings
                Menu("Settings") {
                    Text("Voice Recognition: \(voiceService.isListening ? "Active" : "Inactive")")
                    Divider()
                    Button("Test Microphone") {
                        // Test microphone functionality
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AudioLevelBar: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { index in
                Rectangle()
                    .fill(level > Float(index) * 0.1 ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 3, height: CGFloat(8 + index * 2))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }
}