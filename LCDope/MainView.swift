
import SwiftUI

enum IterationType {
	case disabled
	case minutes, hours, days, years
}

struct MainView: View {

	@StateObject var menu: ObservableMenu
	@Environment(\.colorScheme) var colorScheme

    @Binding var document: LCDocument
	
	@State private var task: Task<Void, Never>? = nil
	var isRunning: Bool { task != nil }

	@State private var frame: Frame?
	@State private var popover = false
	@State public var iterate = IterationType.disabled
	private let birthDay = Date.now.isCristianBirthDay
	private let foundationDay = Date.now.isAppleFoudationDay
	public var numberFormatter: NumberFormatter = {
		var nf = NumberFormatter()
		nf.numberStyle = .decimal
		nf.maximumFractionDigits = 8
		nf.maximum = 90.0
		nf.minimum = -90.0
		nf.usesGroupingSeparator = false
		return nf
	}()
    var body: some View {
		let size = [
			DebugWidgetFamily.small : (w:  40, h:  40),
			DebugWidgetFamily.medium: (w: 100, h:  40),
			DebugWidgetFamily.large : (w: 100, h: 100),
		][menu.family] ?? (w: 0, h: 0)
		return VSplitView {
			PixelCanvas(with: size)
				.frame(minWidth: 450, maxWidth: .infinity, minHeight: 450, maxHeight: .infinity)
				.background(StripedBackground())
			if menu.console {
				Console().frame(maxWidth: .infinity, minHeight: 50)
			}
		} .toolbar {
			ToolbarItem(placement: .navigation) {
				Button("Debug", systemImage: isRunning ? "stop.fill" : "play.fill") {
					if isRunning {
						task?.cancel()
						task = nil
					} else {
						run(with: size)
					}
				} .help("Run Widget")
			}
			ToolbarItem(placement: .automatic) {
				Toggle("Grid", systemImage: "grid", isOn: $menu.grid)
					.help("Hide / Show Grid")
			}
			ToolbarItem(placement: .automatic) {
				Picker("Display Size", selection: $menu.family) {
					Image(systemName: "widget.small").tag(DebugWidgetFamily.small)
					Image(systemName: "widget.medium").tag(DebugWidgetFamily.medium)
					Image(systemName: "widget.large").tag(DebugWidgetFamily.large)
				} .pickerStyle(.segmented).help("Select Widget Size")
			}
			ToolbarItem(placement: .automatic) {
				Button("Tuning", systemImage: "wrench.and.screwdriver", action: {
					popover = true
				}).popover(isPresented: $popover, arrowEdge: .bottom) {
					VStack {
						GroupBox {
							HStack {
								Image(systemName: "calendar.badge.clock")
								Spacer()
								DatePicker("", selection: $menu.date).datePickerStyle(.stepperField)
							} .padding(5)
						}
						GroupBox {
							HStack {
								Image(systemName: "mappin.and.ellipse")
								TextField("Latitude", value: $menu.latitude, formatter: numberFormatter
									).textFieldStyle(.roundedBorder)
								Text("° 𝓝")
								TextField("Longitude", value: $menu.longitude, formatter: numberFormatter).textFieldStyle(.roundedBorder)
								Text("° 𝓔")
							} .padding(5)
						}
						GroupBox {
							HStack {
								Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
								Spacer()
								Picker("Iterate", selection: $iterate) {
									Text("Disabled").tag(IterationType.disabled)
									Text("Minutes").tag(IterationType.minutes)
									Text("Hours").tag(IterationType.hours)
									Text("Days").tag(IterationType.days)
									Text("Years").tag(IterationType.years)
								} .help("Select Iteration Type")
							} .padding(5)
						}
					} .padding(10)
				}
			}
		} .onAppear {
			menu.isMainViewActive = true
		} .onDisappear {
			menu.isMainViewActive = false
			if isRunning {
				task?.cancel()
				task = nil
			}
		} .onChange(of: menu.runAction) {
			if menu.runAction {
				run(with: size)
				menu.runAction = false
			}
		}
	}
	
	private func run(with size: (w: Int, h: Int)) {
		frame = driver(document.code, for: document.name, on: menu.date, with: size, in: [ menu.latitude, menu.longitude ])
		if frame == nil { return }
		menu.console = frame!.logs.count > 0
		if iterate == .disabled { return }
		var component: Calendar.Component
		switch iterate {
		case .minutes: component = .minute
		case .hours: component = .hour
		case .days: component = .day
		case .years: component = .year
		default: component = .minute
		}
		var offset = 0, date = menu.date
		task = Task {
			while !Task.isCancelled {
				try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
				date = Calendar.current.date(byAdding: component, value: offset, to: date)!
				frame = driver(document.code, for: document.name, on: date, with: size, in: [ menu.latitude, menu.longitude ])
				if frame == nil {
					task?.cancel()
					task = nil
					return
				}
				menu.console = frame!.logs.count > 0
				offset += 1
			}
		}
	}
	
	private func PixelCanvas(with size: (w: Int, h: Int)) -> some View {
		let space = menu.grid ? 1 : 0, pixel = menu.grid ? 2 : 3, box = pixel + space
		let padding = (x: 40, y: 40)
		let fw = CGFloat(size.w * box + space)
		let fh = CGFloat(size.h * box + space)
		let data: [[UInt32]]
		let back: Color
		if frame != nil && frame!.data.count * frame!.data[0].count != size.w * size.h {
			data = PlaceHolder(for: size).data
			back = .black
		} else {
			data = frame == nil ? PlaceHolder(for: size).data : frame!.data
			back = frame == nil ? .black : Color(rgb: frame!.back)
		}
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
			], thickness: 30, degrees: 90)
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
	@Previewable @StateObject var menu = ObservableMenu()
	MainView(menu: menu, document: .constant(LCDocument()))
		.frame(width: 550, height: 550)
		.windowFullScreenBehavior(.disabled)
}
