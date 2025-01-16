
import SwiftUI

@main
struct LCDopeApp: App {
	@StateObject var menu = ObservableMenu()
    var body: some Scene {
        DocumentGroup(newDocument: LCDocument()) { file in
			MainView(menu: menu, document: file.$document).onAppear {
				if let window = NSApplication.shared.windows.first {
					window.center()
				}
			}
		} .commands {
			DebugCommands(menu: menu)
		}
    }
}

enum DebugWidgetFamily {
	case small, medium, large
}
class ObservableMenu: ObservableObject {
	@Published var family: DebugWidgetFamily = .small
	@Published var grid: Bool = true
	@Published var canvas: Bool = true
	@Published var console: Bool = false // only concealable in menu
	@Published var runAction: Bool = false
	@Published var isMainViewActive: Bool = false
}

struct DebugCommands: Commands {
	@StateObject var menu: ObservableMenu
	var body: some Commands {
		CommandGroup(after: .sidebar) {
			Toggle("Canvas", isOn: $menu.canvas)
				.keyboardShortcut("\n", modifiers: [.option, .command])
			Button("Hide Console") {
				menu.console = false
			}
			.disabled(!menu.console)
			.keyboardShortcut("c", modifiers: [.option, .command])
			Divider()
		}
		CommandMenu("Debug") {
			Button("Run") {
				menu.runAction = true
			}
			.disabled(!menu.isMainViewActive)
			.keyboardShortcut("R", modifiers: [.command])
			Divider()
			Toggle("Pixel Grid", isOn: $menu.grid)
				.disabled(!menu.isMainViewActive)
				.keyboardShortcut("G", modifiers: [.command])
			Picker(selection: $menu.family, label: Text("Display Size")) {
				Text("Small\t(40x40)").tag(DebugWidgetFamily.small)
					.keyboardShortcut("1", modifiers: .command)
				Text("Medium\t(100x80)").tag(DebugWidgetFamily.medium)
					.keyboardShortcut("2", modifiers: .command)
				Text("Large\t(100x100)").tag(DebugWidgetFamily.large)
					.keyboardShortcut("3", modifiers: .command)
			}
			.disabled(!menu.isMainViewActive)
		}
	}
}

