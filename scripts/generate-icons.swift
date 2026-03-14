#!/usr/bin/env swift

import AppKit
import CoreGraphics
import CoreText

// MARK: - Shared: create heavy rounded font

func makeHeavyRoundedFont(size: CGFloat) -> CTFont {
    // Try SF Pro Rounded Heavy, fallback chain
    let candidates: [(String, CGFloat)] = [
        (".AppleSystemUIFontRounded-Heavy", size),
        (".AppleSystemUIFontRounded-Black", size),
    ]
    for (name, sz) in candidates {
        let f = CTFontCreateWithName(name as CFString, sz, nil)
        let actualName = CTFontCopyPostScriptName(f) as String
        if actualName.contains("Heavy") || actualName.contains("Black") || actualName.contains("Rounded") {
            return f
        }
    }
    // Manual approach: get rounded design, then add heavy trait
    let desc = NSFontDescriptor
        .preferredFontDescriptor(forTextStyle: .body)
        .withDesign(.rounded)
    let heavyDesc = desc?.addingAttributes([
        .traits: [NSFontDescriptor.TraitKey.weight: NSFont.Weight.heavy.rawValue]
    ])
    if let hd = heavyDesc, let f = NSFont(descriptor: hd, size: size) {
        return f as CTFont
    }
    return CTFontCreateWithName(".AppleSystemUIFontRounded-Bold" as CFString, size, nil)
}

// MARK: - Shared: create text path

func createTextPath(text: String, font: CTFont, canvasSize: CGFloat) -> (CGMutablePath, CGRect) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

    let textX = (canvasSize - bounds.width) / 2 - bounds.origin.x
    let textY = (canvasSize - bounds.height) / 2 - bounds.origin.y

    let runs = CTLineGetGlyphRuns(line) as! [CTRun]
    let path = CGMutablePath()

    for run in runs {
        let count = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: count)
        var positions = [CGPoint](repeating: .zero, count: count)
        CTRunGetGlyphs(run, CFRangeMake(0, count), &glyphs)
        CTRunGetPositions(run, CFRangeMake(0, count), &positions)
        let rf = (CTRunGetAttributes(run) as! [String: Any])[kCTFontAttributeName as String] as! CTFont

        for i in 0..<count {
            if let gp = CTFontCreatePathForGlyph(rf, glyphs[i], nil) {
                let t = CGAffineTransform(translationX: textX + positions[i].x, y: textY + positions[i].y)
                path.addPath(gp, transform: t)
            }
        }
    }
    return (path, bounds)
}

// MARK: - Gradient colors (shared)

let gradientColors = [
    CGColor(red: 0.40, green: 0.65, blue: 1.0, alpha: 1.0),
    CGColor(red: 0.58, green: 0.48, blue: 1.0, alpha: 1.0),
    CGColor(red: 0.82, green: 0.42, blue: 0.88, alpha: 1.0),
    CGColor(red: 0.95, green: 0.55, blue: 0.65, alpha: 1.0),
]

// MARK: - App Icon Generator

func generateAppIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.22
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Dark gradient background
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let bgColors = [
        CGColor(red: 0.06, green: 0.06, blue: 0.14, alpha: 1.0),
        CGColor(red: 0.10, green: 0.08, blue: 0.22, alpha: 1.0),
        CGColor(red: 0.06, green: 0.06, blue: 0.16, alpha: 1.0),
    ]
    let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bgColors as CFArray, locations: [0.0, 0.5, 1.0])!
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    ctx.restoreGState()

    // Subtle border
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.setStrokeColor(CGColor(red: 0.35, green: 0.4, blue: 0.8, alpha: 0.25))
    ctx.setLineWidth(s * 0.008)
    ctx.strokePath()
    ctx.restoreGState()

    // Text path
    let font = makeHeavyRoundedFont(size: s * 0.44)
    let (textPath, _) = createTextPath(text: "GF", font: font, canvasSize: s)

    // Glow behind text
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.setShadow(offset: .zero, blur: s * 0.06, color: CGColor(red: 0.45, green: 0.4, blue: 1.0, alpha: 0.6))
    ctx.addPath(textPath)
    ctx.setFillColor(CGColor(red: 0.45, green: 0.4, blue: 1.0, alpha: 0.4))
    ctx.fillPath()
    ctx.restoreGState()

    // Gradient text
    ctx.saveGState()
    ctx.addPath(textPath)
    ctx.clip()
    let textGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: [0.0, 0.35, 0.7, 1.0])!
    ctx.drawLinearGradient(textGradient, start: CGPoint(x: s * 0.1, y: s * 0.75), end: CGPoint(x: s * 0.9, y: s * 0.25), options: [])
    ctx.restoreGState()

    image.unlockFocus()
    return image
}

