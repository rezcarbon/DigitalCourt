import SwiftUI
import UIKit

struct AppIconGenerator: View {
    @State private var isGenerating = false
    @State private var generationStatus = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Generator")
                .font(.title)
                .padding()
            
            // Preview of the icon - use your real logo
            RealSithEmpireLogo(size: 200, glowEffect: true, animated: false)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 40))
            
            if isGenerating {
                ProgressView("Generating Icons...")
                Text(generationStatus)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Button("Generate App Icon Files") {
                    generateAppIconFiles()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Text("This will generate all required icon sizes and save them to your project's Assets.xcassets folder")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
    
    private func generateAppIconFiles() {
        isGenerating = true
        
        let iconConfigurations: [(size: CGFloat, filename: String)] = [
            // iPhone sizes
            (40, "icon-20@2x.png"),      // 20pt @2x
            (60, "icon-20@3x.png"),      // 20pt @3x
            (58, "icon-29@2x.png"),      // 29pt @2x
            (87, "icon-29@3x.png"),      // 29pt @3x
            (80, "icon-40@2x.png"),      // 40pt @2x
            (120, "icon-40@3x.png"),     // 40pt @3x
            (120, "icon-60@2x.png"),     // 60pt @2x
            (180, "icon-60@3x.png"),     // 60pt @3x
            
            // iPad sizes
            (20, "icon-20.png"),         // 20pt @1x
            (40, "icon-20@2x-ipad.png"), // 20pt @2x iPad
            (29, "icon-29.png"),         // 29pt @1x
            (58, "icon-29@2x-ipad.png"), // 29pt @2x iPad
            (40, "icon-40.png"),         // 40pt @1x
            (80, "icon-40@2x-ipad.png"), // 40pt @2x iPad
            (76, "icon-76.png"),         // 76pt @1x
            (152, "icon-76@2x.png"),     // 76pt @2x
            (167, "icon-83.5@2x.png"),   // 83.5pt @2x
            
            // App Store
            (1024, "icon-1024.png")      // 1024pt @1x
        ]
        
        let appIconPath = "/Users/modvaderm3/Desktop/DigitalCourt/DCourt/DCourt/Assets.xcassets/AppIcon.appiconset/"
        
        for (index, config) in iconConfigurations.enumerated() {
            DispatchQueue.main.async {
                self.generationStatus = "Generating \(config.filename)... (\(index + 1)/\(iconConfigurations.count))"
            }
            
            generateIcon(size: config.size, filename: config.filename, savePath: appIconPath)
            
            // Small delay to show progress
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        DispatchQueue.main.async {
            self.generationStatus = "✅ All icons generated successfully!"
            self.isGenerating = false
            
            // Reset status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.generationStatus = ""
            }
        }
    }
    
    private func generateIcon(size: CGFloat, filename: String, savePath: String) {
        let renderer = ImageRenderer(
            content: RealSithEmpireLogo(size: size, glowEffect: true, animated: false)
                .background(Color.black)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.18)) // iOS icon corner radius
        )
        
        renderer.scale = 1.0 // Use exact pixel size
        
        if let image = renderer.uiImage {
            saveImageToFile(image, filename: filename, path: savePath)
        }
    }
    
    private func saveImageToFile(_ image: UIImage, filename: String, path: String) {
        guard let data = image.pngData() else {
            print("❌ Failed to convert image to PNG data for \(filename)")
            return
        }
        
        let fileURL = URL(fileURLWithPath: path + filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ Saved \(filename) to \(path)")
        } catch {
            print("❌ Failed to save \(filename): \(error)")
        }
    }
}

struct AppIconGenerator_Previews: PreviewProvider {
    static var previews: some View {
        AppIconGenerator()
            .preferredColorScheme(.dark)
    }
}