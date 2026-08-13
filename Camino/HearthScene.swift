import SwiftUI

/// Hearth (frames turn 2 — 2a / 2d). Open country, low hedgerow, treeline.
/// The house is the warmest thing in the frame. Distance, brightness, and weather stay three signals.
struct HearthScene: View {
    var brightness: Double
    var distance: Double
    var weather: Double
    var arrived: Bool
    var reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 60 : (1.0 / 12.0), paused: reduceMotion)) { timeline in
            let pulse = reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                HearthPainter.paint(
                    context: &context,
                    size: size,
                    brightness: brightness,
                    distance: distance,
                    weather: weather,
                    pulse: pulse
                )
            }
        }
        .background(Color(red: 0.02, green: 0.027, blue: 0.059))
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

enum HearthPainter {
    static func paint(
        context: inout GraphicsContext,
        size: CGSize,
        brightness bIn: Double,
        distance dIn: Double,
        weather wIn: Double,
        pulse: Double
    ) {
        let b = SceneSignals.clamp01(bIn)
        let d = SceneSignals.clamp01(dIn)
        let w = SceneSignals.clamp01(wIn)
        let H = size.height
        let W = size.width
        let k = H / 852
        let horizon = H * 0.44

        sky(&context, W: W, horizon: horizon, b: b)
        moon(&context, W: W, H: H, k: k, b: b)
        stars(&context, size: size, b: b)
        glow(&context, W: W, horizon: horizon, k: k, b: b)
        clouds(&context, W: W, horizon: horizon, k: k, b: b, w: w)
        hills(&context, W: W, horizon: horizon, k: k, b: b)
        treeline(&context, W: W, horizon: horizon, k: k, b: b)
        land(&context, size: size, horizon: horizon, b: b)
        verge(&context, size: size, horizon: horizon, b: b)
        path(&context, size: size, horizon: horizon, b: b)
        stones(&context, W: W, H: H, horizon: horizon, k: k, b: b)
        house(&context, W: W, H: H, horizon: horizon, k: k, b: b, d: d)
        lanterns(&context, W: W, H: H, horizon: horizon, k: k, b: b)
        fireflies(&context, W: W, H: H, horizon: horizon, k: k, b: b, pulse: pulse)
        rain(&context, size: size, b: b, w: w)
        grain(&context, size: size)
        vignette(&context, size: size)
    }

