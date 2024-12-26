
import SwiftUI
import CoreLocation
import CodeEditorView
import LanguageSupport

let jsConfiguration = LanguageConfiguration(
	name: "javascript",
	supportsSquareBrackets: true,
	supportsCurlyBrackets: true,
	stringRegex: try! Regex("'(?:(?!').)*?'|\"(?:(?!\").)*?\"|/(?:(?!/).)*?/[gimsuy]*"),
	characterRegex: try! Regex("`(?:(?!`).)*?`"),
	numberRegex: try! Regex("0x[0-9A-Fa-f]+|\\d+(?:\\.\\d+|[Ee][+-]\\d+)?"),
	singleLineComment: "//",
	nestedComment: (open: "/*", close: "*/"),
	identifierRegex: try! Regex("[$A-Za-z_][$0-9A-Za-z_]*"),
	operatorRegex: try! Regex("[+\\-*/%&|^!<>=]+"),
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

let lightTheme = Theme(
	colourScheme: .light,
	fontName: "SFMono-Medium",
	fontSize: 14.0,
	textColour: OSColor.black,
	commentColour: OSColor(red: 0.365, green: 0.422, blue: 0.475, alpha: 1.0),
	stringColour: OSColor(red: 0.77, green: 0.10, blue: 0.086, alpha: 1.0),
	characterColour: OSColor(red: 0.77, green: 0.10, blue: 0.086, alpha: 1.0),
	numberColour: OSColor(red: 0.11, green: 0, blue: 0.81, alpha: 1.0),
	identifierColour: OSColor(red: 0.194, green: 0.429, blue: 0.455, alpha: 1.0),
	operatorColour: OSColor.black,
	keywordColour: OSColor(red: 0.608, green: 0.138, blue: 0.576, alpha: 1.0),
	symbolColour: OSColor.black,
	typeColour: OSColor.black,
	fieldColour: OSColor.black,
	caseColour: OSColor.black,
	backgroundColour: OSColor.white,
	currentLineColour: OSColor(red: 0.933, green: 0.961, blue: 0.966, alpha: 1.0),
	selectionColour: OSColor(red: 0.725, green: 0.839, blue: 0.984, alpha: 1.0),
	cursorColour: OSColor(red: 0.041, green: 0.375, blue: 0.998, alpha: 1.0),
	invisiblesColour: OSColor.black
)

let darkTheme = Theme(
	colourScheme: .dark,
	fontName: "SFMono-Medium",
	fontSize: 14.0,
	textColour: OSColor(red: 1, green: 1, blue: 1, alpha: 0.85),
	commentColour: OSColor(red: 0.424, green: 0.475, blue: 0.525, alpha: 1.0),
	stringColour: OSColor(red: 0.989, green: 0.416, blue: 0.366, alpha: 1.0),
	characterColour: OSColor(red: 0.989, green: 0.416, blue: 0.366, alpha: 1.0),
	numberColour: OSColor(red: 0.815, green: 0.749, blue: 0.412, alpha: 1.0),
	identifierColour: OSColor(red: 0.404, green: 0.718, blue: 0.643, alpha: 1.0),
	operatorColour: OSColor(red: 1, green: 1, blue: 1, alpha: 0.85),
	keywordColour: OSColor(red: 0.988, green: 0.374, blue: 0.638, alpha: 1.0),
	symbolColour: OSColor.black,
	typeColour: OSColor.black,
	fieldColour: OSColor.black,
	caseColour: OSColor.black,
	backgroundColour: OSColor(red: 0.121, green: 0.123, blue: 0.141, alpha: 1.0),
	currentLineColour: OSColor(red: 0.139, green: 0.147, blue: 0.169, alpha: 1.0),
	selectionColour: OSColor(red: 0.318, green: 0.357, blue: 0.439, alpha: 1.0),
	cursorColour: OSColor(red: 0.041, green: 0.375, blue: 0.998, alpha: 1.0),
	invisiblesColour: OSColor.black
)

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
				.environment(\.codeEditorTheme, colorScheme == .dark ? darkTheme : lightTheme)
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
					if frame != nil { consolePane = (frame?.logs.count ?? 0) > 0 }
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
