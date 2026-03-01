import SwiftUI

struct MainMenuView: View {
    let onStart: () -> Void
    var highScore: Int = 0

    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity: CGFloat = 0
    @State private var buttonOffset: CGFloat = 40
    @State private var scooterOffset: CGFloat = -200

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Text("DELIVERY")
                        .font(.system(size: 48, weight: .black, design: .default))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.82, blue: 0.1),
                                    Color(red: 1.0, green: 0.6, blue: 0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("RUSH")
                        .font(.system(size: 72, weight: .black, design: .default))
                        .tracking(12)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.4, blue: 0.1),
                                    Color(red: 0.9, green: 0.2, blue: 0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .red.opacity(0.4), radius: 20, x: 0, y: 4)
                }
                .scaleEffect(titleScale)
                .opacity(titleOpacity)

                Spacer().frame(height: 24)

                Text("🛵")
                    .font(.system(size: 60))
                    .offset(x: scooterOffset)

                Spacer().frame(height: 16)

                VStack(spacing: 6) {
                    Text("Deliver packages across the city")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Watch out for traffic & police!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .opacity(titleOpacity)

                Spacer()

                Button(action: onStart) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("START DELIVERY")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(2)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
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
                    .clipShape(.rect(cornerRadius: 16))
                    .shadow(color: .orange.opacity(0.4), radius: 16, x: 0, y: 4)
                }
                .offset(y: buttonOffset)
                .opacity(titleOpacity)

                Spacer().frame(height: 24)

                if highScore > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text("Best: \(highScore) deliveries")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .font(.footnote)
                    .opacity(titleOpacity)
                }

                Spacer().frame(height: 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                titleScale = 1.0
                titleOpacity = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.4)) {
                buttonOffset = 0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                scooterOffset = 0
            }
        }
    }
}
