import Foundation

/// API orchestration engine for autonomous CIM operations
class APIOrchestrator: @unchecked Sendable {
    
    private let session: URLSession
    private let requestsQueue = DispatchQueue(label: "APIOrchestrator.requests", attributes: .concurrent)
    private var _activeRequests: [String: URLSessionDataTask] = [:]
    
    private var activeRequests: [String: URLSessionDataTask] {
        get {
            return requestsQueue.sync { _activeRequests }
        }
        set {
            requestsQueue.async(flags: .barrier) { 
                self._activeRequests = newValue
            }
        }
    }
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
    }
    
    func execute(endpoint: String, payload: String?) async -> String {
        let requestId = UUID().uuidString
        
        do {
            let result = try await performRequest(endpoint: endpoint, payload: payload, requestId: requestId)
            return result
        } catch {
            return "API Error: \(error.localizedDescription)"
        }
    }
    
    private func performRequest(endpoint: String, payload: String?, requestId: String) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw APIOrchestratorError.invalidURL(endpoint)
        }
        
        var request = URLRequest(url: url)
        
        // Configure request based on payload
        if let payload = payload {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = payload.data(using: .utf8)
        } else {
            request.httpMethod = "GET"
        }
        
        // Add common headers
        request.setValue("CIM-Agent/3.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { [weak self] data, response, error in
                self?.requestsQueue.async(flags: .barrier) {
                    self?._activeRequests.removeValue(forKey: requestId)
                }
                
                if let error = error {
                    continuation.resume(throwing: APIOrchestratorError.networkError(error.localizedDescription))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: APIOrchestratorError.invalidResponse)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: APIOrchestratorError.noData)
                    return
                }
                
                let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                
                if 200...299 ~= httpResponse.statusCode {
                    continuation.resume(returning: responseString)
                } else {
                    continuation.resume(throwing: APIOrchestratorError.httpError(httpResponse.statusCode, responseString))
                }
            }
            
            requestsQueue.async(flags: .barrier) { [weak self] in
                self?._activeRequests[requestId] = task
            }
            task.resume()
        }
    }
    
    func cancelAllRequests() {
        requestsQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            for (_, task) in self._activeRequests {
                task.cancel()
            }
            self._activeRequests.removeAll()
        }
    }
    
    func getActiveRequestCount() -> Int {
        return requestsQueue.sync { _activeRequests.count }
    }
}

enum APIOrchestratorError: Error, LocalizedError {
    case invalidURL(String)
    case networkError(String)
    case invalidResponse
    case noData
    case httpError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response received"
        case .noData:
            return "No data received"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        }
    }
}