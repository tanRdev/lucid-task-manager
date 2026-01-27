import Foundation

struct PortScanner {
    private static let lock = NSLock()
    private static var cachedPorts: [pid_t: [UInt16]] = [:]
    private static var cacheTimestamp: Date = .distantPast
    private static let cacheTTL: TimeInterval = 15.0

    /// Runs `lsof -iTCP -sTCP:LISTEN -n -P` and returns a dictionary mapping pid -> [port].
    /// Results are cached for 15 seconds since port bindings change infrequently.
    static func getListeningPorts() -> [pid_t: [UInt16]] {
        lock.lock()
        if Date().timeIntervalSince(cacheTimestamp) < cacheTTL {
            let cached = cachedPorts
            lock.unlock()
            return cached
        }
        lock.unlock()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return cachedPorts
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0,
              let output = String(data: data, encoding: .utf8) else {
            return cachedPorts
        }

        let result = parseLsofOutput(output)
        lock.lock()
        cachedPorts = result
        cacheTimestamp = Date()
        lock.unlock()
        return result
    }

    /// Parse lsof output lines. Example line:
    /// `node    12345 user   23u  IPv4 0x...      0t0  TCP *:3000 (LISTEN)`
    /// Fields are whitespace-separated. PID is field index 1. The TCP address:port field contains `*:PORT` or `host:PORT`.
    private static func parseLsofOutput(_ output: String) -> [pid_t: [UInt16]] {
        var result: [pid_t: [UInt16]] = [:]
        let lines = output.components(separatedBy: "\n")

        for line in lines.dropFirst() { // skip header
            let fields = line.split(whereSeparator: { $0.isWhitespace })
            guard fields.count >= 9 else { continue }

            guard let pid = pid_t(fields[1]) else { continue }

            // The address:port field is typically at index 8
            let addressField = String(fields[8])
            if let colonIndex = addressField.lastIndex(of: ":") {
                let portString = addressField[addressField.index(after: colonIndex)...]
                if let port = UInt16(portString) {
                    result[pid, default: []].append(port)
                }
            }
        }

        // Deduplicate ports per pid
        for (pid, ports) in result {
            result[pid] = Array(Set(ports)).sorted()
        }

        return result
    }
}
