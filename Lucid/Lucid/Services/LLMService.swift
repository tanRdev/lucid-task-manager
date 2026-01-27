import Foundation
import os

/// Service for local LLM-based process identification
actor LLMService {
    private let logger = Logger(subsystem: "com.tan.lucid", category: "LLMService")

    // In-memory cache: "processName|path" -> (description, safety)
    private var cache: [String: (String, Safety)] = [:]

    // Path to llama.cpp executable (can be configured)
    private let llamaCppPath: String
    private let modelPath: String

    // Disk cache location
    private let cacheFileURL: URL

    init(llamaCppPath: String = "/opt/homebrew/bin/llama-cli",
         modelPath: String = "~/.lucid/models/tinyllama-1.1b-chat.gguf") {
        self.llamaCppPath = llamaCppPath
        self.modelPath = (modelPath as NSString).expandingTildeInPath

        let cacheDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".lucid")
        let cacheURL = cacheDir.appendingPathComponent("llm-cache.json")
        self.cacheFileURL = cacheURL

        // Load persisted cache synchronously during init
        if FileManager.default.fileExists(atPath: cacheURL.path),
           let data = try? Data(contentsOf: cacheURL),
           let entries = try? JSONDecoder().decode([String: CacheEntry].self, from: data) {
            for (key, entry) in entries {
                if let safety = Safety(rawValue: entry.safety) {
                    self.cache[key] = (entry.description, safety)
                }
            }
        }
    }

    /// Check if LLM is available on the system
    func isAvailable() -> Bool {
        FileManager.default.fileExists(atPath: llamaCppPath) &&
        FileManager.default.fileExists(atPath: modelPath)
    }

    /// Check the cache only (no inference). Returns immediately.
    func cachedResult(name: String, path: String) -> (String, Safety)? {
        cache["\(name)|\(path)"]
    }

    /// Identify a process using LLM
    func identifyProcess(name: String, path: String) async -> (String, Safety)? {
        let cacheKey = "\(name)|\(path)"

        // Check cache first
        if let cached = cache[cacheKey] {
            logger.debug("LLM cache hit for \(name)")
            return cached
        }

        // Check availability
        guard isAvailable() else {
            logger.warning("LLM not available")
            return nil
        }

        // Build prompt
        let prompt = buildPrompt(name: name, path: path)

        // Run inference
        guard let result = await runInference(prompt: prompt) else {
            logger.error("LLM inference failed for \(name)")
            return nil
        }

        // Parse result
        guard let parsed = parseResult(result) else {
            logger.error("LLM result parsing failed for \(name)")
            return nil
        }

        // Cache in memory and persist to disk
        cache[cacheKey] = parsed
        saveCacheToDisk()
        logger.info("LLM identified \(name) as \(parsed.0)")
        return parsed
    }

    // MARK: - Disk Persistence

    private struct CacheEntry: Codable {
        let description: String
        let safety: String
    }

    private func saveCacheToDisk() {
        var entries: [String: CacheEntry] = [:]
        for (key, (description, safety)) in cache {
            entries[key] = CacheEntry(description: description, safety: safety.rawValue)
        }
        do {
            let dir = cacheFileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(entries)
            try data.write(to: cacheFileURL, options: .atomic)
        } catch {
            logger.warning("Failed to save LLM disk cache: \(error)")
        }
    }

    private func buildPrompt(name: String, path: String) -> String {
        """
        You are a macOS process identification expert. Given a process name and path, provide:
        1. A brief description (max 5 words)
        2. Safety category: system, user, or unknown

        Process name: \(name)
        Process path: \(path)

        Respond ONLY in this format:
        DESCRIPTION: <description>
        SAFETY: <system|user|unknown>
        """
    }

    private func runInference(prompt: String) async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: llamaCppPath)
        process.arguments = [
            "-m", modelPath,
            "-p", prompt,
            "-n", "128",          // Max tokens
            "-t", "4",            // Threads
            "--temp", "0.1",      // Low temperature for deterministic output
            "--silent-prompt"
        ]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe() // Suppress stderr

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                return nil
            }

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            logger.error("Failed to run llama.cpp: \(error)")
            return nil
        }
    }

    private func parseResult(_ output: String) -> (String, Safety)? {
        // Parse format:
        // DESCRIPTION: <description>
        // SAFETY: <category>

        let lines = output.components(separatedBy: .newlines)
        var description: String?
        var safety: Safety?

        for line in lines {
            if line.hasPrefix("DESCRIPTION:") {
                description = line.replacingOccurrences(of: "DESCRIPTION:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("SAFETY:") {
                let safetyStr = line.replacingOccurrences(of: "SAFETY:", with: "").trimmingCharacters(in: .whitespaces).lowercased()
                safety = Safety(rawValue: safetyStr)
            }
        }

        guard let desc = description, !desc.isEmpty,
              let saf = safety else {
            return nil
        }

        return (desc, saf)
    }

    /// Clear the cache (useful for testing)
    func clearCache() {
        cache.removeAll()
    }
}
