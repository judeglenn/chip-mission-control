import Foundation
import Combine

struct CronJob: Identifiable {
    let id = UUID()
    let name: String
    let schedule: String
    let nextRun: String?
    let enabled: Bool
}

class GatewayMonitor: ObservableObject {
    @Published var isHealthy: Bool? = nil
    @Published var gatewayPID: String? = nil
    @Published var cronJobs: [CronJob] = []
    @Published var version: String = "–"
    @Published var isLoading: Bool = false
    @Published var lastRefresh: Date? = nil
    @Published var isRestartingGateway: Bool = false

    private var timer: Timer?
    private let gatewayURL = "http://127.0.0.1:62314/"

    func startMonitoring() {
        refresh()
        let t = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func refresh() {
        guard !isLoading else { return }
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let healthy = self.checkHealth()
            let pid = self.fetchGatewayPID()
            let crons = self.fetchCronJobs()
            let ver = self.fetchVersion()

            DispatchQueue.main.async {
                self.isHealthy = healthy
                self.gatewayPID = pid
                self.cronJobs = crons
                self.version = ver ?? "Unknown"
                self.isLoading = false
                self.lastRefresh = Date()
            }
        }
    }

    func restartGateway() {
        isRestartingGateway = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            _ = runCommand("openclaw", arguments: ["gateway", "restart"])
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self?.isRestartingGateway = false
                self?.refresh()
            }
        }
    }

    // MARK: - Private fetchers

    private func checkHealth() -> Bool {
        guard let url = URL(string: gatewayURL) else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 6
        let session = URLSession(configuration: config)

        let semaphore = DispatchSemaphore(value: 0)
        var result = false

        let task = session.dataTask(with: request) { _, response, error in
            if let http = response as? HTTPURLResponse {
                result = http.statusCode < 500
            } else {
                result = error == nil
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 7)
        return result
    }

    private func fetchGatewayPID() -> String? {
        // Try openclaw gateway status --json first
        let statusResult = runCommand("openclaw", arguments: ["gateway", "status", "--json"])
        if statusResult.exitCode == 0, !statusResult.output.isEmpty,
           let data = statusResult.output.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let pid = json["pid"] {
            return "\(pid)"
        }

        // Fallback: pgrep
        let pgrep = runCommand("pgrep", arguments: ["-f", "openclaw gateway"])
        if pgrep.exitCode == 0, !pgrep.output.isEmpty {
            return pgrep.output.components(separatedBy: "\n").first
        }
        return nil
    }

    private func fetchCronJobs() -> [CronJob] {
        let result = runCommand("openclaw", arguments: ["cron", "list", "--json"])
        guard result.exitCode == 0, !result.output.isEmpty,
              let data = result.output.data(using: .utf8) else { return [] }

        // Try array format
        if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return array.compactMap(parseCronJob)
        }
        // Try wrapped object { "jobs": [...] }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let jobs = obj["jobs"] as? [[String: Any]] {
            return jobs.compactMap(parseCronJob)
        }
        return []
    }

    private func parseCronJob(_ dict: [String: Any]) -> CronJob? {
        guard let name = dict["name"] as? String else { return nil }
        let schedule = dict["schedule"] as? String
            ?? dict["cron"] as? String
            ?? dict["expression"] as? String
            ?? ""
        let nextRun = dict["next_run"] as? String
            ?? dict["nextRun"] as? String
            ?? dict["next"] as? String
        let enabled = dict["enabled"] as? Bool ?? true
        return CronJob(name: name, schedule: schedule, nextRun: nextRun, enabled: enabled)
    }

    private func fetchVersion() -> String? {
        let result = runCommand("openclaw", arguments: ["--version"])
        guard result.exitCode == 0, !result.output.isEmpty else { return nil }
        return result.output
    }

    deinit {
        timer?.invalidate()
    }
}
