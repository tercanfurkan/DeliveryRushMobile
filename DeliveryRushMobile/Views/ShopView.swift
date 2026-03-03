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
                return ShopItem(
                    id: "scooter_\(tier.rawValue)",
                    name: tier.displayName,
                    description: "Speed: \(Int(tier.maxSpeed))  Thrust: \(Int(tier.thrust))",
                    price: tier.price,
                    isOwned: owned,
                    isEquipped: equipped,
                    canAfford: viewModel.money >= tier.price || owned
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
                    canAfford: viewModel.money >= track.price || owned
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
                    previewColor: Color(uiColor: color.bodyColor)
                )
            }

        case .portalStore:
            let canPortal = viewModel.deliveriesThisLevel >= 8
            let isMaxLevel = viewModel.currentLevel >= 3
            if isMaxLevel {
                return [ShopItem(
                    id: "portal_max",
                    name: "You've seen it all!",
                    description: "You're a world delivery legend.",
                    price: 0,
                    isOwned: true,
                    isEquipped: false,
                    canAfford: false,
                    isDisabled: true
                )]
            } else {
                let nextTheme = CityTheme.theme(for: viewModel.currentLevel + 1)
                return [ShopItem(
                    id: "portal_travel",
                    name: "Travel to \(nextTheme.name)",
                    description: canPortal ? "Warp to the next city!" : "Complete \(8 - viewModel.deliveriesThisLevel) more deliveries first",
                    price: 100,
                    isOwned: false,
                    isEquipped: false,
                    canAfford: viewModel.money >= 100 && canPortal,
                    isDisabled: !canPortal
                )]
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
            if item.id == "portal_travel" {
                viewModel.purchaseItem(shopType: .portalStore, itemIndex: 0)
                viewModel.isShopOpen = false
            }
        }
    }
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
    var previewColor: Color? = nil
}

// MARK: - Shop Item Card

struct ShopItemCard: View {
    let item: ShopItem
    let accentColor: Color
    let onBuy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Color preview swatch (paint store)
            if let previewColor = item.previewColor {
                RoundedRectangle(cornerRadius: 6)
                    .fill(previewColor)
                    .frame(height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
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
}
