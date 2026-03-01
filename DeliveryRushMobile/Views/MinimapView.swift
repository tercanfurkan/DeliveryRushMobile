import SwiftUI

struct MinimapView: View {
    let playerPosition: CGPoint
    let pickupPosition: CGPoint?
    let deliveryPosition: CGPoint?
    let worldSize: CGFloat

    private let mapSize: CGFloat = 110

    var body: some View {
        Canvas { context, size in
            func drawMarker(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat,
                            innerR: CGFloat, outerR: CGFloat, color: Color) {
                let inner = CGRect(x: x - innerR, y: y - innerR, width: innerR * 2, height: innerR * 2)
                ctx.fill(Path(ellipseIn: inner), with: .color(color))
                let outer = CGRect(x: x - outerR, y: y - outerR, width: outerR * 2, height: outerR * 2)
                ctx.stroke(Path(ellipseIn: outer), with: .color(color.opacity(0.6)), lineWidth: 1)
            }

            let scale = size.width / worldSize
            let rw = CityConfig.roadWidth * scale
            let cell = CityConfig.cellSize * scale

            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(red: 0.12, green: 0.12, blue: 0.14))
            )

            let roadColor = Color(red: 0.25, green: 0.25, blue: 0.28)
            for row in 0...CityConfig.gridSize {
                let y = CGFloat(row) * cell
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: rw)), with: .color(roadColor))
            }
            for col in 0...CityConfig.gridSize {
                let x = CGFloat(col) * cell
                context.fill(Path(CGRect(x: x, y: 0, width: rw, height: size.height)), with: .color(roadColor))
            }

            let blockColor = Color(red: 0.35, green: 0.33, blue: 0.30)
            for row in 0..<CityConfig.gridSize {
                for col in 0..<CityConfig.gridSize {
                    let bx = CGFloat(col) * cell + rw
                    let by = CGFloat(row) * cell + rw
                    let bs = CityConfig.blockSize * scale
                    context.fill(Path(CGRect(x: bx, y: by, width: bs, height: bs)), with: .color(blockColor))
                }
            }

            if let pickup = pickupPosition {
                drawMarker(&context, x: pickup.x * scale, y: size.height - pickup.y * scale,
                           innerR: 4, outerR: 6, color: .green)
            }

            if let delivery = deliveryPosition {
                drawMarker(&context, x: delivery.x * scale, y: size.height - delivery.y * scale,
                           innerR: 4, outerR: 6, color: .orange)
            }

            drawMarker(&context, x: playerPosition.x * scale, y: size.height - playerPosition.y * scale,
                       innerR: 3, outerR: 5, color: .yellow)
        }
        .frame(width: mapSize, height: mapSize)
        .clipShape(.rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
    }
}
