import Danger
import Foundation

let danger = Danger()

// MARK: - Security Scan Job Status Check

// Check if the security scan job failed
if let securityScanResult = ProcessInfo.processInfo.environment["SECURITY_SCAN_RESULT"] {
    if securityScanResult != "success" {
        fail("""
        🚨 **Security Scan Failed**

        The security-scan job (including SonarCloud analysis) did not complete successfully.
        Status: `\(securityScanResult)`

        Please check the security-scan job logs for details.
        """)
    }
}

// MARK: - PR Validation

// Check if PR has a proper title and description
if danger.github.pullRequest.title.isEmpty {
    fail("Please provide a title for your PR.")
}

if danger.github.pullRequest.body?.isEmpty != false {
    warn("Please provide a description for your PR to help reviewers understand the changes.")
}

// Check for large PRs
let changedFiles = danger.git.modifiedFiles + danger.git.createdFiles + danger.git.deletedFiles
if changedFiles.count > 20 {
    warn("This PR contains \(changedFiles.count) changed files. Consider breaking it into smaller PRs for easier review.")
}

// Check for proper file changes
let swiftFiles = changedFiles.filter { $0.hasSuffix(".swift") }
let testFiles = changedFiles.filter { $0.contains("Test") && $0.hasSuffix(".swift") }

if !swiftFiles.isEmpty && testFiles.isEmpty {
    warn("You've made changes to Swift files but haven't added tests. Consider adding tests to maintain code quality.")
}

// MARK: - Security Checks

// Check for potential security issues in code
let allFiles = danger.git.modifiedFiles + danger.git.createdFiles
for file in allFiles where file.hasSuffix(".swift") {
    let fileContent = try String(contentsOfFile: file)

    // Check for hardcoded secrets/keys
    let secretPatterns = [
        "api[_-]?key\\s*[=:]\\s*['\"][^'\"]{10,}['\"]",
        "secret[_-]?key\\s*[=:]\\s*['\"][^'\"]{10,}['\"]",
        "password\\s*[=:]\\s*['\"][^'\"]{8,}['\"]",
        "token\\s*[=:]\\s*['\"][^'\"]{10,}['\"]"
    ]

    for pattern in secretPatterns {
        if fileContent.range(of: pattern, options: .regularExpression) != nil {
            fail("⚠️ Potential hardcoded secret detected in \(file). Please use environment variables or secure storage instead.")
        }
    }

    // Check for unsafe network calls
    if fileContent.contains("http://") && !fileContent.contains("localhost") {
        warn("HTTP connection detected in \(file). Consider using HTTPS for secure communication.")
    }

    // Check for SQL injection risks (if using SQLite or similar)
    if fileContent.contains("sqlite3_exec") || fileContent.contains("FMDB") {
        if fileContent.contains("\"+") || fileContent.contains("\"\\(") {
            warn("Potential SQL injection risk in \(file). Use parameterized queries instead of string concatenation.")
        }
    }
}

// MARK: - SwiftLint Results Integration

// Check SwiftLint results
if FileManager.default.fileExists(atPath: "swiftlint-results.json") {
    let swiftlintData = try Data(contentsOf: URL(fileURLWithPath: "swiftlint-results.json"))

    struct SwiftLintViolation: Codable {
        let character: Int?
        let file: String
        let line: Int
        let reason: String
        let rule_id: String
        let severity: String
        let type: String
    }

    let violations = try JSONDecoder().decode([SwiftLintViolation].self, from: swiftlintData)

    let errors = violations.filter { $0.severity == "error" }
    let warnings = violations.filter { $0.severity == "warning" }

    if !errors.isEmpty {
        var errorMessage = "🚨 **SwiftLint Errors** (\(errors.count)):\n"
        for error in errors.prefix(10) { // Limit to first 10 to avoid spam
            let fileName = URL(fileURLWithPath: error.file).lastPathComponent
            errorMessage += "- `\(fileName):\(error.line)` - \(error.reason) (`\(error.rule_id)`)\n"
        }
        if errors.count > 10 {
            errorMessage += "... and \(errors.count - 10) more errors\n"
        }
        fail(errorMessage)
    }

    if !warnings.isEmpty {
        var warningMessage = "⚠️ **SwiftLint Warnings** (\(warnings.count)):\n"
        for warning in warnings.prefix(5) { // Limit to first 5
            let fileName = URL(fileURLWithPath: warning.file).lastPathComponent
            warningMessage += "- `\(fileName):\(warning.line)` - \(warning.reason) (`\(warning.rule_id)`)\n"
        }
        if warnings.count > 5 {
            warningMessage += "... and \(warnings.count - 5) more warnings\n"
        }
        warn(warningMessage)
    }

    if violations.isEmpty {
        message("✅ **SwiftLint**: No violations found!")
    }
} else {
    warn("SwiftLint results not found. Make sure SwiftLint ran successfully.")
}

// MARK: - SonarCloud Results Integration

// Check if SonarCloud analysis is available
message("🔍 **Security Analysis Results**")

// Note: In a real implementation, you would fetch SonarCloud results via API
// For now, we'll provide guidance on how to check the results
message("""
📊 **SonarCloud Analysis**: Check the [SonarCloud dashboard](https://sonarcloud.io) for detailed security analysis results.

Key metrics to review:
- Security Hotspots: Code that might contain security vulnerabilities
- Vulnerabilities: Confirmed security issues that need immediate attention
- Code Smells: Maintainability issues that could lead to bugs
- Coverage: Test coverage percentage
""")

// MARK: - Code Quality Checks

// Check for TODOs and FIXMEs
var todos: [String] = []
var fixmes: [String] = []

for file in swiftFiles {
    let fileContent = try String(contentsOfFile: file)
    let lines = fileContent.components(separatedBy: .newlines)

    for (index, line) in lines.enumerated() {
        if line.contains("TODO") {
            todos.append("📝 TODO in \(file):\(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
        }
        if line.contains("FIXME") {
            fixmes.append("🔧 FIXME in \(file):\(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
        }
    }
}

if !todos.isEmpty {
    message("**TODOs found:**\n" + todos.joined(separator: "\n"))
}

if !fixmes.isEmpty {
    warn("**FIXMEs found that should be addressed:**\n" + fixmes.joined(separator: "\n"))
}

// MARK: - Build and Test Status

// Check if Package.swift was modified
if danger.git.modifiedFiles.contains("Package.swift") {
    message("📦 Package.swift was modified. Make sure to test the build and dependencies work correctly.")
}

// Final security reminder
message("""
🛡️ **Security Checklist**:
- [ ] No hardcoded secrets or API keys
- [ ] All network calls use HTTPS
- [ ] Input validation is properly implemented
- [ ] Sensitive data is properly encrypted
- [ ] Dependencies are up-to-date and secure
- [ ] SwiftLint security rules passed
- [ ] SonarCloud security scan completed
""")

// Success message
message("✅ Danger checks completed! Please review any warnings or failures above.")