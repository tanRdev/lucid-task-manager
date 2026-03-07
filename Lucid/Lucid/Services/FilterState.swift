import SwiftUI
import Observation

@Observable
@MainActor
final class FilterState {
    // MARK: - State
    var selectedFilter: FilterCategory = .all
    var searchText: String = "" {
        didSet {
            handleSearchTextChange()
        }
    }
    var debouncedSearchText: String = ""
    var sortOrder: [KeyPathComparator<LucidProcess>] = [
        .init(\.cpuUsage, order: .reverse)
    ]

    // MARK: - Private State
    private var debounceTask: Task<Void, Never>?
    private let debounceInterval: Duration = .milliseconds(300)

    // MARK: - Public Methods

    func applyFilter(_ filter: FilterCategory) {
        selectedFilter = filter
    }

    func clearSearch() {
        searchText = ""
        debouncedSearchText = ""
        debounceTask?.cancel()
    }

    func applySortOrder(_ order: [KeyPathComparator<LucidProcess>]) {
        sortOrder = order
    }

    // MARK: - Filtering

    func filter(_ processes: [LucidProcess]) -> [LucidProcess] {
        var result = processes

        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .system:
            result = result.filter { $0.safety == .system }
        case .user:
            result = result.filter { $0.safety == .user }
        case .unknown:
            result = result.filter { $0.safety == .unknown }
        case .port(let port):
            result = result.filter { $0.ports.contains(port) }
        }

        // Apply search filter (using debounced value)
        if !debouncedSearchText.isEmpty {
            result = result.filter { process in
                process.name.localizedCaseInsensitiveContains(debouncedSearchText) ||
                process.description.localizedCaseInsensitiveContains(debouncedSearchText)
            }
        }

        // Apply sort
        result.sort(using: sortOrder)

        return result
    }

    // MARK: - Private Methods

    private func handleSearchTextChange() {
        debounceTask?.cancel()

        debounceTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(for: self.debounceInterval)

            guard !Task.isCancelled else { return }

            self.debouncedSearchText = self.searchText
        }
    }
}