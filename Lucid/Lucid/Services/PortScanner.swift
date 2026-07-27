import Foundation

actor PortScanner {
    private var cachedPorts: [pid_t: [UInt16]] = [:]
    private var cacheTimestamp: Date = .distantPast
    private let cacheTTL: TimeInterval = 15.0
    private(set) var lastError: String?

    /// Runs `lsof -iTCP -sTCP:LISTEN -n -P` and returns a dictionary mapping pid -> [port].
    /// Results are cached for 15 seconds since port bindings change infrequently.
    func getListeningPorts() -> [pid_t: [UInt16]] {
        if Date().timeIntervalSince(cacheTimestamp) < cacheTTL {
            return cachedPorts
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            lastError = "Failed to run lsof: \(error.localizedDescription)"
            return cachedPorts
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0,
              let output = String(data: data, encoding: .utf8) else {
            lastError = "Port scan failed (exit \(process.terminationStatus))"
            return cachedPorts
        }

        let result = Self.parseLsofOutput(output)
        cachedPorts = result
        cacheTimestamp = Date()
        lastError = nil
        return result
    }

    /// Parse lsof output lines. Example line:
    /// `node    12345 user   23u  IPv4 0x...      0t0  TCP *:3000 (LISTEN)`
    private static func parseLsofOutput(_ output: String) -> [pid_t: [UInt16]] {
        var result: [pid_t: [UInt16]] = [:]
        let lines = output.components(separatedBy: "\n")

        for line in lines.dropFirst() {
            let fields = line.split(whereSeparator: { $0.isWhitespace })
            guard fields.count >= 9 else { continue }

            guard let pid = pid_t(fields[1]) else { continue }

            let addressField = String(fields[8])
            if let colonIndex = addressField.lastIndex(of: ":") {
                let portString = addressField[addressField.index(after: colonIndex)...]
                if let port = UInt16(portString) {
                    result[pid, default: []].append(port)
                }
            }
        }

        for (pid, ports) in result {
            result[pid] = Array(Set(ports)).sorted()
        }

        return result
    }
}
