import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct CleanStackMacOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("CS", systemImage: model.menuBarSymbolName) {
            MenuBarContentView()
                .environmentObject(model)
                .frame(width: 340)
        }

        Window("CleanStack Dashboard", id: "dashboard") {
            DashboardView()
                .environmentObject(model)
                .frame(minWidth: 980, minHeight: 700)
        }

        Settings {
            SettingsView()
                .environmentObject(model)
                .frame(width: 520, height: 420)
        }
    }
}
