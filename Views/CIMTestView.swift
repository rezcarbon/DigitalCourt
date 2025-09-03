import SwiftUI

struct CIMTestView: View {
    @StateObject private var cim = CIM()
    @State private var script: String = "function fib(n) {\n    if (n <= 1) return n;\n    return fib(n - 1) + fib(n - 2);\n}\nfib(10);"
    @State private var lastResult: String = ""

    var body: some View {
        NavigationView {
            VStack {
                // Code Editor
                Text("JavaScript Input")
                    .font(.headline)
                TextEditor(text: $script)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .padding()

                // Execute Button
                Button(action: {
                    lastResult = cim.execute(script: script)
                }) {
                    Text("Execute")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Result Display
                Text("Result: \(lastResult)")
                    .padding()
                
                // Console Output
                Text("Console")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(cim.consoleOutput, id: \.self) { line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding()

                Spacer()
            }
            .navigationTitle("CIM Test Environment")
        }
    }
}