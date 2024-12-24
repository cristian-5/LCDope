
import SwiftUI
import CodeEditorView
import LanguageSupport

let jsConfiguration = LanguageConfiguration(
	name: "javascript",
	supportsSquareBrackets: true,
	supportsCurlyBrackets: true,
	stringRegex: try! Regex("'(?:\\.|(?!').)*?'|\"(?:\\.|(?!\").)*?\"|`(?:\\.|(?!`).)*?`"),
	characterRegex: try! Regex("/(?:\\.|(?!/).)*?/[gimsuy]*"),
	numberRegex: try! Regex("0(?:b[01]+|0[0-7]+|d?\\d+|x[0-9A-F]+)?|\\d+(?:\\.\\d+|[Ee][+-]\\d+)?"),
	singleLineComment: "//",
	nestedComment: (open: "/*", close: "*/"),
	identifierRegex: try! Regex("[$A-Za-z](?:\\w\\$)*"),
	operatorRegex: try! Regex("[+\\-*/%&|^!<>]=?|={1,3}|\\|\\||&&|<<|>>"),
	reservedIdentifiers: [
		"break", "case", "catch", "class", "continue", "const",
		"constructor", "debugger", "default", "delete", "do", "else",
		"export", "extends", "false", "finally", "for", "from", "function",
		"get", "if", "import", "in", "instanceof", "let", "new", "null",
		"return", "set", "super", "switch", "symbol", "this", "throw", "true",
		"try", "typeof", "undefined", "var", "void", "while", "with", "yield",
		"async", "await", "of"
	],
	reservedOperators: []
)
let jsLayout = CodeEditor.LayoutConfiguration(showMinimap: false, wrapText: true)

struct MainView: View {
	
	@Environment(\.colorScheme) var colorScheme

    @Binding var document: LCDocument
	@State private var debugPane = true
	@State private var consolePane = false

	@State private var debugging = false
	@State private var frame: Frame?
	
	@State private var position: CodeEditor.Position       = CodeEditor.Position()
	@State private var messages: Set<TextLocated<Message>> = Set()
	
	private let size = (w: 32, h: 32)
	private let birthDay = Date.now.isCristianBirthDay
	private let foundationDay = Date.now.isAppleFoudationDay
    var body: some View {
		return VSplitView {
			HSplitView {
				CodeEditor(
					text: $document.code,
					position: $position,
					messages: $messages,
					language: jsConfiguration,
					layout: jsLayout
				)
				.frame(minWidth: 550)
				.environment(\.codeEditorTheme, colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
				if debugPane {
					PixelCanvas(with: size)
						.frame(minWidth: 220, maxWidth: .infinity, maxHeight: .infinity)
						.background(StripedBackground())
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			if consolePane {
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
					if frame != nil && frame?.logs.count ?? 0 > 0 {
						consolePane = true
					}
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
				.Apple.logo0, .Apple.logo1, .Apple.logo2,
				.Apple.logo3, .Apple.logo4, .Apple.logo5
			], thickness: 20, degrees: 90)
		} else if birthDay {
			Stripes(colors: [
				.Rainbow.red, .Rainbow.orange, .Rainbow.yellow,
				.Rainbow.green, .Rainbow.blue, .Rainbow.indigo
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
