import SwiftUI

struct ChatView: View {
    let chamber: Chamber
    
    @StateObject private var viewModel: ChatChamberViewModel
    @StateObject private var voiceService = VoiceService.shared
    @StateObject private var visionHandler = VisionModelHandler.shared
    
    @State private var messageText = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingVoiceInterface = false
    @State private var isVisionAnalyzing = false
    @State private var showingImageAnalysis = false
    @State private var imageAnalysisResult: VisionAnalysisResult?
    
    init(chamber: Chamber) {
        self.chamber = chamber
        self._viewModel = StateObject(wrappedValue: ChatChamberViewModel(chamber: chamber))
    }
    
    var body: some View {
        VStack {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Voice Interface (when active)
            if showingVoiceInterface {
                VoiceVisualizationView()
                    .padding(.horizontal)
                    .transition(.slide)
            }
            
            // Image Analysis Result
            if let analysisResult = imageAnalysisResult {
                imageAnalysisView(analysisResult)
            }
            
            // Enhanced Message Input
            enhancedMessageInputView
        }
        .navigationTitle(chamber.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    // Voice Interface Toggle
                    Button(action: {
                        withAnimation {
                            showingVoiceInterface.toggle()
                        }
                    }) {
                        Image(systemName: showingVoiceInterface ? "mic.slash.fill" : "mic.fill")
                            .foregroundColor(showingVoiceInterface ? .red : .blue)
                    }
                    
                    // Vision Analysis Toggle (when image is selected)
                    if selectedImage != nil {
                        Button(action: {
                            analyzeSelectedImage()
                        }) {
                            Image(systemName: "eye.fill")
                                .foregroundColor(.purple)
                        }
                        .disabled(isVisionAnalyzing)
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onAppear {
            // Initialize vision handler if not already done
            Task {
                if !visionHandler.isInitialized {
                    try? await visionHandler.initialize()
                }
            }
        }
        .onChange(of: voiceService.recognizedText) { _, newText in
            if !newText.isEmpty && voiceService.voiceSettings.conversationMode {
                // Auto-send recognized text in conversation mode
                messageText = newText
                sendMessage()
            }
        }
    }
    
    private var enhancedMessageInputView: some View {
        VStack(spacing: 8) {
            // Selected Image Preview
            if let image = selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text("Image Selected")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        if isVisionAnalyzing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Analyzing...")
                                    .font(.caption2)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button("Remove") {
                        selectedImage = nil
                        imageAnalysisResult = nil
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Message Input Row
            HStack(spacing: 12) {
                // Image Picker Button
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "photo.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Voice Input Button
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
                        .font(.title2)
                        .foregroundColor(voiceService.isListening ? .red : .green)
                }
                
                // Text Input Field
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...5)
                
                // Send Button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty && selectedImage == nil ? .gray : .blue)
                }
                .disabled(messageText.isEmpty && selectedImage == nil)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private func imageAnalysisView(_ result: VisionAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Image Analysis")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Use Analysis") {
                    messageText = result.description
                    imageAnalysisResult = nil
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Clear") {
                    imageAnalysisResult = nil
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.description)
                        .font(.body)
                    
                    if !result.detectedObjects.isEmpty {
                        Text("Detected Objects:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        ForEach(Array(result.detectedObjects.enumerated()), id: \.offset) { _, object in
                            Text("• \(object.label) (\(Int(object.confidence * 100))%)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !result.extractedText.isEmpty {
                        Text("Extracted Text:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        ForEach(Array(result.extractedText.enumerated()), id: \.offset) { _, text in
                            Text("• \(text.text)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxHeight: 120)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func sendMessage() {
        let finalText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !finalText.isEmpty || selectedImage != nil else { return }
        
        // Update viewModel's input text
        viewModel.inputText = finalText
        
        // Convert UIImage to Data if we have an image
        if let image = selectedImage {
            viewModel.attachedImageData = image.jpegData(compressionQuality: 0.8)
        }
        
        // If we have image analysis, include relevant information
        if let analysis = imageAnalysisResult {
            viewModel.inputText += "\n\n[Image Analysis: \(analysis.description)]"
        }
        
        Task {
            await viewModel.sendMessage()
            
            await MainActor.run {
                messageText = ""
                selectedImage = nil
                imageAnalysisResult = nil
                
                // Stop listening if in conversation mode (will restart after AI response)
                if voiceService.voiceSettings.conversationMode && voiceService.isListening {
                    voiceService.stopListening()
                }
            }
        }
    }
    
    private func analyzeSelectedImage() {
        guard let image = selectedImage else { return }
        
        isVisionAnalyzing = true
        
        Task {
            do {
                let result = try await visionHandler.analyzeImage(image)
                await MainActor.run {
                    imageAnalysisResult = result
                    isVisionAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    isVisionAnalyzing = false
                    print("❌ Vision analysis failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if !message.isUser {
                    Text(message.personaName ?? "AI")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(message.isUser ? Color.blue : Color(.systemGray5))
                        .foregroundColor(message.isUser ? .white : .primary)
                        .cornerRadius(16)
                    
                    // Show attached image if present
                    if let imageData = message.attachedImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                    }
                    
                    // Show attached document if present
                    if let document = message.attachedDocument {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            Text(document.fileName)
                                .font(.caption)
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: Int64(document.data.count), countStyle: .file))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}