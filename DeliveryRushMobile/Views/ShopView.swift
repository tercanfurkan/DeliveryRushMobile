import SwiftUI

// MARK: - B4: Shop Overlay UI

struct ShopView: View {
    @Bindable var viewModel: GameViewModel
    let shop: Shop

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("\(shop.type.emoji)  \(shop.type.name)")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        viewModel.isShopOpen = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(uiColor: shop.type.signColor).opacity(0.3))

                Divider()
                    .background(Color(uiColor: shop.type.signColor))

                // Items grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(shopItems, id: \.id) { item in
                            ShopItemCard(item: item, accentColor: Color(uiColor: shop.type.signColor)) {
                                handlePurchase(item: item)
                            }
                        }
                    }
                    .padding(16)
                }

                Divider()
                    .background(.white.opacity(0.2))

                // Wallet
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.green)
                    Text("Wallet: $\(viewModel.money)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.black.opacity(0.5))
            }
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 20))
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var shopItems: [ShopItem] {
        switch shop.type {
        case .scooterStore:
            return ScooterTier.allCases.map { tier in
                let owned = viewModel.ownedScooters.contains(tier)
                let equipped = viewModel.equippedScooter == tier
                let previewColor: Color = switch tier {
                case .basic: Color(red: 1.0, green: 0.55, blue: 0.15)
                case .turbo: Color(red: 0.15, green: 0.50, blue: 0.90)
                case .racing: Color(red: 0.85, green: 0.65, blue: 0.10)
                }
                return ShopItem(
                    id: "scooter_\(tier.rawValue)",
                    name: tier.displayName,
                    description: "Speed: \(Int(tier.maxSpeed))  Thrust: \(Int(tier.thrust))",
                    price: tier.price,
                    isOwned: owned,
                    isEquipped: equipped,
                    canAfford: viewModel.money >= tier.price || owned,
                    preview: .scooter(previewColor)
                )
            }

        case .musicStore:
            return GameTrack.allCases.map { track in
                let owned = viewModel.ownedTracks.contains(track)
                let equipped = viewModel.activeTrack == track
                return ShopItem(
                    id: "track_\(track.displayName)",
                    name: track.displayName,
                    description: track.character,
                    price: track.price,
                    isOwned: owned,
                    isEquipped: equipped,
                    canAfford: viewModel.money >= track.price || owned,
                    preview: .musicWave
                )
            }

        case .paintStore:
            return ScooterColor.allCases.map { color in
                let owned = viewModel.ownedColors.contains(color)
                let equipped = viewModel.scooterColor == color
                return ShopItem(
                    id: "color_\(color.displayName)",
                    name: color.displayName,
                    description: "Custom paint job",
                    price: color.price,
                    isOwned: owned,
                    isEquipped: equipped,
                    canAfford: viewModel.money >= color.price || owned,
                    preview: .color(Color(uiColor: color.bodyColor))
                )
            }

        case .portalStore:
            let isMaxLevel = viewModel.currentLevel >= 10
            if isMaxLevel {
                return [ShopItem(
                    id: "portal_max",
                    name: "You've seen it all!",
                    description: "You're a world delivery legend.",
                    price: 0,
                    isOwned: true,
                    isEquipped: false,
                    canAfford: false,
                    isDisabled: true,
                    preview: .portal
                )]
            } else {
                let canPortal = viewModel.deliveriesThisLevel >= 8
                let remaining = max(0, 8 - viewModel.deliveriesThisLevel)
                return (viewModel.currentLevel + 1 ... 10).map { destLevel in
                    let theme = CityTheme.theme(for: destLevel)
                    let flavorText: String = switch destLevel {
                    case 4: "Neon-lit streets and blazing speed"
                    case 5: "Cobblestones, rain, and red buses"
                    case 6: "Baguettes, boulevards, and bistros"
                    case 7: "Concrete jungle bursting with colour"
                    case 8: "Colonial chaos meets modern madness"
                    case 9: "Red earth, vivid palms, unstoppable hustle"
                    case 10: "Sun, harbour, and iconic skyline"
                    default: "A brand new city awaits"
                    }
                    let desc = canPortal
                        ? "\(theme.skylineEmoji) \(flavorText)"
                        : "Complete \(remaining) more deliveries first"
                    return ShopItem(
                        id: "portal_\(destLevel)",
                        name: "Travel to \(theme.name)",
                        description: desc,
                        price: 100,
                        isOwned: false,
                        isEquipped: false,
                        canAfford: viewModel.money >= 100 && canPortal,
                        isDisabled: !canPortal,
                        preview: .portal,
                        portalDestination: destLevel
                    )
                }
            }
        }
    }

    private func handlePurchase(item: ShopItem) {
        switch shop.type {
        case .scooterStore:
            if let tier = ScooterTier.allCases.first(where: { "scooter_\($0.rawValue)" == item.id }) {
                if item.isOwned {
                    viewModel.equipScooter(tier)
                } else {
                    viewModel.purchaseItem(shopType: .scooterStore, itemIndex: ScooterTier.allCases.firstIndex(of: tier) ?? 0)
                }
            }

        case .musicStore:
            if let track = GameTrack.allCases.first(where: { "track_\($0.displayName)" == item.id }) {
                if item.isOwned {
                    viewModel.equipTrack(track)
                } else {
                    viewModel.purchaseItem(shopType: .musicStore, itemIndex: GameTrack.allCases.firstIndex(of: track) ?? 0)
                }
            }

        case .paintStore:
            if let color = ScooterColor.allCases.first(where: { "color_\($0.displayName)" == item.id }) {
                if item.isOwned {
                    viewModel.equipColor(color)
                } else {
                    viewModel.purchaseItem(shopType: .paintStore, itemIndex: ScooterColor.allCases.firstIndex(of: color) ?? 0)
                }
            }

        case .portalStore:
            if let targetLevel = item.portalDestination {
                guard viewModel.money >= 100, viewModel.deliveriesThisLevel >= 8 else { return }
                viewModel.money -= 100
                viewModel.travelToLevel(targetLevel)
                viewModel.isShopOpen = false
            }
        }
    }
}

