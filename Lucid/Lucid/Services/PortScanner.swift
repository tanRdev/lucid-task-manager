import Foundation

actor PortScanner {
    private var cachedPorts: [pid_t: [UInt16]] = [:]
    private var cacheTimestamp: Date = .distantPast
    private let cacheTTL: TimeInterval = 15.0
    private(set) var lastError: String?

    /// Blocking lsof runs on a dedicated GCD queue — never on the cooperative
    /// pool, where a 100ms–1s+ read would stall unrelated tasks.
    private let ioQueue = DispatchQueue(label: "com.tan.lucid.portscanner", qos: .utility)

    /// Separate queue for the watchdog — `ioQueue` is serial and blocked on
    /// the pipe read, so the timeout cannot fire from it.
    private static let timeoutQueue = DispatchQueue(label: "com.tan.lucid.portscanner.timeout")

    /// A wedged lsof would block `readDataToEndOfFile` forever; the sample
    /// task would never finish and the whole monitor would stop refreshing.
    private static let lsofTimeout: TimeInterval = 10

    /// Runs `lsof -iTCP -sTCP:LISTEN -n -P -F pn` and returns pid -> [port].
    /// Results are cached for 15 seconds since port bindings change infrequently.
    func getListeningPorts() async -> [pid_t: [UInt16]] {
        if Date().timeIntervalSince(cacheTimestamp) < cacheTTL {
            return cachedPorts
        }

        let result = await withCheckedContinuation { continuation in
            ioQueue.async {
                continuation.resume(returning: Self.runLsof())
            }
        }

        switch result {
        case .failure(let error):
            lastError = error.message
            return cachedPorts
        case .success(let output):
            let parsed = Self.parseLsofOutput(output)
            cachedPorts = parsed
            cacheTimestamp = Date()
            lastError = nil
            return parsed
        }
    }

    private enum LsofError: Error {
        case launchFailed(String)
        case nonZeroExit(Int32)
        case timedOut(TimeInterval)

        var message: String {
            switch self {
            case .launchFailed(let description):
                return "Failed to run lsof: \(description)"
            case .nonZeroExit(let status):
                return "Port scan failed (exit \(status))"
            case .timedOut(let timeout):
                return "Port scan timed out after \(Int(timeout))s"
            }
        }
    }

    private static func runLsof() -> Result<String, LsofError> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        // -F pn: machine-readable field output (p = pid, n = name) instead of
        // whitespace-aligned columns, so parsing does not depend on field position.
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P", "-F", "pn"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return .failure(.launchFailed(error.localizedDescription))
        }

        // Watchdog: kill lsof if the pipe read outlives the deadline.
        let watchdog = DispatchWorkItem { [process] in
            if process.isRunning { process.terminate() }
        }
        timeoutQueue.asyncAfter(deadline: .now() + lsofTimeout, execute: watchdog)

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        watchdog.cancel()

        if process.terminationReason == .uncaughtSignal {
            return .failure(.timedOut(lsofTimeout))
        }

        guard process.terminationStatus == 0,
              let output = String(data: data, encoding: .utf8) else {
            return .failure(.nonZeroExit(process.terminationStatus))
        }
        return .success(output)
    }

    /// Parse `lsof -F pn` output. Each process record is a `p<pid>` line followed
    /// by one `n<name>` line per file descriptor, e.g.:
    /// ```
    /// p12345
    /// n*:3000
    /// n127.0.0.1:8080
    /// ```
    static func parseLsofOutput(_ output: String) -> [pid_t: [UInt16]] {
        var result: [pid_t: [UInt16]] = [:]
        var currentPID: pid_t?

        for line in output.split(separator: "\n") {
            guard let field = line.first else { continue }
            let value = line.dropFirst()

            switch field {
            case "p":
                currentPID = pid_t(value)
            case "n":
                guard let pid = currentPID else { continue }
                // Defend against a trailing annotation such as " (LISTEN)".
                let address = value.split(whereSeparator: { $0.isWhitespace }).first ?? value
                guard let colonIndex = address.lastIndex(of: ":") else { continue }
                let portString = address[address.index(after: colonIndex)...]
                if let port = UInt16(portString) {
                    result[pid, default: []].append(port)
                }
            default:
                continue
            }
        }

        for (pid, ports) in result {
            result[pid] = Array(Set(ports)).sorted()
        }

        return result
    }
}
