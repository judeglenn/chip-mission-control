import SwiftUI

// MARK: - Root View

struct ContentView: View {
    @EnvironmentObject var monitor: GatewayMonitor

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            Divider()
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    SectionContainer(title: "Gateway Status", icon: "server.rack") {
                        GatewayStatusView()
                    }
                    Divider().padding(.leading, 12)

                    SectionContainer(title: "Cron Jobs", icon: "clock.fill") {
                        CronJobsView()
                    }
                    Divider().padding(.leading, 12)

                    SectionContainer(title: "Active Projects", icon: "folder.badge.gearshape") {
                        ActiveProjectsView()
                    }
                    Divider().padding(.leading, 12)

                    SectionContainer(title: "Shortcuts", icon: "bolt.fill") {
                        ShortcutsView()
                    }
                    Divider().padding(.leading, 12)

                    SectionContainer(title: "System Info", icon: "info.circle.fill") {
                        SystemInfoView()
                    }

                    FooterView()
                }
            }
        }
        .frame(width: 340)
    }
}

// MARK: - Header

struct HeaderView: View {
    @EnvironmentObject var monitor: GatewayMonitor

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cpu")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.accentColor)
            Text("Chip Mission Control")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            if monitor.isLoading {
                ProgressView()
                    .scaleEffect(0.65)
                    .frame(width: 14, height: 14)
            }
            Button(action: { monitor.refresh() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help("Refresh now")
            .disabled(monitor.isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Footer

struct FooterView: View {
    @EnvironmentObject var monitor: GatewayMonitor

    var body: some View {
        VStack(spacing: 6) {
            Divider()
            HStack {
                if let last = monitor.lastRefresh {
                    Text("Updated \(relativeString(from: last))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func relativeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Section Container

struct SectionContainer<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .kerning(0.6)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            content()
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
        }
    }
}

// MARK: - Gateway Status

struct GatewayStatusView: View {
    @EnvironmentObject var monitor: GatewayMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 16, height: 16)
                    Circle()
                        .fill(statusColor)
                        .frame(width: 9, height: 9)
                }
                Text(statusLabel)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(statusColor)
                Spacer()
                Text("127.0.0.1:62314")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            if let pid = monitor.gatewayPID {
                HStack(spacing: 4) {
                    Text("PID")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(pid)
                        .font(.system(size: 11, design: .monospaced))
                }
            }

            Button(action: { monitor.restartGateway() }) {
                HStack(spacing: 5) {
                    if monitor.isRestartingGateway {
                        ProgressView()
                            .scaleEffect(0.55)
                            .frame(width: 10, height: 10)
                    } else {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                    }
                    Text(monitor.isRestartingGateway ? "Restarting…" : "Restart Gateway")
                        .font(.system(size: 11))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(monitor.isRestartingGateway)
        }
    }

    private var statusColor: Color {
        switch monitor.isHealthy {
        case true:  return .green
        case false: return .red
        case nil:   return .secondary
        }
    }

    private var statusLabel: String {
        switch monitor.isHealthy {
        case true:  return "UP"
        case false: return "DOWN"
        case nil:   return "CHECKING"
        }
    }
}

// MARK: - Cron Jobs

struct CronJobsView: View {
    @EnvironmentObject var monitor: GatewayMonitor

    var body: some View {
        if monitor.cronJobs.isEmpty {
            HStack {
                Text("No cron jobs found")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(monitor.cronJobs) { job in
                    CronJobRow(job: job)
                }
            }
        }
    }
}

struct CronJobRow: View {
    let job: CronJob

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(job.enabled ? Color.green : Color.secondary)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text(job.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                if let nextRun = job.nextRun {
                    Text("Next: \(nextRun)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if !job.schedule.isEmpty {
                    Text(job.schedule)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Active Projects

struct Project: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
}

struct ActiveProjectsView: View {
    let projects: [Project] = [
        Project(
            name: "OrchardPatch",
            description: "localhost:3000 · orchardpatch.com",
            icon: "laptopcomputer",
            color: Color(red: 0.18, green: 0.31, blue: 0.09),
            action: {
                if let url = URL(string: "http://localhost:3000") {
                    NSWorkspace.shared.open(url)
                }
            }
        ),
        Project(
            name: "QM Grant Strategy",
            description: "Google Doc",
            icon: "doc.text.fill",
            color: .green,
            action: {
                if let url = URL(string: "https://docs.google.com/document/d/1KVKd5reGiBQWlQ725YWYtb_gorrjuOOSb1bYtvmeMYU/edit") {
                    NSWorkspace.shared.open(url)
                }
            }
        ),
        Project(
            name: "ai-agent-homelab",
            description: "GitHub repo",
            icon: "chevron.left.forwardslash.chevron.right",
            color: .purple,
            action: {
                if let url = URL(string: "https://github.com/judeglenn/ai-agent-homelab") {
                    NSWorkspace.shared.open(url)
                }
            }
        ),
    ]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(projects) { project in
                Button(action: project.action) {
                    HStack(spacing: 9) {
                        Image(systemName: project.icon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(project.color)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(project.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text(project.description)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Shortcuts

struct ShortcutsView: View {
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                ActionButton(title: "Telegram", icon: "paperplane.fill", color: Color(red: 0.17, green: 0.60, blue: 0.87)) {
                    if let url = URL(string: "tg://") {
                        NSWorkspace.shared.open(url)
                    }
                }
                ActionButton(title: "Workspace", icon: "folder.fill", color: .blue) {
                    NSWorkspace.shared.open(
                        URL(fileURLWithPath: "/Users/chip/.openclaw/workspace")
                    )
                }
            }
            HStack(spacing: 6) {
                ActionButton(title: "Gateway Dashboard", icon: "globe", color: .green) {
                    if let url = URL(string: "http://127.0.0.1:62314") {
                        NSWorkspace.shared.open(url)
                    }
                }
                ActionButton(title: "View Logs", icon: "doc.text.fill", color: .orange) {
                    NSWorkspace.shared.open(
                        URL(fileURLWithPath: "/tmp/openclaw/")
                    )
                }
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

// MARK: - System Info

struct SystemInfoView: View {
    @EnvironmentObject var monitor: GatewayMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            InfoRow(label: "OpenClaw Version", value: monitor.version)
            InfoRow(label: "Gateway URL", value: "127.0.0.1:62314")
            InfoRow(label: "Auto-refresh", value: "Every 30s")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}
