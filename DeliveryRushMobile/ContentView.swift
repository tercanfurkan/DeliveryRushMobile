import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()

    var body: some View {
        Group {
            switch viewModel.gamePhase {
            case .menu:
                MainMenuView(
                    onStart: { viewModel.startGame() },
                    viewModel: viewModel,
                    highScore: viewModel.highScore
                )
            case .playing, .gameOver:
                GamePlayView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.gamePhase)
    }
}
