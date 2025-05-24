
import SwiftUI

struct Stripes: View {
	var background: Color? = nil, foreground: Color? = nil
	var thickness: CGFloat, spacing: CGFloat
	var colors: [Color]? = nil
	var degrees: Double
	
	init(background: Color, foreground: Color, thickness: CGFloat, spacing: CGFloat, degrees: Double = 0) {
		self.background = background
		self.foreground = foreground
		self.thickness = thickness
		self.spacing = spacing
		self.degrees = degrees
	}
	
	init(colors: [Color], thickness: CGFloat = 20, degrees: Double = 0) {
		self.colors = colors
		self.thickness = thickness
		self.spacing = 0
		self.degrees = degrees
	}
	
	var body: some View {
		GeometryReader { geo in
			let side = 2000.0 // A large fixed size for drawing stripes offscreen
			let total = Int((side * 2) / (thickness + spacing))
			ZStack {
				if let background = background {
					background
				}
				Canvas { context, size in
					context.rotate(by: .degrees(degrees))
					let origin = CGPoint(x: -side, y: -side)
					for i in 0..<total {
						let x = CGFloat(i) * (thickness + spacing)
						let rect = CGRect(x: origin.x + x, y: origin.y, width: thickness, height: side * 2)
						if let foreground = foreground {
							context.fill(Path(rect), with: .color(foreground))
						} else if let colors = colors {
							context.fill(Path(rect), with: .color(colors[i % colors.count]))
						}
					}
				}
			}
			.frame(width: geo.size.width, height: geo.size.height)
			.clipped()
		}
	}

}

