import Foundation
import PDFKit
import NaturalLanguage

/// Advanced document processing engine for multi-modal AI
class DocumentProcessor: @unchecked Sendable {
    
    private let processingQueue = DispatchQueue(label: "DocumentProcessor", qos: .userInitiated)
    private let nlProcessor = NLTagger(tagSchemes: [.lexicalClass, .language, .lemma])
    
    func processDocument(_ documentData: Data, type: DocumentType) async -> DocumentProcessingResult {
        return await withCheckedContinuation { continuation in
            processingQueue.async { [weak self] in
                guard let self = self else {
                    let emptyResult = DocumentProcessingResult(
                        documentType: type.rawValue,
                        extractedText: "",
                        structure: DocumentStructure(title: nil, sections: [], tables: [], images: [], pageCount: 0),
                        metadata: [:],
                        confidence: 0.0,
                        timestamp: Date()
                    )
                    continuation.resume(returning: emptyResult)
                    return
                }
                
                _ = Date()
                var extractedText = ""
                var structure = DocumentStructure(title: nil, sections: [], tables: [], images: [], pageCount: 0)
                var metadata: [String: String] = [:]
                var confidence = 0.0
                
                switch type {
                case .pdf:
                    let pdfResult = self.processPDF(documentData)
                    extractedText = pdfResult.text
                    structure = pdfResult.structure
                    metadata = pdfResult.metadata
                    confidence = pdfResult.confidence
                    
                case .word:
                    // Word document processing would be implemented here
                    extractedText = "Word document processing not implemented"
                    confidence = 0.0
                    
                case .text:
                    extractedText = String(data: documentData, encoding: .utf8) ?? ""
                    structure = self.analyzeTextStructure(extractedText)
                    confidence = 0.9
                    
                case .image:
                    // Image document processing (OCR) would be implemented here
                    extractedText = "Image document processing not implemented"
                    confidence = 0.0
                    
                case .structured:
                    // Structured document processing (JSON, XML, etc.)
                    extractedText = String(data: documentData, encoding: .utf8) ?? ""
                    structure = self.analyzeStructuredDocument(extractedText)
                    confidence = 0.8
                }
                
                let result = DocumentProcessingResult(
                    documentType: type.rawValue,
                    extractedText: extractedText,
                    structure: structure,
                    metadata: metadata,
                    confidence: confidence,
                    timestamp: Date()
                )
                
                continuation.resume(returning: result)
            }
        }
    }
    
