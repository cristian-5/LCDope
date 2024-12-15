
import SwiftUI

@main
struct LCDopeApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: LCDocument()) { file in
			MainView(document: file.$document).onAppear {
				if let window = NSApplication.shared.windows.first {
					window.center()
				}
			}
		}
    }
}
