import AppKit
import Foundation

let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

for size in [16, 32, 64, 128, 256, 512, 1024] {
    let side = CGFloat(size)
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                       pixelsWide: size, pixelsHigh: size,
                                       bitsPerSample: 8, samplesPerPixel: 4,
                                       hasAlpha: true, isPlanar: false,
                                       colorSpaceName: .deviceRGB,
                                       bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Could not create icon canvas at \(size)px")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let bounds = NSRect(x: 0, y: 0, width: side, height: side)
    let tile = NSBezierPath(roundedRect: bounds.insetBy(dx: side * 0.055, dy: side * 0.055),
                            xRadius: side * 0.23, yRadius: side * 0.23)
    NSGradient(starting: NSColor(red: 0.04, green: 0.32, blue: 0.58, alpha: 1),
               ending: NSColor(red: 0.01, green: 0.09, blue: 0.22, alpha: 1))!
        .draw(in: tile, angle: -60)

    let panel = NSBezierPath(roundedRect: bounds.insetBy(dx: side * 0.14, dy: side * 0.14),
                             xRadius: side * 0.18, yRadius: side * 0.18)
    NSColor.white.withAlphaComponent(0.13).setFill()
    panel.fill()
    NSColor.white.withAlphaComponent(0.32).setStroke()
    panel.lineWidth = max(1, side * 0.012)
    panel.stroke()

    let center = NSPoint(x: side * 0.5, y: side * 0.43)
    let radius = side * 0.24
    let arc = NSBezierPath()
    arc.appendArc(withCenter: center, radius: radius, startAngle: 15, endAngle: 165, clockwise: false)
    arc.lineWidth = max(2, side * 0.052)
    arc.lineCapStyle = .round
    NSColor.white.withAlphaComponent(0.9).setStroke()
    arc.stroke()

    let needle = NSBezierPath()
    needle.move(to: center)
    needle.line(to: NSPoint(x: side * 0.665, y: side * 0.565))
    needle.lineWidth = max(2, side * 0.044)
    needle.lineCapStyle = .round
    NSColor(red: 0.42, green: 0.95, blue: 0.89, alpha: 1).setStroke()
    needle.stroke()

    let hub = NSBezierPath(ovalIn: NSRect(x: center.x - side * 0.034,
                                         y: center.y - side * 0.034,
                                         width: side * 0.068, height: side * 0.068))
    NSColor.white.setFill()
    hub.fill()

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not render icon at \(size)px")
    }
    try png.write(to: directory.appendingPathComponent("icon_\(size).png"))
}