    private static func sky(_ ctx: inout GraphicsContext, W: CGFloat, horizon: CGFloat, b: Double) {
        let path = Path(CGRect(x: 0, y: 0, width: W, height: horizon + 2))
        ctx.fill(
            path,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: mix(0x080B1C, 0x8FB6DA, b), location: 0),
                    .init(color: mix(0x141C38, 0xC4D8E8, b), location: 0.52),
                    .init(color: mix(0x2A2438, 0xF6D9AB, b), location: 1)
                ]),
                startPoint: CGPoint(x: W / 2, y: 0),
                endPoint: CGPoint(x: W / 2, y: horizon)
            )
        )
    }

    private static func moon(_ ctx: inout GraphicsContext, W: CGFloat, H: CGFloat, k: CGFloat, b: Double) {
        let opacity = max(0, 0.9 - b * 1.1)
        guard opacity > 0.02 else { return }
        let s = 30 * k
        let origin = CGPoint(x: W * 0.22, y: H * 0.13)
        ctx.fill(
            Path(ellipseIn: CGRect(x: origin.x - s * 1.2, y: origin.y - s * 1.2, width: s * 3.4, height: s * 3.4)),
            with: .color(Color(red: 0.965, green: 0.922, blue: 0.824).opacity(0.18 * opacity))
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: origin.x, y: origin.y, width: s, height: s)),
            with: .color(Color(red: 0.965, green: 0.922, blue: 0.824).opacity(opacity))
        )
    }

    private static func stars(_ ctx: inout GraphicsContext, size: CGSize, b: Double) {
        let starOp = max(0, 0.9 - b * 1.15)
        guard starOp > 0.02 else { return }
        let pts: [(CGFloat, CGFloat, CGFloat)] = [
            (8, 7, 1.4), (19, 14, 1), (27, 5, 1.2), (36, 20, 1), (44, 9, 1.6),
            (52, 17, 1), (61, 6, 1.2), (69, 15, 1.4), (77, 10, 1), (86, 19, 1.2),
            (93, 8, 1.4), (13, 25, 1), (31, 30, 1.2), (57, 27, 1), (72, 31, 1.2),
            (88, 28, 1), (4, 17, 1), (48, 33, 1), (65, 23, 1.4), (81, 34, 1)
        ]
        for (i, p) in pts.enumerated() {
            let op = starOp * (0.45 + Double(i % 4) * 0.18)
            let r = p.2
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: size.width * p.0 / 100 - r / 2,
                    y: size.height * p.1 / 100 - r / 2,
                    width: r,
                    height: r
                )),
                with: .color(Color(red: 1, green: 0.965, blue: 0.886).opacity(op))
            )
        }
    }

    private static func glow(_ ctx: inout GraphicsContext, W: CGFloat, horizon: CGFloat, k: CGFloat, b: Double) {
        let glowH = (80 + 260 * b) * k
        let color = mix(0xE8A867, 0xFFECCB, b)
        ctx.fill(
            Path(CGRect(x: -W * 0.14, y: horizon - glowH, width: W * 1.28, height: glowH)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: color.opacity(0.2 + 0.68 * b), location: 0),
                    .init(color: color.opacity(0), location: 0.7)
                ]),
                center: CGPoint(x: W / 2, y: horizon),
                startRadius: 0,
                endRadius: max(W * 0.72, glowH)
            )
        )
    }

    private static func clouds(_ ctx: inout GraphicsContext, W: CGFloat, horizon: CGFloat, k: CGFloat, b: Double, w: Double) {
        guard w > 0.02 else { return }
        let fill = mix(0x767F98, 0xA6AFC0, b)
        let scaleX = W / 393
        let clouds: [(CGFloat, CGFloat, CGFloat, CGFloat, Double)] = [
            (-0.10, horizon - 240 * k, 260 * k, 64 * k, 0.72),
            (0.40, horizon - 196 * k, 220 * k, 50 * k, 0.60),
            (0.12, horizon - 292 * k, 180 * k, 42 * k, 0.45),
            (0.58, horizon - 168 * k, 150 * k, 38 * k, 0.38)
        ]
        for cloud in clouds {
            ctx.fill(
                Path(ellipseIn: CGRect(x: cloud.0 * W, y: cloud.1, width: cloud.2 * scaleX, height: cloud.3)),
                with: .color(fill.opacity(cloud.4 * w))
            )
        }
    }

    private static func hills(_ ctx: inout GraphicsContext, W: CGFloat, horizon: CGFloat, k: CGFloat, b: Double) {
        ctx.fill(
            Path(ellipseIn: CGRect(x: -0.24 * W, y: horizon - 52 * k, width: 0.70 * W, height: 86 * k)),
            with: .color(mix(0x0E1526, 0x7E8C79, b).opacity(0.9))
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: W * 0.52, y: horizon - 44 * k, width: 0.74 * W, height: 74 * k)),
            with: .color(mix(0x0A101E, 0x5F6C55, b).opacity(0.9))
        )
    }

    private static func treeline(_ ctx: inout GraphicsContext, W: CGFloat, horizon: CGFloat, k: CGFloat, b: Double) {
        let top = horizon - 30 * k
        let height = 32 * k
        var path = Path()
        path.move(to: CGPoint(x: 0, y: top + height))
        for i in 0...26 {
            let x = CGFloat(i) / 26 * W
            let yRel = i % 2 == 1 ? 4 + (i % 5) * 13 : 46 + (i % 3) * 12
            path.addLine(to: CGPoint(x: x, y: top + height * CGFloat(yRel) / 100.0))
        }
        path.addLine(to: CGPoint(x: W, y: top + height))
        path.closeSubpath()
        ctx.fill(path, with: .color(mix(0x070C16, 0x39432F, b)))
    }

    private static func land(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, b: Double) {
        ctx.fill(
            Path(CGRect(x: 0, y: horizon, width: size.width, height: max(0, size.height - horizon))),
            with: .linearGradient(
                Gradient(colors: [mix(0x0D1420, 0x4E5A45, b), mix(0x060A11, 0x2E3626, b)]),
                startPoint: CGPoint(x: size.width / 2, y: horizon),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            )
        )
    }

    private static func verge(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, b: Double) {
        var path = Path()
        var x: CGFloat = -size.height
        while x < size.width + size.height {
            path.move(to: CGPoint(x: x, y: horizon))
            path.addLine(to: CGPoint(x: x + (size.height - horizon) * 0.1, y: size.height))
            x += 9
        }
        ctx.stroke(path, with: .color(Color.white.opacity(0.05 * (0.35 + 0.3 * b) / 0.35)), lineWidth: 1.2)
    }

    private static func path(_ ctx: inout GraphicsContext, size: CGSize, horizon: CGFloat, b: Double) {
        let W = size.width
        let H = size.height
        var halo = Path()
        halo.move(to: CGPoint(x: W * 0.474, y: horizon))
        halo.addLine(to: CGPoint(x: W * 0.526, y: horizon))
        halo.addLine(to: CGPoint(x: W * 0.84, y: H))
        halo.addLine(to: CGPoint(x: W * 0.16, y: H))
        halo.closeSubpath()
        ctx.fill(
            halo,
            with: .linearGradient(
                Gradient(colors: [
                    mix(0x242C3E, 0xD6C09A, b).opacity(0.55),
                    mix(0x3B4459, 0xEADCBE, b).opacity(0.55)
                ]),
                startPoint: CGPoint(x: W / 2, y: horizon),
                endPoint: CGPoint(x: W / 2, y: H)
            )
        )

        var core = Path()
        core.move(to: CGPoint(x: W * 0.483, y: horizon))
        core.addLine(to: CGPoint(x: W * 0.517, y: horizon))
        core.addLine(to: CGPoint(x: W * 0.78, y: H))
        core.addLine(to: CGPoint(x: W * 0.22, y: H))
        core.closeSubpath()
        ctx.fill(
            core,
            with: .linearGradient(
                Gradient(colors: [
                    mix(0x1A2130, 0xD9C49E, b).opacity(0.88),
                    mix(0x2C3446, 0xEFE2C6, b).opacity(0.88)
                ]),
                startPoint: CGPoint(x: W / 2, y: horizon),
                endPoint: CGPoint(x: W / 2, y: H)
            )
        )
    }

    private static func stones(_ ctx: inout GraphicsContext, W: CGFloat, H: CGFloat, horizon: CGFloat, k: CGFloat, b: Double) {
        let fill = mix(0x161D2B, 0xB8A47E, b)
        let ts: [CGFloat] = [0.12, 0.26, 0.42, 0.62, 0.84]
        for (i, t) in ts.enumerated() {
            let y = horizon + (H - horizon) * t
            let sw = (7 + 34 * t) * k
            let xOff: CGFloat = (i % 2 == 1 ? 3.5 : -3.5) * t
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: W * (0.50 + xOff / 100) - sw / 2,
                    y: y,
                    width: sw,
                    height: sw * 0.32
                )),
                with: .color(fill.opacity(0.5))
            )
        }
    }

    private static func house(_ ctx: inout GraphicsContext, W: CGFloat, H: CGFloat, horizon: CGFloat, k: CGFloat, b: Double, d: Double) {
        let hw = (26 + 150 * pow(d, 1.15)) * k
        let hb = (H - horizon) * (1 - 0.6 * d) - 6 * k
        let houseBottom = H - hb
        let houseLeft = W / 2 - hw / 2

        let poolR = hw * 2.6
        let poolOp = 0.5 - 0.2 * b
        ctx.fill(
            Path(ellipseIn: CGRect(
                x: W / 2 - poolR / 2,
                y: houseBottom - poolR * 0.47,
                width: poolR,
                height: poolR * 0.5
            )),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 1, green: 0.776, blue: 0.471).opacity(poolOp), location: 0),
                    .init(color: Color(red: 1, green: 0.776, blue: 0.471).opacity(0), location: 0.7)
                ]),
                center: CGPoint(x: W / 2, y: houseBottom - poolR * 0.05),
                startRadius: 0,
                endRadius: poolR * 0.5
            )
        )

        let roofH = hw * 0.4
        let bodyH = hw * 0.56
        let bodyW = hw * 0.74
        let bodyLeft = houseLeft + (hw - bodyW) / 2
        let bodyTop = houseBottom - bodyH
        let roofTop = bodyTop - roofH

        ctx.fill(
            Path(CGRect(
                x: houseLeft + hw - hw * 0.16 - hw * 0.11,
                y: roofTop - hw * 0.12,
                width: hw * 0.11,
                height: hw * 0.2
            )),
            with: .color(mix(0x101725, 0x4E4738, b))
        )

        var roof = Path()
        roof.move(to: CGPoint(x: houseLeft + hw / 2, y: roofTop))
        roof.addLine(to: CGPoint(x: houseLeft + hw, y: bodyTop))
        roof.addLine(to: CGPoint(x: houseLeft, y: bodyTop))
        roof.closeSubpath()
        ctx.fill(roof, with: .color(mix(0x131A28, 0x4A4335, b)))
        ctx.fill(
            Path(CGRect(x: bodyLeft, y: bodyTop, width: bodyW, height: bodyH)),
            with: .color(mix(0x0E141F, 0x5E5747, b))
        )

        let winS = max(2.5, hw * 0.17)
        let lampSoft = Color(red: 1, green: 0.776, blue: 0.431)
        func window(x: CGFloat, color: Color) {
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: x - winS * 0.6,
                    y: bodyTop + hw * 0.12 - winS * 0.6,
                    width: winS * 2.2,
                    height: winS * 2.2
                )),
                with: .color(lampSoft.opacity(0.45))
            )
            ctx.fill(
                Path(CGRect(x: x, y: bodyTop + hw * 0.12, width: winS, height: winS)),
                with: .color(color)
            )
        }
        window(x: bodyLeft + hw * 0.09, color: Color(red: 1, green: 0.808, blue: 0.525))
        window(x: bodyLeft + bodyW - hw * 0.09 - winS, color: Color(red: 1, green: 0.843, blue: 0.604))

        let doorW = winS * 0.8
        let doorH = winS * 1.3
        ctx.fill(
            Path(ellipseIn: CGRect(
                x: bodyLeft + bodyW / 2 - doorW,
                y: houseBottom - doorH * 0.7,
                width: doorW * 2,
                height: doorH
            )),
            with: .color(Color(red: 1, green: 0.706, blue: 0.392).opacity(0.35))
        )
        ctx.fill(
            Path(roundedRect: CGRect(
                x: bodyLeft + bodyW / 2 - doorW / 2,
                y: houseBottom - doorH,
                width: doorW,
                height: doorH
            ), cornerRadii: RectangleCornerRadii(topLeading: winS * 0.4, topTrailing: winS * 0.4)),
            with: .color(Color(red: 1, green: 0.757, blue: 0.471))
        )
    }

    private static func lanterns(_ ctx: inout GraphicsContext, W: CGFloat, H: CGFloat, horizon: CGFloat, k: CGFloat, b: Double) {
        let posts: [(CGFloat, CGFloat)] = [(0.3, 42.5), (0.55, 60), (0.8, 33)]
        let postColor = mix(0x0B111C, 0x463F31, b)
        for L in posts {
            let y = horizon + (H - horizon) * L.0
            let ph = (16 + 40 * L.0) * k
            let ls = (3 + 6 * L.0) * k
            let x = W * L.1 / 100
            let postW = max(1, 2 * k * (0.5 + L.0))
            ctx.fill(Path(CGRect(x: x, y: y, width: postW, height: ph)), with: .color(postColor.opacity(0.85)))
            ctx.fill(
                Path(ellipseIn: CGRect(x: x - ls * 1.2, y: y - ls * 0.6 - ls, width: ls * 3, height: ls * 3)),
                with: .color(Color(red: 1, green: 0.745, blue: 0.431).opacity(0.5 - 0.25 * b))
            )
            ctx.fill(
                Path(ellipseIn: CGRect(x: x - ls * 0.4, y: y - ls * 0.6, width: ls, height: ls)),
                with: .color(Color(red: 1, green: 0.808, blue: 0.525))
            )
        }
    }

    private static func fireflies(_ ctx: inout GraphicsContext, W: CGFloat, H: CGFloat, horizon: CGFloat, k: CGFloat, b: Double, pulse: Double) {
        let flies: [(CGFloat, CGFloat)] = [(30, 0.62), (38, 0.74), (64, 0.68), (71, 0.86), (46, 0.9)]
        let base = 0.75 - 0.5 * b
        guard base > 0.02 else { return }
        for (i, f) in flies.enumerated() {
            let wave = pulse == 0 ? 1.0 : 0.65 + 0.35 * sin(pulse * 0.7 + Double(i) * 1.3)
            let op = base * wave
            let y = horizon + (H - horizon) * f.1
            let s = 2.5 * k
            ctx.fill(
                Path(ellipseIn: CGRect(x: W * f.0 / 100 - 4 * k, y: y - 4 * k, width: 8 * k, height: 8 * k)),
                with: .color(Color(red: 1, green: 0.784, blue: 0.471).opacity(0.35 * op))
            )
            ctx.fill(
                Path(ellipseIn: CGRect(x: W * f.0 / 100 - s / 2, y: y, width: s, height: s)),
                with: .color(Color(red: 1, green: 0.843, blue: 0.604).opacity(op))
            )
        }
    }

    private static func rain(_ ctx: inout GraphicsContext, size: CGSize, b: Double, w: Double) {
        let opacity = w > 0.45 ? (w - 0.45) * 1.6 : 0
        guard opacity > 0.02 else { return }
        let stroke = b > 0.55
            ? Color(red: 0.235, green: 0.275, blue: 0.353).opacity(0.30)
            : Color(red: 0.808, green: 0.847, blue: 0.922).opacity(0.26)
        var path = Path()
        var x: CGFloat = -size.height
        while x < size.width + size.height {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + size.height * 0.29, y: size.height))
            x += 8
        }
        ctx.opacity = opacity
        ctx.stroke(path, with: .color(stroke), lineWidth: 1)
        ctx.opacity = 1
    }

    private static func grain(_ ctx: inout GraphicsContext, size: CGSize) {
        var path = Path()
        var y: CGFloat = 0
        while y < size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += 2
        }
        ctx.stroke(path, with: .color(Color.white.opacity(0.018)), lineWidth: 1)
    }

    private static func vignette(_ ctx: inout GraphicsContext, size: CGSize) {
        ctx.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: .clear, location: 0.42),
                    .init(color: Color.black.opacity(0.4), location: 1)
                ]),
                center: CGPoint(x: size.width / 2, y: size.height * 0.76),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.85
            )
        )
    }

    private static func mix(_ a: Int, _ c: Int, _ t: Double) -> Color {
        let t = SceneSignals.clamp01(t)
        func ch(_ hex: Int, shift: Int) -> Double { Double((hex >> shift) & 0xFF) / 255.0 }
        return Color(
            red: ch(a, shift: 16) + (ch(c, shift: 16) - ch(a, shift: 16)) * t,
            green: ch(a, shift: 8) + (ch(c, shift: 8) - ch(a, shift: 8)) * t,
            blue: ch(a, shift: 0) + (ch(c, shift: 0) - ch(a, shift: 0)) * t
        )
    }
}
