import SwiftUI

// MARK: - C4: Level-Up Transition Overlay

struct LevelUpView: View {
    @Bindable var viewModel: GameViewModel
    @State private var slideOffset: CGFloat = 400
    @State private var opacity: Double = 0
    @State private var dotPhase: Int = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("LEVEL \(viewModel.currentLevel)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(viewModel.currentTheme.skylineEmoji)
                    .font(.system(size: 72))

                Text("Welcome to \(viewModel.currentTheme.name)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))

                // Animated progress dots
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { idx in
                        Circle()
                            .fill(idx == dotPhase % 3 ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .animation(.easeInOut(duration: 0.3), value: dotPhase)
                    }
                }
                .padding(.top, 8)

                Text("Loading city...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(40)
            .offset(y: slideOffset)
            .opacity(opacity)
        }
        .task {
            while true {
                try? await Task.sleep(for: .seconds(0.4))
                dotPhase += 1
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                slideOffset = 0
                opacity = 1.0
            }
        }
    }
}
