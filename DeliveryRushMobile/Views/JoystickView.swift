import SwiftUI

struct JoystickView: View {
    @Binding var direction: CGVector
    private let baseRadius: CGFloat = 55
    private let knobRadius: CGFloat = 24
    @State private var knobOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: baseRadius * 2, height: baseRadius * 2)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 2)
                )

            Circle()
                .fill(.white.opacity(0.25))
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .offset(knobOffset)
        }
        .frame(width: baseRadius * 2 + 20, height: baseRadius * 2 + 20)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let translation = value.translation
                    let dist = hypot(translation.width, translation.height)
                    let maxDist = baseRadius - knobRadius / 2
                    let clampedDist = min(dist, maxDist)
                    let angle = atan2(translation.height, translation.width)

                    knobOffset = CGSize(
                        width: cos(angle) * clampedDist,
                        height: sin(angle) * clampedDist
                    )

                    let magnitude = clampedDist / maxDist
                    direction = CGVector(
                        dx: cos(angle) * magnitude,
                        dy: -sin(angle) * magnitude
                    )
                }
                .onEnded { _ in
                    withAnimation(.snappy(duration: 0.2)) {
                        knobOffset = .zero
                    }
                    direction = .zero
                }
        )
    }
}
