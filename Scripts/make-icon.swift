// Draws Shuck's app icon into an .iconset folder for iconutil:
//   swift Scripts/make-icon.swift build/AppIcon.iconset
// A paragraph of corn kernels on a husk-green squircle, on Apple's 1024pt macOS icon grid.
import AppKit
import QuartzCore

let canvas: CGFloat = 1024

func color(_ hex: UInt32) -> CGColor {
	CGColor(
		srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
		green: CGFloat((hex >> 8) & 0xFF) / 255,
		blue: CGFloat(hex & 0xFF) / 255,
		alpha: 1
	)
}

/// A continuous-corner rounded rect filled with a top-to-bottom gradient (layers are y-up on macOS).
func gradientLayer(_ frame: CGRect, radius: CGFloat, top: UInt32, bottom: UInt32) -> CAGradientLayer {
	let layer = CAGradientLayer()
	layer.frame = frame
	layer.cornerRadius = radius
	layer.cornerCurve = .continuous
	layer.masksToBounds = true
	layer.colors = [color(bottom), color(top)]
	return layer
}

func iconLayer() -> CALayer {
	let root = CALayer()
	root.frame = CGRect(x: 0, y: 0, width: canvas, height: canvas)

	let body = gradientLayer(CGRect(x: 100, y: 100, width: 824, height: 824), radius: 185.4, top: 0x6DB33F, bottom: 0x2E7D32)
	root.addSublayer(body)

	// Kernels laid out like a paragraph: full lines, then a short last line.
	let rows = [5, 5, 5, 2]
	let kernel = CGSize(width: 104, height: 76)
	let gap = CGSize(width: 8, height: 52)
	let left = (canvas - (5 * kernel.width + 4 * gap.width)) / 2
	let blockHeight = CGFloat(rows.count) * kernel.height + CGFloat(rows.count - 1) * gap.height
	let top = (canvas + blockHeight) / 2
	for (row, count) in rows.enumerated() {
		let y = top - CGFloat(row + 1) * kernel.height - CGFloat(row) * gap.height
		for column in 0..<count {
			let x = left + CGFloat(column) * (kernel.width + gap.width)
			let frame = CGRect(origin: CGPoint(x: x, y: y), size: kernel)
			root.addSublayer(gradientLayer(frame, radius: 26, top: 0xFFE27A, bottom: 0xF4A900))
		}
	}
	return root
}

func writePNG(_ layer: CALayer, pixels: Int, to url: URL) throws {
	let context = CGContext(
		data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
		space: CGColorSpace(name: CGColorSpace.sRGB)!,
		bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
	)!
	context.scaleBy(x: CGFloat(pixels) / canvas, y: CGFloat(pixels) / canvas)
	layer.render(in: context)
	guard let png = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:]) else {
		throw CocoaError(.fileWriteUnknown)
	}
	try png.write(to: url)
}

guard CommandLine.arguments.count == 2 else {
	FileHandle.standardError.write("usage: swift make-icon.swift <output.iconset>\n".data(using: .utf8)!)
	exit(1)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let layer = iconLayer()
for points in [16, 32, 128, 256, 512] {
	try writePNG(layer, pixels: points, to: output.appendingPathComponent("icon_\(points)x\(points).png"))
	try writePNG(layer, pixels: points * 2, to: output.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
