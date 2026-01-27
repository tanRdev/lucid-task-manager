import Foundation

struct PortScanner {
    /// Runs `lsof -iTCP -sTCP:LISTEN -n -P` and returns a dictionary mapping pid -> [port]
    static func getListeningPorts() -> [pid_t: [UInt16]] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return [:]
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else {
            return [:]
        }

        return parseLsofOutput(output)
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
