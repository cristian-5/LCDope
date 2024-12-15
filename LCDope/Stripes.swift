
import SwiftUI

struct Stripes: View {
	var background: Color? = nil, foreground: Color? = nil
	var  thickness: CGFloat, spacing: CGFloat
	var     colors: [Color]? = nil
	var    degrees: Double
	init(background: Color, foreground: Color, thickness: CGFloat, spacing: CGFloat, degrees: Double = 0) {
		self.background = background
		self.foreground = foreground
		self.thickness  = thickness
		self.spacing    = spacing
		self.degrees    = degrees
	}
	init(colors: [Color], thickness: CGFloat = 20, degrees: Double = 0) {
		self.colors    = colors
		self.thickness = thickness
		self.spacing   = 0
		self.degrees   = degrees
	}
	var body: some View {
		GeometryReader { geometry in
			let side = max(geometry.size.width, geometry.size.height)
			let offset = -side / 2
			let items = Int(2 * side / (thickness + spacing))
			if foreground != nil {
				HStack(spacing: spacing) {
					ForEach(0 ..< items, id: \.self) { _ in
						foreground!.frame(width: thickness, height: 2 * side)
					}
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.rotationEffect(Angle(degrees: degrees), anchor: .center)
				.offset(x: offset, y: offset)
				.background(background!)
			} else {
				HStack(spacing: spacing) {
					ForEach(0 ..< items, id: \.self) { i in
						colors![i % colors!.count].frame(width: thickness, height: 2 * side)
					}
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.rotationEffect(Angle(degrees: degrees), anchor: .center)
				.offset(x: offset, y: offset)
			}
		}
		.clipped()
	}
}