    func extractTextFromPDF(_ pdfData: Data) async -> String {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                guard let pdfDocument = PDFDocument(data: pdfData) else {
                    continuation.resume(returning: "")
                    return
                }
                
                var extractedText = ""
                for pageIndex in 0..<pdfDocument.pageCount {
                    if let page = pdfDocument.page(at: pageIndex) {
                        extractedText += page.string ?? ""
                        extractedText += "\n"
                    }
                }
                
                continuation.resume(returning: extractedText)
            }
        }
    }
    
    func analyzeDocumentStructure(_ documentData: Data) async -> DocumentStructure {
        let text = String(data: documentData, encoding: .utf8) ?? ""
        return analyzeTextStructure(text)
    }
    
    // MARK: - PDF Processing
    
    private func processPDF(_ pdfData: Data) -> (text: String, structure: DocumentStructure, metadata: [String: String], confidence: Double) {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            return ("", DocumentStructure(title: nil, sections: [], tables: [], images: [], pageCount: 0), [:], 0.0)
        }
        
        var extractedText = ""
        var sections: [DocumentSection] = []
        var tables: [DocumentTable] = []
        var images: [DocumentImage] = []
        var metadata: [String: String] = [:]
        
        let pageCount = pdfDocument.pageCount
        
        // Extract metadata
        if let documentAttributes = pdfDocument.documentAttributes {
            metadata["title"] = documentAttributes[PDFDocumentAttribute.titleAttribute] as? String ?? ""
            metadata["author"] = documentAttributes[PDFDocumentAttribute.authorAttribute] as? String ?? ""
            metadata["creator"] = documentAttributes[PDFDocumentAttribute.creatorAttribute] as? String ?? ""
            metadata["subject"] = documentAttributes[PDFDocumentAttribute.subjectAttribute] as? String ?? ""
        }
        
        // Process each page
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            let pageText = page.string ?? ""
            extractedText += pageText + "\n"
            
            // Extract sections from page
            let pageSections = extractSections(from: pageText, pageNumber: pageIndex + 1)
            sections.append(contentsOf: pageSections)
            
            // Extract tables (simplified detection)
            let pageTables = extractTables(from: pageText, pageNumber: pageIndex + 1)
            tables.append(contentsOf: pageTables)
            
            // Detect images (simplified)
            let pageImages = detectImages(in: page, pageNumber: pageIndex + 1)
            images.append(contentsOf: pageImages)
        }
        
        let structure = DocumentStructure(
            title: metadata["title"],
            sections: sections,
            tables: tables,
            images: images,
            pageCount: pageCount
        )
        
        return (extractedText, structure, metadata, 0.9)
    }
    
    // MARK: - Text Structure Analysis
    
    private func analyzeTextStructure(_ text: String) -> DocumentStructure {
        let lines = text.components(separatedBy: .newlines)
        var sections: [DocumentSection] = []
        var tables: [DocumentTable] = []
        
        var currentSection: String?
        var currentContent: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if isHeading(trimmedLine) {
                // Save previous section
                if let sectionTitle = currentSection, !currentContent.isEmpty {
                    sections.append(DocumentSection(
                        title: sectionTitle,
                        content: currentContent.joined(separator: "\n"),
                        level: getHeadingLevel(sectionTitle),
                        pageNumber: nil
                    ))
                }
                
                // Start new section
                currentSection = trimmedLine
                currentContent = []
            } else if isTableRow(trimmedLine) {
                // Detect table rows
                let table = parseTableRow(trimmedLine)
                if !tables.contains(where: { $0.rows.last == table }) {
                    tables.append(DocumentTable(rows: [table], headers: nil, pageNumber: nil))
                }
            } else if !trimmedLine.isEmpty {
                currentContent.append(trimmedLine)
            }
        }
        
        // Add final section
        if let sectionTitle = currentSection, !currentContent.isEmpty {
            sections.append(DocumentSection(
                title: sectionTitle,
                content: currentContent.joined(separator: "\n"),
                level: getHeadingLevel(sectionTitle),
                pageNumber: nil
            ))
        }
        
        return DocumentStructure(
            title: extractTitle(from: text),
            sections: sections,
            tables: tables,
            images: [],
            pageCount: 1
        )
    }
    
    private func analyzeStructuredDocument(_ text: String) -> DocumentStructure {
        // Handle JSON, XML, or other structured formats
        var sections: [DocumentSection] = []
        
        if text.hasPrefix("{") || text.hasPrefix("[") {
            // JSON structure
            sections = analyzeJSONStructure(text)
        } else if text.hasPrefix("<") {
            // XML structure
            sections = analyzeXMLStructure(text)
        }
        
        return DocumentStructure(
            title: "Structured Document",
            sections: sections,
            tables: [],
            images: [],
            pageCount: 1
        )
    }
    
    // MARK: - Content Extraction Helpers
    
    private func extractSections(from text: String, pageNumber: Int) -> [DocumentSection] {
        let lines = text.components(separatedBy: .newlines)
        var sections: [DocumentSection] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if isHeading(trimmedLine) {
                sections.append(DocumentSection(
                    title: trimmedLine,
                    content: "",
                    level: getHeadingLevel(trimmedLine),
                    pageNumber: pageNumber
                ))
            }
        }
        
        return sections
    }
    
    private func extractTables(from text: String, pageNumber: Int) -> [DocumentTable] {
        let lines = text.components(separatedBy: .newlines)
        var tables: [DocumentTable] = []
        var currentTableRows: [[String]] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if isTableRow(trimmedLine) {
                let row = parseTableRow(trimmedLine)
                currentTableRows.append(row)
            } else if !currentTableRows.isEmpty {
                // End of table
                tables.append(DocumentTable(
                    rows: currentTableRows,
                    headers: currentTableRows.first,
                    pageNumber: pageNumber
                ))
                currentTableRows = []
            }
        }
        
        // Add final table if exists
        if !currentTableRows.isEmpty {
            tables.append(DocumentTable(
                rows: currentTableRows,
                headers: currentTableRows.first,
                pageNumber: pageNumber
            ))
        }
        
        return tables
    }
    
    private func detectImages(in page: PDFPage, pageNumber: Int) -> [DocumentImage] {
        // Simplified image detection - would need more sophisticated implementation
        return []
    }
    
    // MARK: - Text Analysis Helpers
    
    private func isHeading(_ text: String) -> Bool {
        // Simple heading detection
        return text.count < 100 && 
               (text.uppercased() == text || 
                text.hasSuffix(":") || 
                text.matches(regex: "^\\d+\\.\\s+") ||
                text.matches(regex: "^[A-Z][A-Za-z\\s]+$"))
    }
    
    private func getHeadingLevel(_ heading: String) -> Int {
        if heading.matches(regex: "^\\d+\\.\\s+") {
            return 1
        } else if heading.matches(regex: "^\\d+\\.\\d+\\.\\s+") {
            return 2
        }
        return 1
    }
    
    private func isTableRow(_ text: String) -> Bool {
        // Simple table row detection
        let separators = ["|", "\t", "  "]
        return separators.contains { text.contains($0) }
    }
    
    private func parseTableRow(_ text: String) -> [String] {
        if text.contains("|") {
            return text.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        } else if text.contains("\t") {
            return text.components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            return text.components(separatedBy: "  ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
    }
    
    private func extractTitle(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && trimmed.count < 100 {
                return trimmed
            }
        }
        return nil
    }
    
    private func analyzeJSONStructure(_ json: String) -> [DocumentSection] {
        var sections: [DocumentSection] = []
        
        do {
            if let data = json.data(using: .utf8),
               let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                for (key, value) in jsonObject {
                    sections.append(DocumentSection(
                        title: key,
                        content: String(describing: value),
                        level: 1,
                        pageNumber: 1
                    ))
                }
            }
        } catch {
            print("JSON parsing error: \(error)")
        }
        
        return sections
    }
    
    private func analyzeXMLStructure(_ xml: String) -> [DocumentSection] {
        // Simplified XML structure analysis
        var sections: [DocumentSection] = []
        
        let pattern = "<([^>]+)>"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: xml, range: NSRange(xml.startIndex..., in: xml)) ?? []
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: xml) {
                let tagName = String(xml[range])
                sections.append(DocumentSection(
                    title: tagName,
                    content: "XML element",
                    level: 1,
                    pageNumber: 1
                ))
            }
        }
        
        return sections
    }
    
    // MARK: - Advanced Document Analysis
    
    func performSemanticAnalysis(_ text: String) async -> SemanticAnalysisResult {
        return await withCheckedContinuation { continuation in
            processingQueue.async { [weak self] in
                guard let self = self else {
                    let emptyResult = SemanticAnalysisResult(
                        language: "unknown",
                        entities: [],
                        keyPhrases: [],
                        sentiment: "neutral",
                        topics: [],
                        confidence: 0.0,
                        timestamp: Date()
                    )
                    continuation.resume(returning: emptyResult)
                    return
                }
                
                self.nlProcessor.string = text
                
                var entities: [String] = []
                let keyPhrases: [String] = []
                var sentiment = "neutral"
                var topics: [String] = []
                
                // Named Entity Recognition
                self.nlProcessor.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
                    if let tag = tag, tag == .noun {
                        let entity = String(text[range])
                        entities.append(entity)
                    }
                    return true
                }
                
                // Language detection
                let language = NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue ?? "unknown"
                
                // Topic modeling (simplified)
                topics = self.extractTopics(from: text)
                
                // Sentiment analysis (simplified)
                sentiment = self.analyzeSentiment(text)
                
                let result = SemanticAnalysisResult(
                    language: language,
                    entities: Array(Set(entities)), // Remove duplicates
                    keyPhrases: keyPhrases,
                    sentiment: sentiment,
                    topics: topics,
                    confidence: 0.8,
                    timestamp: Date()
                )
                
                continuation.resume(returning: result)
            }
        }
    }
    
    private func extractTopics(from text: String) -> [String] {
        let commonTopics = ["technology", "business", "science", "education", "health", "finance"]
        let lowercaseText = text.lowercased()
        
        return commonTopics.filter { topic in
            lowercaseText.contains(topic)
        }
    }
    
    private func analyzeSentiment(_ text: String) -> String {
        let positiveWords = ["good", "great", "excellent", "positive", "happy", "success"]
        let negativeWords = ["bad", "terrible", "negative", "sad", "failure", "problem"]
        
        let lowercaseText = text.lowercased()
        let positiveCount = positiveWords.reduce(0) { count, word in
            count + lowercaseText.components(separatedBy: word).count - 1
        }
        let negativeCount = negativeWords.reduce(0) { count, word in
            count + lowercaseText.components(separatedBy: word).count - 1
        }
        
        if positiveCount > negativeCount {
            return "positive"
        } else if negativeCount > positiveCount {
            return "negative"
        } else {
            return "neutral"
        }
    }
}

// MARK: - Supporting Models

struct SemanticAnalysisResult: Codable {
    let language: String
    let entities: [String]
    let keyPhrases: [String]
    let sentiment: String
    let topics: [String]
    let confidence: Double
    let timestamp: Date
}

// MARK: - String Extension for Regex

extension String {
    func matches(regex: String) -> Bool {
        return range(of: regex, options: .regularExpression) != nil
    }
}