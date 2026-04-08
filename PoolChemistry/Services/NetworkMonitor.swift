import Foundation
import Network

// MARK: - Network Monitor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected: Bool = true
    @Published var connectionType: NWInterface.InterfaceType?

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Check Connection
    func checkConnection() async -> Bool {
        return isConnected
    }

    // MARK: - Wait for Connection
    func waitForConnection(timeout: TimeInterval = 10) async -> Bool {
        if isConnected { return true }

        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if isConnected { return true }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        return isConnected
    }
}
