import Foundation

/// Advanced code analysis engine for CIM
class CodeAnalyzer {
    
    private let supportedLanguages = ["swift", "javascript", "python", "java", "cpp", "c"]
    
    func analyze(code: String, language: String) async -> CodeAnalysisResult {
        let normalizedLanguage = language.lowercased()
        
        guard supportedLanguages.contains(normalizedLanguage) else {
            return CodeAnalysisResult(
                language: language,
                complexity: 0,
                issues: [CodeAnalysisResult.CodeIssue(
                    severity: .warning,
                    description: "Unsupported language: \(language)",
                    line: nil,
                    suggestion: "Supported languages: \(supportedLanguages.joined(separator: ", "))"
                )],
                suggestions: [],
                metrics: CodeAnalysisResult.CodeMetrics(
                    linesOfCode: 0,
                    cyclomaticComplexity: 0,
                    maintainabilityIndex: 0.0,
                    technicalDebt: 0.0
                )
            )
        }
        
        let lines = code.components(separatedBy: .newlines)
        let linesOfCode = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        
        let complexity = calculateCyclomaticComplexity(code: code, language: normalizedLanguage)
        let issues = await detectIssues(code: code, language: normalizedLanguage)
        let suggestions = generateSuggestions(code: code, language: normalizedLanguage, issues: issues)
        let maintainabilityIndex = calculateMaintainabilityIndex(linesOfCode: linesOfCode, complexity: complexity)
        let technicalDebt = calculateTechnicalDebt(issues: issues, linesOfCode: linesOfCode)
        
        return CodeAnalysisResult(
            language: language,
            complexity: complexity,
            issues: issues,
            suggestions: suggestions,
            metrics: CodeAnalysisResult.CodeMetrics(
                linesOfCode: linesOfCode,
                cyclomaticComplexity: complexity,
                maintainabilityIndex: maintainabilityIndex,
                technicalDebt: technicalDebt
            )
        )
    }
    
    private func calculateCyclomaticComplexity(code: String, language: String) -> Int {
        var complexity = 1 // Base complexity
        
        let complexityKeywords: [String]
        switch language {
        case "swift":
            complexityKeywords = ["if", "else if", "while", "for", "guard", "switch", "case", "catch", "?", "&&", "||"]
        case "javascript":
            complexityKeywords = ["if", "else if", "while", "for", "switch", "case", "catch", "?", "&&", "||"]
        case "python":
            complexityKeywords = ["if", "elif", "while", "for", "except", "and", "or"]
        default:
            complexityKeywords = ["if", "while", "for", "switch", "case", "catch"]
        }
        
        for keyword in complexityKeywords {
            let pattern = "\\b\(keyword)\\b"
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex?.numberOfMatches(in: code, options: [], range: NSRange(location: 0, length: code.count)) ?? 0
            complexity += matches
        }
        
        return complexity
    }
    
    private func detectIssues(code: String, language: String) async -> [CodeAnalysisResult.CodeIssue] {
        var issues: [CodeAnalysisResult.CodeIssue] = []
        let lines = code.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for common issues
            if trimmedLine.count > 120 {
                issues.append(CodeAnalysisResult.CodeIssue(
                    severity: .warning,
                    description: "Line too long (\(trimmedLine.count) characters)",
                    line: lineNumber,
                    suggestion: "Consider breaking this line into multiple lines"
                ))
            }
            
            if language == "swift" {
                // Swift-specific checks
                if trimmedLine.contains("!") && !trimmedLine.contains("!=") {
                    issues.append(CodeAnalysisResult.CodeIssue(
                        severity: .warning,
                        description: "Force unwrapping detected",
                        line: lineNumber,
                        suggestion: "Consider using optional binding or nil coalescing instead"
                    ))
                }
                
                if trimmedLine.contains("print(") {
                    issues.append(CodeAnalysisResult.CodeIssue(
                        severity: .info,
                        description: "Debug print statement found",
                        line: lineNumber,
                        suggestion: "Remove debug prints before production"
                    ))
                }
            }
            
            // Check for TODO/FIXME comments
            if trimmedLine.uppercased().contains("TODO") || trimmedLine.uppercased().contains("FIXME") {
                issues.append(CodeAnalysisResult.CodeIssue(
                    severity: .info,
                    description: "TODO/FIXME comment found",
                    line: lineNumber,
                    suggestion: "Address this comment before release"
                ))
            }
        }
        
        return issues
    }
    
    private func generateSuggestions(code: String, language: String, issues: [CodeAnalysisResult.CodeIssue]) -> [String] {
        var suggestions: [String] = []
        
        // General suggestions based on issues
        let errorCount = issues.filter { $0.severity == .error }.count
        let warningCount = issues.filter { $0.severity == .warning }.count
        
        if errorCount > 0 {
            suggestions.append("Fix \(errorCount) error(s) to improve code stability")
        }
        
        if warningCount > 3 {
            suggestions.append("Address warnings to improve code quality")
        }
        
        // Language-specific suggestions
        switch language {
        case "swift":
            if code.contains("var ") && !code.contains("let ") {
                suggestions.append("Consider using 'let' instead of 'var' where possible for immutability")
            }
            if !code.contains("@MainActor") && code.contains("@Published") {
                suggestions.append("Consider using @MainActor for ObservableObject classes")
            }
        case "javascript":
            if code.contains("var ") {
                suggestions.append("Consider using 'let' or 'const' instead of 'var'")
            }
            if !code.contains("'use strict'") {
                suggestions.append("Consider adding 'use strict' for better error checking")
            }
        default:
            break
        }
        
        return suggestions
    }
    
    private func calculateMaintainabilityIndex(linesOfCode: Int, complexity: Int) -> Double {
        // Simplified maintainability index calculation
        let volume = Double(linesOfCode) * log2(Double(max(1, linesOfCode)))
        let maintainabilityIndex = max(0, (171 - 5.2 * log(volume) - 0.23 * Double(complexity) - 16.2 * log(Double(linesOfCode))) * 100 / 171)
        return maintainabilityIndex
    }
    
    private func calculateTechnicalDebt(issues: [CodeAnalysisResult.CodeIssue], linesOfCode: Int) -> Double {
        let errorWeight = 10.0
        let warningWeight = 5.0
        let infoWeight = 1.0
        
        var debtScore = 0.0
        for issue in issues {
            switch issue.severity {
            case .error, .critical:
                debtScore += errorWeight
            case .warning:
                debtScore += warningWeight
            case .info:
                debtScore += infoWeight
            }
        }
        
        // Normalize by lines of code
        return linesOfCode > 0 ? debtScore / Double(linesOfCode) * 100 : 0
    }
}