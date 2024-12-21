
import SwiftUI
import SwiftyMonaco

struct MainView: View {
    @Binding var document: LCDocument
	@State private var debugPane = true
	@State private var consolePane = true

	@State private var debugging = false
	@State private var frame: Frame?
	private static let syntax = Bundle.main.url(
		forResource: "JSLanguage", withExtension: "js"
	)!
	private let size = (w: 32, h: 32)
	private let birthDay = Date.now.isCristianBirthDay
	private let foundationDay = Date.now.isAppleFoudationDay
    var body: some View {
		return VSplitView {
			HSplitView {
				SwiftyMonaco(text: $document.code).syntaxHighlight(SyntaxHighlight(title: "JavaScript", fileURL: MainView.syntax)).minimap(false)
					.frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
				if debugPane {
					PixelCanvas(with: size)
						.frame(minWidth: 220, maxWidth: .infinity, maxHeight: .infinity)
						.background(StripedBackground())
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			if consolePane {
				StatusBar().frame(maxWidth: .infinity)
				Console().frame(maxWidth: .infinity, minHeight: 50)
			}
		} .toolbar {
			ToolbarItem(placement: .automatic) {
				Toggle("Console Pane", systemImage: "inset.filled.bottomhalf.rectangle", isOn: $consolePane)
					.help("Hide / Show Console Pane")
			}
			ToolbarItem(placement: .automatic) {
				Toggle("Debug Pane", systemImage: "sidebar.squares.trailing", isOn: $debugPane)
					.help("Hide / Show Debug Pane")
			}
			ToolbarItem(placement: .navigation) {
				Button("Debug", systemImage: "play.fill") {
					frame = driver(document.code, for: document.name, on: Date.now, with: size)
				} .disabled(debugging).help("Run Widget")
			}
		}
	}
	
	private func PixelCanvas(with size: (w: Int, h: Int)) -> some View {
		let pixel = 3, space = 1, box = pixel + space
		let padding = (x: 40, y: 40)
		let fw = CGFloat(size.w * box + space)
		let fh = CGFloat(size.h * box + space)
		let data = frame == nil ? PlaceHolder(for: size).data : frame!.data
		let back: Color = frame == nil ? .black : Color(rgb: frame!.back)
		return ZStack {
			RoundedRectangle(cornerRadius: 20).fill(back).frame(
				width: fw + CGFloat(padding.x), height: fh + CGFloat(padding.y)
			).shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 0)
			Canvas { context, cgsize in
				let rect = CGRect(origin: CGPoint.zero, size: cgsize)
				context.fill(Path(rect), with: .color(back))
				let SIZE = CGSize(width: pixel, height: pixel)
				for i in 0 ..< size.h {
					for j in 0 ..< size.w {
						let origin = CGPoint(x: j * box + space, y: i * box + space)
						let square = CGRect(origin: origin, size: SIZE)
						context.fill(Path(square), with: .color(Color(rgb: data[i][j])))
					}
				}
			}
			.frame(width: fw, height: fh)
		}
	}
	
	private func StatusBar() -> some View {
		HStack(alignment: .top, spacing: 8) {
			Button("Clear", systemImage: "trash") {
				frame!.logs.removeAll()
			}
			.disabled(frame == nil || frame!.logs.isEmpty)
			.labelStyle(.iconOnly)
			.buttonStyle(.borderless)
			Divider().frame(height: 12).padding(2)
			Spacer()
			Button("Logs Pane", systemImage: "inset.filled.bottomthird.square") {
				consolePane.toggle()
			}
			.labelStyle(.iconOnly)
			.buttonStyle(.borderless)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 6)
		.background(.splitter)
	}
	
	private func Console() -> some View {
		ScrollView {
			VStack(spacing: 0) {
				ForEach(frame == nil ? [LogEntry]() : frame!.logs, id: \.id) { entry in
					Text(entry.message)
						.font(.system(size: 14, weight: .regular, design: .monospaced))
						.foregroundStyle(Color.text)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(10)
						.background(entry.type.background)
						.textSelection(.enabled)
						.overlay(alignment: .bottom) {
							Rectangle()
								.frame(height: 1)
								.background(Color.text)
								.opacity(0.1)
						}
				}
			}
		}
		.listStyle(SidebarListStyle())
		.scrollContentBackground(.hidden)
		.background(Color.console)
	}
	
	private func StripedBackground() -> some View {
		if foundationDay {
			Stripes(colors: [
				.Apple.logo0,
				.Apple.logo1,
				.Apple.logo2,
				.Apple.logo3,
				.Apple.logo4,
				.Apple.logo5
			], thickness: 20, degrees: 90)
		} else if birthDay {
			Stripes(colors: [
				.Rainbow.red,
				.Rainbow.orange,
				.Rainbow.yellow,
				.Rainbow.green,
				.Rainbow.blue,
				.Rainbow.indigo
			], thickness: 20, degrees: 45)
		} else {
			Stripes(
				background: .Canvas.background, foreground: .Canvas.foreground,
				thickness: 80, spacing: 100, degrees: 40
			)
		}
	}

}

#Preview {
	MainView(document: .constant(LCDocument()))
}
