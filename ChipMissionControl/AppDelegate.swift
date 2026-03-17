import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    let monitor = GatewayMonitor()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menubar-only: hide dock icon programmatically as well
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()

        monitor.$isHealthy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] healthy in
                self?.updateStatusIcon(healthy: healthy)
            }
            .store(in: &cancellables)

        monitor.startMonitoring()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        if let image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "Chip Mission Control") {
            image.isTemplate = true
            button.image = image
        }
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 560)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: ContentView().environmentObject(monitor)
        )
        self.popover = popover
    }

    // MARK: - Icon updates

    private func updateStatusIcon(healthy: Bool?) {
        guard let button = statusItem?.button else { return }

        let color: NSColor
        switch healthy {
        case true:  color = .systemGreen
        case false: color = .systemRed
        case nil:   color = .labelColor
        }

        button.contentTintColor = color
    }

    // MARK: - Popover toggle

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }

        if let popover, popover.isShown {
            popover.performClose(sender)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover?.contentViewController?.view.window?.makeKey()
        }
    }
}
