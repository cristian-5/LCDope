
import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
	func placeholder(in context: Context) -> LCDEntry {
		LCDEntry(date: Date(), placeholder: true, family: context.family, configuration: DisplayIntent())
	}
	func snapshot(for configuration: DisplayIntent, in context: Context) async -> LCDEntry {
		LCDEntry(date: Date(), family: context.family, configuration: configuration)
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
			let entry = LCDEntry(date: date, family: context.family, configuration: configuration)
			entries.append(entry)
		}
		return Timeline(entries: entries, policy: .atEnd)
	}
}

struct LCDEntry: TimelineEntry {
	let date: Date
	var placeholder: Bool = false
	let family: WidgetFamily
	let configuration: DisplayIntent
}

struct DisplayEntryView : View {
	var entry: Provider.Entry
	@State var frameCount = 0
	var body: some View {
		let size = [
			.systemSmall : (w: 32, h: 32),
			.systemMedium: (w: 60, h: 24),
			.systemLarge : (w: 60, h: 60),
		][entry.family] ?? (w: 32, h: 32)
		let pixel = entry.family == .systemSmall ? 3 : 4
		let space = 1, box = pixel + space
		let fw = CGFloat(size.w * box + space)
		let fh = CGFloat(size.h * box + space)
		let file = entry.configuration.file()
		let frame: Frame? = file == nil ? nil : driver(
			file!, for: entry.configuration.driver?.fileURL?.absoluteString ?? "unknown",
			on: Date.now, with: size, in: entry.configuration.coords()
		)
		let data = frame == nil ? PlaceHolder(for: size).data : frame!.data
		let back: Color = frame == nil ? .black : Color(rgb: frame!.back)
		return Canvas { context, cgsize in
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
		.containerBackground(back, for: .widget)
	}
}

struct Display: Widget {
	let kind: String = "Display"
	var body: some WidgetConfiguration {
		AppIntentConfiguration(kind: kind, intent: DisplayIntent.self, provider: Provider()) {
			entry in DisplayEntryView(entry: entry)
		}
		.configurationDisplayName("LCDisplay")
		.description("Run your own LCD Widgets")
		.supportedFamilies([ .systemSmall, .systemMedium, .systemLarge ])
	}
}