// MARK: - Shop Item Preview

enum ShopItemPreview {
    case color(Color)
    case scooter(Color)
    case musicWave
    case portal
}

// MARK: - Shop Item Model

struct ShopItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let isOwned: Bool
    let isEquipped: Bool
    let canAfford: Bool
    var isDisabled: Bool = false
    var preview: ShopItemPreview? = nil
    var portalDestination: Int? = nil
}

// MARK: - Shop Item Card

struct ShopItemCard: View {
    let item: ShopItem
    let accentColor: Color
    let onBuy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Preview artwork
            if let preview = item.preview {
                previewView(preview)
            }

            Text(item.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(item.description)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(3)

            Spacer()

            if item.isDisabled {
                Text("Not available")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            } else if item.isEquipped {
                Label("Equipped", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentColor)
            } else {
                Button(action: onBuy) {
                    HStack(spacing: 4) {
                        if item.isOwned {
                            Text("EQUIP")
                                .font(.system(size: 11, weight: .black))
                        } else {
                            Image(systemName: "dollarsign")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(item.price)")
                                .font(.system(size: 12, weight: .black))
                        }
                    }
                    .foregroundStyle(item.canAfford ? .black : .white.opacity(0.4))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        item.canAfford ? accentColor : Color.white.opacity(0.15)
                    )
                    .clipShape(.rect(cornerRadius: 8))
                }
                .disabled(!item.canAfford)
            }
        }
        .padding(12)
        .background(.white.opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.isEquipped ? accentColor.opacity(0.6) : .white.opacity(0.1), lineWidth: 1.5)
        )
    }

    @ViewBuilder
    private func previewView(_ preview: ShopItemPreview) -> some View {
        switch preview {
        case .color(let c):
            RoundedRectangle(cornerRadius: 6)
                .fill(c)
                .frame(height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )

        case .scooter(let c):
            scooterPreview(color: c)
                .frame(height: 44)

        case .musicWave:
            musicWavePreview()
                .frame(height: 44)

        case .portal:
            portalPreview()
                .frame(height: 44)
        }
    }

    @ViewBuilder
    private func scooterPreview(color: Color) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2
            let cy = h / 2

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))

                // Body
                Ellipse()
                    .fill(color)
                    .frame(width: w * 0.48, height: h * 0.38)
                    .offset(x: 0, y: -h * 0.04)

                // Rear wheel
                Circle()
                    .stroke(color, lineWidth: 3)
                    .frame(width: h * 0.42, height: h * 0.42)
                    .offset(x: -w * 0.20, y: h * 0.18)

                // Front wheel
                Circle()
                    .stroke(color, lineWidth: 3)
                    .frame(width: h * 0.38, height: h * 0.38)
                    .offset(x: w * 0.22, y: h * 0.18)

                // Handlebar
                Path { path in
                    let bx = cx + w * 0.16
                    let by = cy - h * 0.10
                    path.move(to: CGPoint(x: bx - 4, y: by - 8))
                    path.addLine(to: CGPoint(x: bx + 4, y: by + 2))
                }
                .stroke(color.opacity(0.85), lineWidth: 2.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    @ViewBuilder
    private func musicWavePreview() -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.05, green: 0.12, blue: 0.22))

                // Sine wave path
                Path { path in
                    let steps = 60
                    let amplitude = h * 0.30
                    let midY = h / 2
                    path.move(to: CGPoint(x: 0, y: midY))
                    for i in 1...steps {
                        let x = w * CGFloat(i) / CGFloat(steps)
                        let angle = CGFloat(i) / CGFloat(steps) * .pi * 4
                        let y = midY - amplitude * sin(angle)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.15, green: 0.80, blue: 1.0), Color(red: 0.30, green: 0.40, blue: 1.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )

                // Second wave (offset phase)
                Path { path in
                    let steps = 60
                    let amplitude = h * 0.15
                    let midY = h / 2
                    path.move(to: CGPoint(x: 0, y: midY))
                    for i in 1...steps {
                        let x = w * CGFloat(i) / CGFloat(steps)
                        let angle = CGFloat(i) / CGFloat(steps) * .pi * 4 + .pi / 2
                        let y = midY - amplitude * sin(angle)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color(red: 0.40, green: 0.80, blue: 1.0).opacity(0.45), lineWidth: 1.2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    @ViewBuilder
    private func portalPreview() -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2
            let cy = h / 2
            let maxR = min(w, h) * 0.44

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.06, green: 0.02, blue: 0.14))

                // Concentric arcs with varying hues to suggest a swirling portal
                ForEach(0..<5) { i in
                    let fraction = CGFloat(i + 1) / 5.0
                    let radius = maxR * fraction
                    let hue = 0.72 - Double(i) * 0.06 // purple to violet range
                    let arcColor = Color(hue: hue, saturation: 0.85, brightness: 0.95)
                    let rotOffset = Double(i) * 18.0 // degrees

                    Circle()
                        .trim(from: 0.05, to: 0.88)
                        .stroke(arcColor.opacity(0.75 - Double(i) * 0.08), lineWidth: 2.5)
                        .frame(width: radius * 2, height: radius * 2)
                        .rotationEffect(.degrees(rotOffset))
                        .position(x: cx, y: cy)
                }

                // Central glow dot
                Circle()
                    .fill(Color(hue: 0.78, saturation: 0.6, brightness: 1.0))
                    .frame(width: 6, height: 6)
                    .position(x: cx, y: cy)
                    .blur(radius: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
