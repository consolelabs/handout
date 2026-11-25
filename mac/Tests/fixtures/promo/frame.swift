// frame.swift: puts a raw screen capture on a padded gradient background for the promo set.
//
// Usage: frame <light|dark> <corner radius in capture pixels, 0 keeps the capture's own corners> <in.png> <out.png>
//
// The padding is 20 percent of the capture's longer side, so every shot of the set has the same
// proportions. The capture keeps its own pixel size: nothing is scaled, so text stays sharp.
import AppKit
import CoreGraphics
import ImageIO

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("frame: \(message)\n".utf8))
    exit(1)
}

let args = CommandLine.arguments
guard args.count == 5, args[1] == "light" || args[1] == "dark", let radius = Double(args[2]) else {
    fail("usage: frame <light|dark> <corner radius> <in.png> <out.png>")
}
let dark = args[1] == "dark"
guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[3]) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fail("cannot read \(args[3])") }

let width = Double(image.width), height = Double(image.height)
let pad = (max(width, height) * 0.2).rounded()
let canvasWidth = Int(width + 2 * pad), canvasHeight = Int(height + 2 * pad)
let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let context = CGContext(data: nil, width: canvasWidth, height: canvasHeight, bitsPerComponent: 8, bytesPerRow: 0,
                              space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fail("no canvas") }

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [CGFloat((hex >> 16) & 255) / 255, CGFloat((hex >> 8) & 255) / 255, CGFloat(hex & 255) / 255, alpha])!
}

let stops = dark ? [color(0x10142B), color(0x2B2145)] : [color(0xDCE6FB), color(0xF4E8F6)]
let gradient = CGGradient(colorsSpace: space, colors: stops as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: CGFloat(canvasHeight)), end: CGPoint(x: CGFloat(canvasWidth), y: 0), options: [])

let rect = CGRect(x: pad, y: pad, width: width, height: height)
let scale = max(width, height) / 600
let shadowColor = color(0x000000, dark ? 0.6 : 0.26)
let shadowOffset = CGSize(width: 0, height: -18 * scale)
if radius > 0 {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.saveGState()
    context.setShadow(offset: shadowOffset, blur: 52 * scale, color: shadowColor)
    context.setFillColor(color(0x000000))
    context.addPath(path)
    context.fillPath()
    context.restoreGState()
    context.saveGState()
    context.addPath(path)
    context.clip()
    context.draw(image, in: rect)
    context.restoreGState()
    context.setStrokeColor(color(dark ? 0xFFFFFF : 0x000000, dark ? 0.16 : 0.1))
    context.setLineWidth(max(1, scale))
    context.addPath(CGPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.strokePath()
} else {
    context.saveGState()
    context.setShadow(offset: shadowOffset, blur: 52 * scale, color: shadowColor)
    context.draw(image, in: rect)
    context.restoreGState()
}

guard let framed = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[4]) as CFURL, "public.png" as CFString, 1, nil) else { fail("cannot write \(args[4])") }
CGImageDestinationAddImage(destination, framed, nil)
guard CGImageDestinationFinalize(destination) else { fail("cannot write \(args[4])") }
print("framed \(args[4]) \(canvasWidth)x\(canvasHeight)")
