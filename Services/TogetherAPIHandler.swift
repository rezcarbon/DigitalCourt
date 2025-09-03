import Foundation

// A class to handle network requests to the Together AI API.
class TogetherAPIHandler {
    private let apiKey: String
    private let modelId: String
    private let apiURL = URL(string: "https://api.together.xyz/v1/chat/completions")!

    init(apiKey: String, modelId: String) {
        self.apiKey = apiKey
        self.modelId = modelId
    }

    /// Generates a response from the LLM for a given prompt and optional image URL.
    func generateResponse(for prompt: String, imageUrl: String? = nil, systemPrompt: String) async -> String {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Construct the message payload
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": createContent(for: prompt, imageUrl: imageUrl)]
        ]

        let payload: [String: Any] = [
            "model": modelId,
            "max_tokens": 4096,
            "temperature": 0.7,
            "top_p": 0.7,
            "top_k": 50,
            "repetition_penalty": 1,
            "stop": ["</s>"],
            "messages": messages
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            return "Error serializing JSON payload: \(error.localizedDescription)"
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Parse the JSON response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return "Error parsing response: \(String(data: data, encoding: .utf8) ?? "Invalid data")"
            }
            
            return content
        } catch {
            return "Error during API request: \(error.localizedDescription)"
        }
    }

    /// Generates a streaming response from the LLM for a given prompt.
    func generateStreamResponse(for prompt: String, imageUrl: String? = nil, systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                var request = URLRequest(url: apiURL)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                // Construct the message payload
                let messages: [[String: Any]] = [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": createContent(for: prompt, imageUrl: imageUrl)]
                ]

                let payload: [String: Any] = [
                    "model": modelId,
                    "max_tokens": 4096,
                    "temperature": 0.7,
                    "top_p": 0.7,
                    "top_k": 50,
                    "repetition_penalty": 1,
                    "stop": ["</s>"],
                    "messages": messages,
                    "stream": true
                ]

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
                } catch {
                    continuation.finish(throwing: error)
                    return
                }

                do {
                    let (data, _) = try await URLSession.shared.data(for: request)
                    
                    // Parse the streaming response (SSE format)
                    let responseString = String(data: data, encoding: .utf8) ?? ""
                    
                    // Split by lines and process each event
                    let lines = responseString.components(separatedBy: .newlines)
                    
                    for line in lines {
                        if line.hasPrefix("data: ") {
                            let jsonData = String(line.dropFirst(6)) // Remove "data: " prefix
                            
                            if jsonData == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            
                            // Parse the JSON
                            if let data = jsonData.data(using: .utf8),
                               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let firstChoice = choices.first,
                               let delta = firstChoice["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                continuation.yield(content)
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Creates the content structure for the API call, handling both text and image inputs.
    private func createContent(for prompt: String, imageUrl: String?) -> [Any] {
        var content: [Any] = [
            ["type": "text", "text": prompt]
        ]
        
        // If an image URL is provided, add it to the content
        if let imageUrl = imageUrl {
            content.insert(["type": "image_url", "image_url": ["url": imageUrl]], at: 0)
        }
        
        return content
    }
}