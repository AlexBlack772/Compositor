import AppKit

/// The edge or corner a frame-resize handle points, standing in for `NSCursor.FrameResizePosition`, which exists
/// only on macOS 15. Call sites keep one version-independent type and ask it for the cursor.
enum FrameResizePosition {
    case top, topLeft, topRight, right, bottomRight, bottom, bottomLeft, left

    /// The two-way frame-resize cursor on macOS 15; earlier systems show the classic resize cursor, or drawn
    /// diagonal arrows for the corners, which AppKit has no public cursor for.
    var cursor: NSCursor {
        if #available(macOS 15.0, *) { return .frameResize(position: nsPosition, directions: [.inward, .outward]) }
        switch self {
        case .top, .bottom: return .resizeUpDown
        case .left, .right: return .resizeLeftRight
        case .topLeft, .bottomRight: return Self.northwestDiagonalCursor
        case .topRight, .bottomLeft: return Self.northeastDiagonalCursor
        }
    }

    @available(macOS 15.0, *)
    private var nsPosition: NSCursor.FrameResizePosition {
        switch self {
        case .top: return .top
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .right: return .right
        case .bottomRight: return .bottomRight
        case .bottom: return .bottom
        case .bottomLeft: return .bottomLeft
        case .left: return .left
        }
    }

    /// Corner arrows before macOS 15: an SF Symbol with a white silhouette, so it reads on any image, drawn the
    /// way the canvas's other symbol cursors are.
    private static func makeDiagonalCursor(symbolName: String) -> NSCursor {
        let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Resize")!
        let white = symbol.withSymbolConfiguration(.init(paletteColors: [.white]))!
        let black = symbol.withSymbolConfiguration(.init(paletteColors: [.black]))!
        let image = NSImage(size: NSSize(width: 24, height: 24), flipped: false) { _ in
            let glyph = CGRect(x: 2, y: 2, width: 20, height: 20)
            // Expand the white silhouette, then draw the black symbol on top.
            for step in 0..<16 {
                let angle = CGFloat(step) * .pi / 8
                white.draw(in: glyph.offsetBy(dx: cos(angle) * 1.25, dy: sin(angle) * 1.25))
            }
            black.draw(in: glyph)
            return true
        }
        return NSCursor(image: image, hotSpot: NSPoint(x: 12, y: 12))
    }

    private static let northwestDiagonalCursor = makeDiagonalCursor(symbolName: "arrow.up.left.and.arrow.down.right")
    private static let northeastDiagonalCursor = makeDiagonalCursor(symbolName: "arrow.up.right.and.arrow.down.left")
}
