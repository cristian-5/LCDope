
import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
	func placeholder(in context: Context) -> LCDEntry {
		LCDEntry(date: Date(), placeholder: true, configuration: DisplayIntent())
	}
	func snapshot(for configuration: DisplayIntent, in context: Context) async -> LCDEntry {
		LCDEntry(date: Date(), configuration: configuration)
	}
	func timeline(for configuration: DisplayIntent, in context: Context) async -> Timeline<LCDEntry> {
		var entries: [LCDEntry] = []
		let interval = min( // 1s ... 12h
			max(1, Int(configuration.interval.converted(to: .seconds).value)),
			43200 // 12h
		), start = Calendar.current.nextDate(
			after: Date.now, matching: DateComponents(second: 0),
			matchingPolicy: .nextTime
		) ?? Date.now
		for offset in 0 ..< 5 { // generates 5 snapshots:
			let date = Calendar.current.date(byAdding: .second, value: offset * interval, to: start)!
			let entry = LCDEntry(date: date, configuration: configuration)
			entries.append(entry)
		}
		return Timeline(entries: entries, policy: .atEnd)
	}
}

struct LCDEntry: TimelineEntry {
	let date: Date
	var placeholder: Bool = false
	let configuration: DisplayIntent
}

struct DisplayEntryView : View {
	var entry: Provider.Entry
	@State var frameCount = 0
	var body: some View {
		let pixel = 3, space = 1, box = pixel + space
		let size = (w: 32, h: 32)
		let fw = CGFloat(size.w * box + space)
		let fh = CGFloat(size.h * box + space)
		let frame: Frame? = driver(
			entry.configuration.file() ?? "",
			for: entry.configuration.driver?.fileURL?.absoluteString ?? "unknown",
			on: Date.now, with: size
		)
		let data = frame == nil ? PlaceHolder(for: size).data : frame!.data
		let back: Color = frame == nil ? .red : Color(rgb: frame!.back)
		return ZStack {
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
			.clipShape(RoundedRectangle(cornerRadius: 6))
			RoundedRectangle(cornerRadius: 8)
				.stroke(Color.black.opacity(0.25), lineWidth: 16).blur(radius: 10)
				.mask(RoundedRectangle(cornerRadius: 6).fill(RadialGradient(
					gradient: Gradient(colors: [.black, .clear]),
					center: .center, startRadius: 100, endRadius: 120
				)))
		}
	}
}

struct Display: Widget {
	let kind: String = "Display"
	var body: some WidgetConfiguration {
		AppIntentConfiguration(kind: kind, intent: DisplayIntent.self, provider: Provider()) {
			entry in DisplayEntryView(entry: entry).containerBackground(.bezel, for: .widget)
		}
		.configurationDisplayName("LCDisplay")
		.description("Run your own LCD Widgets")
		.supportedFamilies([ .systemSmall ])
	}
}
