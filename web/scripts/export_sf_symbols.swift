import AppKit
import Foundation

// Export SF Symbols used by LiveSport as template PNGs for the marketing mega-menu.
let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "web/assets/sf-symbols")

try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let symbols: [String] = [
    "figure.run",
    "figure.walk",
    "figure.hiking",
    "figure.outdoor.cycle",
    "bicycle",
    "figure.strengthtraining.traditional",
    "figure.cross.training",
    "timer",
    "figure.tennis",
    "figure.badminton",
    "figure.pickleball",
    "figure.squash",
    "figure.pool.swim",
    "surfboard",
    "figure.sailing",
    "figure.surfing",
    "figure.rower",
    "figure.outdoor.rowing",
    "oar.2.crossed",
    "sailboat",
    "figure.skiing.downhill",
    "figure.snowboarding",
    "figure.skiing.crosscountry",
    "figure.ice.skating",
    "figure.indoor.soccer",
    "figure.basketball",
    "figure.volleyball",
    "figure.american.football",
    "figure.baseball",
    "figure.field.hockey",
    "figure.lacrosse",
    "figure.rugby",
    "figure.boxing",
    "figure.kickboxing",
    "figure.martial.arts",
    "figure.wrestling",
    "dumbbell",
    "figure.core.training",
    "figure.golf",
    "figure.climbing",
    "figure.dance",
    "figure.pilates",
    "figure.skating",
    "figure.yoga",
    "figure.flexibility",
    "figure.mixed.cardio",
]

let pointSize: CGFloat = 64
let padding: CGFloat = 8

func render(_ name: String) -> NSImage? {
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil) else {
        return nil
    }
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.black]))
    let img = base.withSymbolConfiguration(config) ?? base
    let size = NSSize(width: pointSize + padding * 2, height: pointSize + padding * 2)
    let canvas = NSImage(size: size)
    canvas.lockFocus()
    NSColor.clear.setFill()
    NSRect(origin: .zero, size: size).fill()
    let drawn = img.size
    let origin = NSPoint(x: (size.width - drawn.width) / 2, y: (size.height - drawn.height) / 2)
    img.draw(in: NSRect(origin: origin, size: drawn),
             from: .zero,
             operation: .sourceOver,
             fraction: 1.0)
    canvas.unlockFocus()
    return canvas
}

func pngData(_ image: NSImage) -> Data? {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else { return nil }
    rep.size = image.size
    return rep.representation(using: .png, properties: [:])
}

var ok = 0
var fail: [String] = []
for name in symbols {
    let file = name.replacingOccurrences(of: ".", with: "-") + ".png"
    let url = outDir.appendingPathComponent(file)
    guard let image = render(name), let data = pngData(image) else {
        fail.append(name)
        continue
    }
    try data.write(to: url)
    ok += 1
    print("wrote \(file)")
}
print("OK \(ok) FAIL \(fail.count) \(fail)")
if !fail.isEmpty { exit(1) }
