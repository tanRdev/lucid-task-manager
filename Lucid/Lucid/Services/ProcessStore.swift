import Foundation
import Observation

@Observable
@MainActor
final class ProcessStore {
    // MARK: - Observable State
    var processes: [LucidProcess] = []
    var activePorts: [UInt16] = []
    var filterCounts = FilterCounts()

    // MARK: - Derived State (Pre-computed for performance)
    private(set) var portProcessMap: [UInt16: [pid_t]] = [:]
    private var processByPid: [pid_t: LucidProcess] = [:]

    struct FilterCounts {
        var total: Int = 0
        var system: Int = 0
        var user: Int = 0
        var unknown: Int = 0
    }

    // MARK: - Public Methods

    func updateProcesses(_ newProcesses: [LucidProcess]) {
        let sorted = newProcesses.sorted()
        self.processes = sorted

        // Build lookup dictionary
        processByPid = Dictionary(
            uniqueKeysWithValues: sorted.map { ($0.pid, $0) }
        )

        // Calculate filter counts
        filterCounts = FilterCounts(
            total: sorted.count,
            system: sorted.filter { $0.safety == .system }.count,
            user: sorted.filter { $0.safety == .user }.count,
            unknown: sorted.filter { $0.safety == .unknown }.count
        )

        // Build port-to-process map for O(1) lookup
        var portMap: [UInt16: [pid_t]] = [:]
        for process in sorted {
            for port in process.ports {
                portMap[port, default: []].append(process.pid)
            }
        }
        portProcessMap = portMap
        activePorts = Array(portMap.keys).sorted()
    }

    func process(for pid: pid_t) -> LucidProcess? {
        processByPid[pid]
    }

    func processes(for port: UInt16) -> [pid_t] {
        portProcessMap[port] ?? []
    }

    func removeProcess(_ process: LucidProcess) {
        processes.removeAll { $0.pid == process.pid }
        processByPid.removeValue(forKey: process.pid)

        // Update port map
        for port in process.ports {
            portProcessMap[port]?.removeAll { $0 == process.pid }
            if portProcessMap[port]?.isEmpty == true {
                portProcessMap.removeValue(forKey: port)
                activePorts.removeAll { $0 == port }
            }
        }

        // Recalculate counts
        updateProcesses(processes)
    }
}