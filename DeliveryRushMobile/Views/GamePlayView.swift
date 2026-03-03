import SwiftUI
import SpriteKit

struct GamePlayView: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        ZStack {
            if let scene = viewModel.gameScene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }

            VStack {
                HStack(alignment: .top) {
                    hudLeft
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        hudRight
                        MinimapView(
                            playerPosition: viewModel.playerPosition,
                            pickupPosition: viewModel.pickupMarkerPosition,
                            deliveryPosition: viewModel.deliveryMarkerPosition,
                            worldSize: CityConfig.worldSize
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()
                missionBanner
                controlsBar
            }
            .padding(.bottom, 16)

            if viewModel.showCrashFlash {
                Color.red.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            if viewModel.showDeliveryComplete {
                deliveryCompleteOverlay
            }

            if viewModel.gamePhase == .gameOver {
                gameOverOverlay
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: viewModel.showCrashFlash)
        .sensoryFeedback(.success, trigger: viewModel.showDeliveryComplete)
    }

    private var hudLeft: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.green)
                Text("$\(viewModel.money)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.6))
            .clipShape(.rect(cornerRadius: 12))

            if viewModel.currentMission != nil {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundStyle(timerColor)
                    Text(timerText)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(timerColor)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.black.opacity(0.6))
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private var hudRight: some View {
        HStack(spacing: 4) {
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(.orange)
            Text("\(viewModel.totalDeliveries)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.6))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var timerColor: Color {
        viewModel.missionTimeRemaining < 10 ? .red : .white
    }

    private var timerText: String {
        let seconds = Int(viewModel.missionTimeRemaining)
        return "\(seconds)s"
    }

    private var missionBanner: some View {
        Group {
            if !viewModel.missionMessage.isEmpty {
                HStack(spacing: 8) {
                    if viewModel.policeAlert {
                        Image(systemName: "light.beacon.max.fill")
                            .foregroundStyle(.red)
                            .symbolEffect(.pulse)
                    }

                    if let iconName = viewModel.missionIconName {
                        Text(iconName)
                            .font(.system(size: 18))
                    }

                    Text(viewModel.missionMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.black.opacity(0.7))
                .clipShape(.rect(cornerRadius: 12))
                .padding(.bottom, 8)
            }
        }
    }

    private var controlsBar: some View {
        HStack(alignment: .bottom) {
            JoystickView(direction: Binding(
                get: { viewModel.joystickDirection },
                set: { viewModel.joystickDirection = $0 }
            ))
            .padding(.leading, 16)

            Spacer()

            if viewModel.canThrow {
                Button {
                    viewModel.throwRequested = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .font(.system(size: 52))
                        Text("THROW")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.orange.opacity(0.7))
                            .frame(width: 80, height: 80)
                    )
                }
                .padding(.trailing, 24)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3), value: viewModel.canThrow)
            }
        }
        .padding(.bottom, 16)
    }

    private var deliveryCompleteOverlay: some View {
        VStack(spacing: 12) {
            Text("✅ DELIVERED!")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.green)

            Text("+$\(viewModel.lastEarned)")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.yellow)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .transition(.scale.combined(with: .opacity))
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("GAME OVER")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(.red)

                VStack(spacing: 8) {
                    HStack {
                        Text("Deliveries:")
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("\(viewModel.totalDeliveries)")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    HStack {
                        Text("Best:")
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("\(viewModel.highScore)")
                            .font(.title2.bold())
                            .foregroundStyle(.yellow)
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    viewModel.startGame()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("TRY AGAIN")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.82, blue: 0.1),
                                Color(red: 1.0, green: 0.65, blue: 0.05)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(.rect(cornerRadius: 14))
                }

                Button {
                    viewModel.gamePhase = .menu
                    viewModel.gameScene = nil
                } label: {
                    Text("Main Menu")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 24))
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
    }
}