// MARK: - Menu Bar Icon Generator (color gradient)

func generateMenuBarIcon(height: Int, scale: Int) -> NSImage {
    let ph = height * scale
    let fontSize = CGFloat(ph) * 0.78
    let font = makeHeavyRoundedFont(size: fontSize) as NSFont

    let attrs: [NSAttributedString.Key: Any] = [.font: font]
    let textSize = ("GF" as NSString).size(withAttributes: attrs)

    let pw = Int(ceil(textSize.width)) + 4 * scale
    let pointW = pw / scale
    let pointH = height

    // Step 1: Draw white text on transparent to create a mask
    let maskRep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pw, pixelsHigh: ph,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    maskRep.size = NSSize(width: pw, height: ph)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: maskRep)
    let whiteAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
    let drawPoint = NSPoint(
        x: (CGFloat(pw) - textSize.width) / 2,
        y: (CGFloat(ph) - textSize.height) / 2
    )
    ("GF" as NSString).draw(at: drawPoint, withAttributes: whiteAttrs)
    NSGraphicsContext.restoreGraphicsState()

    // Step 2: Create gradient image
    let gradRep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pw, pixelsHigh: ph,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    gradRep.size = NSSize(width: pw, height: ph)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: gradRep)
    if let ctx = NSGraphicsContext.current?.cgContext {
        let dw = CGFloat(pw)
        let dh = CGFloat(ph)

        // Use mask from text
        if let maskCG = maskRep.cgImage {
            ctx.clip(to: CGRect(x: 0, y: 0, width: dw, height: dh), mask: maskCG)
        }

        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: [0.0, 0.35, 0.7, 1.0])!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: dh * 0.85), end: CGPoint(x: dw, y: dh * 0.15), options: [])
    }
    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: NSSize(width: pointW, height: pointH))
    image.addRepresentation(gradRep)
    image.isTemplate = false
    return image
}

// MARK: - Save helpers

func savePNG(_ image: NSImage, to path: String, size: Int) {
    let targetSize = NSSize(width: size, height: size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = targetSize

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(origin: .zero, size: targetSize),
               from: NSRect(origin: .zero, size: image.size),
               operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(path)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path) (\(size)x\(size))")
    } catch {
        print("Error saving \(path): \(error)")
    }
}

// MARK: - Main

let baseDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let resourceDir = "\(baseDir)/Resources"

let appIcon = generateAppIcon(size: 1024)

let iconsetDir = "\(resourceDir)/AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let iconSizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, size) in iconSizes {
    savePNG(appIcon, to: "\(iconsetDir)/\(name).png", size: size)
}

let menuBarDir = "\(resourceDir)/MenuBarIcon"
try? FileManager.default.removeItem(atPath: menuBarDir)
try? FileManager.default.createDirectory(atPath: menuBarDir, withIntermediateDirectories: true)

// Generate color gradient menu bar icons (non-square, auto-width)
let menuIcon1x = generateMenuBarIcon(height: 18, scale: 1)
let menuIcon2x = generateMenuBarIcon(height: 18, scale: 2)

func saveMenuBarPNG(_ image: NSImage, to path: String) {
    let w = Int(image.size.width)
    let h = Int(image.size.height)
    // Find the actual bitmap rep
    guard let rep = image.representations.first as? NSBitmapImageRep,
          let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed: \(path)")
        return
    }
    try! pngData.write(to: URL(fileURLWithPath: path))
    print("Saved: \(path) (\(w)x\(h) pt)")
}

saveMenuBarPNG(menuIcon1x, to: "\(menuBarDir)/menubar-icon.png")
saveMenuBarPNG(menuIcon2x, to: "\(menuBarDir)/menubar-icon@2x.png")

print("\nDone!")
