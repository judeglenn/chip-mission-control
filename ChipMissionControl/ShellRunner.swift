import Foundation

struct ShellResult {
    let output: String
    let error: String
    let exitCode: Int32
}

func runCommand(_ executable: String, arguments: [String] = []) -> ShellResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments

    // Ensure common install paths are in PATH for GUI apps
    var environment = ProcessInfo.processInfo.environment
    let extraPaths = "/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
    if let existing = environment["PATH"] {
        environment["PATH"] = extraPaths + ":" + existing
    } else {
        environment["PATH"] = extraPaths
    }
    process.environment = environment

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        return ShellResult(output: "", error: error.localizedDescription, exitCode: -1)
    }

    let output = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let errorOutput = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    return ShellResult(output: output, error: errorOutput, exitCode: process.terminationStatus)
}
