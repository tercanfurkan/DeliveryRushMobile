import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    weak var viewModel: GameViewModel?

    private let worldNode = SKNode()
    private let playerNode = SKNode()
    private let trafficNode = SKNode()
    private let pedestrianNode = SKNode()
    private let markerNode = SKNode()
    private let policeNode = SKNode()
    private let trafficLightNode = SKNode()
    private let cameraNode = SKCameraNode()

    private var playerAngle: CGFloat = .pi / 2
    private var lastUpdateTime: TimeInterval = 0
    private var trafficSpawnTimer: TimeInterval = 0
    private var pedestrianSpawnTimer: TimeInterval = 0
    private var crashCooldown: TimeInterval = 0
    private var missionTimerActive = false
    private var trafficLightTimer: TimeInterval = 0
    private var trafficLightGreen = true

    private var pickupMarker: SKNode?
    private var deliveryMarker: SKNode?
    private var throwInFlight: Bool = false

    private var greenLightNodes: [SKShapeNode] = []
    private var redLightNodes: [SKShapeNode] = []
    private let tlGreenOn  = UIColor.green
    private let tlGreenOff = UIColor(red: 0.1, green: 0.25, blue: 0.1, alpha: 1)
    private let tlRedOn    = UIColor.red
    private let tlRedOff   = UIColor(red: 0.3, green: 0.05, blue: 0.05, alpha: 1)

    private var buildingTextureCache: [Int: SKTexture] = [:]
    private var npcVelocities: [ObjectIdentifier: CGVector] = [:]

    private let maxSpeed: CGFloat = 280
    private let thrustForce: CGFloat = 900
    private let turnSpeed: CGFloat = 5.5

    private let buildingColors: [UIColor] = [
        UIColor(red: 0.55, green: 0.42, blue: 0.35, alpha: 1),
        UIColor(red: 0.60, green: 0.55, blue: 0.50, alpha: 1),
        UIColor(red: 0.48, green: 0.50, blue: 0.56, alpha: 1),
        UIColor(red: 0.62, green: 0.55, blue: 0.45, alpha: 1),
        UIColor(red: 0.52, green: 0.45, blue: 0.42, alpha: 1),
        UIColor(red: 0.58, green: 0.52, blue: 0.46, alpha: 1),
        UIColor(red: 0.50, green: 0.44, blue: 0.52, alpha: 1),
        UIColor(red: 0.65, green: 0.58, blue: 0.48, alpha: 1),
    ]

    private let sidewalkColor = UIColor(red: 0.38, green: 0.37, blue: 0.36, alpha: 1)
    private let roadColor = UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1)
    private let curbColor = UIColor(red: 0.32, green: 0.31, blue: 0.30, alpha: 1)

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1)
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero

        addChild(worldNode)
        worldNode.addChild(trafficNode)
        worldNode.addChild(pedestrianNode)
        worldNode.addChild(markerNode)
        markerNode.zPosition = 20
        worldNode.addChild(policeNode)
        worldNode.addChild(trafficLightNode)

        camera = cameraNode
        addChild(cameraNode)

        buildCity()
        setupPlayer()
        setupWorldBoundary()
    }

    // MARK: - City Building

    private func buildCity() {
        let ws = CityConfig.worldSize
        let rw = CityConfig.roadWidth
        let sw = CityConfig.sidewalkWidth

        drawRoads(ws: ws, rw: rw)
        drawSidewalks(ws: ws, rw: rw, sw: sw)
        drawLaneMarkings(ws: ws, rw: rw)
        drawCrosswalks(rw: rw)
        drawTrafficLights(rw: rw)
        drawBuildings(rw: rw)
        drawSidewalkTrees(rw: rw, sw: sw)
    }

    private func drawRoads(ws: CGFloat, rw: CGFloat) {
        for row in 0...CityConfig.gridSize {
            let y = CGFloat(row) * CityConfig.cellSize
            let road = SKShapeNode(rectOf: CGSize(width: ws + rw, height: rw))
            road.position = CGPoint(x: ws / 2, y: y + rw / 2)
            road.fillColor = roadColor
            road.strokeColor = .clear
            road.zPosition = 0
            worldNode.addChild(road)
        }

        for col in 0...CityConfig.gridSize {
            let x = CGFloat(col) * CityConfig.cellSize
            let road = SKShapeNode(rectOf: CGSize(width: rw, height: ws + rw))
            road.position = CGPoint(x: x + rw / 2, y: ws / 2)
            road.fillColor = roadColor
            road.strokeColor = .clear
            road.zPosition = 0
            worldNode.addChild(road)
        }
    }

    private func drawSidewalks(ws: CGFloat, rw: CGFloat, sw: CGFloat) {
        for row in 0...CityConfig.gridSize {
            let y = CGFloat(row) * CityConfig.cellSize

            let bottom = SKShapeNode(rectOf: CGSize(width: ws + rw, height: sw))
            bottom.position = CGPoint(x: ws / 2, y: y + sw / 2)
            bottom.fillColor = sidewalkColor
            bottom.strokeColor = .clear
            bottom.zPosition = 1
            worldNode.addChild(bottom)

            let top = SKShapeNode(rectOf: CGSize(width: ws + rw, height: sw))
            top.position = CGPoint(x: ws / 2, y: y + rw - sw / 2)
            top.fillColor = sidewalkColor
            top.strokeColor = .clear
            top.zPosition = 1
            worldNode.addChild(top)

            let curbBottom = SKShapeNode(rectOf: CGSize(width: ws + rw, height: 1))
            curbBottom.position = CGPoint(x: ws / 2, y: y + sw)
            curbBottom.fillColor = curbColor
            curbBottom.strokeColor = .clear
            curbBottom.zPosition = 1.5
            worldNode.addChild(curbBottom)

            let curbTop = SKShapeNode(rectOf: CGSize(width: ws + rw, height: 1))
            curbTop.position = CGPoint(x: ws / 2, y: y + rw - sw)
            curbTop.fillColor = curbColor
            curbTop.strokeColor = .clear
            curbTop.zPosition = 1.5
            worldNode.addChild(curbTop)
        }

        for col in 0...CityConfig.gridSize {
            let x = CGFloat(col) * CityConfig.cellSize

            let left = SKShapeNode(rectOf: CGSize(width: sw, height: ws + rw))
            left.position = CGPoint(x: x + sw / 2, y: ws / 2)
            left.fillColor = sidewalkColor
            left.strokeColor = .clear
            left.zPosition = 1
            worldNode.addChild(left)

            let right = SKShapeNode(rectOf: CGSize(width: sw, height: ws + rw))
            right.position = CGPoint(x: x + rw - sw / 2, y: ws / 2)
            right.fillColor = sidewalkColor
            right.strokeColor = .clear
            right.zPosition = 1
            worldNode.addChild(right)
        }
    }

    private func drawLaneMarkings(ws: CGFloat, rw: CGFloat) {
        let markingColor = UIColor(white: 1.0, alpha: 0.18)

        for row in 0...CityConfig.gridSize {
            let y = CGFloat(row) * CityConfig.cellSize + rw / 2
            let count = Int(ws / 50)
            for m in 0..<count {
                let dash = SKShapeNode(rectOf: CGSize(width: 20, height: 2))
                dash.position = CGPoint(x: CGFloat(m) * 50 + 25, y: y)
                dash.fillColor = markingColor
                dash.strokeColor = .clear
                dash.zPosition = 1.5
                worldNode.addChild(dash)
            }
        }

        for col in 0...CityConfig.gridSize {
            let x = CGFloat(col) * CityConfig.cellSize + rw / 2
            let count = Int(ws / 50)
            for m in 0..<count {
                let dash = SKShapeNode(rectOf: CGSize(width: 2, height: 20))
                dash.position = CGPoint(x: x, y: CGFloat(m) * 50 + 25)
                dash.fillColor = markingColor
                dash.strokeColor = .clear
                dash.zPosition = 1.5
                worldNode.addChild(dash)
            }
        }
    }

    private func drawCrosswalks(rw: CGFloat) {
        let crossColor = UIColor(white: 1.0, alpha: 0.25)
        let stripeW: CGFloat = 5
        let stripeH: CGFloat = 18
        let stripeCount = 5

        for row in 0..<CityConfig.gridSize {
            for col in 0..<CityConfig.gridSize {
                guard (row + col) % 3 == 0 else { continue }
                let ix = CGFloat(col) * CityConfig.cellSize + rw / 2
                let iy = CGFloat(row) * CityConfig.cellSize + rw / 2

                for s in 0..<stripeCount {
                    let offset = CGFloat(s - stripeCount / 2) * (stripeW + 4)

                    let hStripe = SKShapeNode(rectOf: CGSize(width: stripeH, height: stripeW))
                    hStripe.position = CGPoint(x: ix + offset, y: iy + rw / 2 - 5)
                    hStripe.fillColor = crossColor
                    hStripe.strokeColor = .clear
                    hStripe.zPosition = 1.8
                    worldNode.addChild(hStripe)

                    let vStripe = SKShapeNode(rectOf: CGSize(width: stripeW, height: stripeH))
                    vStripe.position = CGPoint(x: ix + rw / 2 - 5, y: iy + offset)
                    vStripe.fillColor = crossColor
                    vStripe.strokeColor = .clear
                    vStripe.zPosition = 1.8
                    worldNode.addChild(vStripe)
                }
            }
        }
    }

    private func drawTrafficLights(rw: CGFloat) {
        for row in 0..<CityConfig.gridSize {
            for col in 0..<CityConfig.gridSize {
                guard (row + col) % 2 == 0 else { continue }
                let ix = CGFloat(col) * CityConfig.cellSize + rw / 2
                let iy = CGFloat(row) * CityConfig.cellSize + rw / 2

                let lightPositions: [CGPoint] = [
                    CGPoint(x: ix + rw / 2 + 4, y: iy + rw / 2 + 4),
                    CGPoint(x: ix - rw / 2 - 4, y: iy - rw / 2 - 4),
                ]

                for pos in lightPositions {
                    let pole = SKShapeNode(rectOf: CGSize(width: 3, height: 12), cornerRadius: 1)
                    pole.position = pos
                    pole.fillColor = UIColor(white: 0.25, alpha: 1)
                    pole.strokeColor = .clear
                    pole.zPosition = 5
                    trafficLightNode.addChild(pole)

                    let greenLight = SKShapeNode(circleOfRadius: 2.5)
                    greenLight.position = CGPoint(x: pos.x, y: pos.y + 4)
                    greenLight.fillColor = tlGreenOn
                    greenLight.strokeColor = .clear
                    greenLight.zPosition = 5.5
                    trafficLightNode.addChild(greenLight)
                    greenLightNodes.append(greenLight)

                    let redLight = SKShapeNode(circleOfRadius: 2.5)
                    redLight.position = CGPoint(x: pos.x, y: pos.y - 4)
                    redLight.fillColor = tlRedOff
                    redLight.strokeColor = .clear
                    redLight.zPosition = 5.5
                    trafficLightNode.addChild(redLight)
                    redLightNodes.append(redLight)
                }
            }
        }
    }

    private func drawBuildings(rw: CGFloat) {
        let parkLocations: Set<String> = ["4_7", "7_3", "2_5"]

        for row in 0..<CityConfig.gridSize {
            for col in 0..<CityConfig.gridSize {
                let bx = CGFloat(col) * CityConfig.cellSize + rw + CityConfig.blockSize / 2
                let by = CGFloat(row) * CityConfig.cellSize + rw + CityConfig.blockSize / 2
                let key = "\(row)_\(col)"
                let bSize = CityConfig.blockSize - 4

                if parkLocations.contains(key) {
                    drawPark(at: CGPoint(x: bx, y: by), size: bSize)
                } else {
                    drawBuilding(at: CGPoint(x: bx, y: by), size: bSize, row: row, col: col)
                }
            }
        }
    }

    private func drawPark(at center: CGPoint, size: CGFloat) {
        let park = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 6)
        park.position = center
        park.fillColor = UIColor(red: 0.22, green: 0.42, blue: 0.25, alpha: 1)
        park.strokeColor = UIColor(red: 0.18, green: 0.35, blue: 0.20, alpha: 1)
        park.lineWidth = 2
        park.zPosition = 2
        worldNode.addChild(park)

        let pathColor = UIColor(red: 0.35, green: 0.33, blue: 0.30, alpha: 0.6)
        let path1 = SKShapeNode(rectOf: CGSize(width: size * 0.6, height: 4), cornerRadius: 2)
        path1.position = center
        path1.fillColor = pathColor
        path1.strokeColor = .clear
        path1.zPosition = 2.5
        worldNode.addChild(path1)

        let path2 = SKShapeNode(rectOf: CGSize(width: 4, height: size * 0.5), cornerRadius: 2)
        path2.position = CGPoint(x: center.x + 10, y: center.y)
        path2.fillColor = pathColor
        path2.strokeColor = .clear
        path2.zPosition = 2.5
        worldNode.addChild(path2)

        for _ in 0..<7 {
            let treeRadius = CGFloat.random(in: 7...13)
            let tree = SKShapeNode(circleOfRadius: treeRadius)
            tree.position = CGPoint(
                x: center.x + CGFloat.random(in: -size * 0.35...size * 0.35),
                y: center.y + CGFloat.random(in: -size * 0.35...size * 0.35)
            )
            tree.fillColor = UIColor(
                red: CGFloat.random(in: 0.15...0.25),
                green: CGFloat.random(in: 0.45...0.6),
                blue: CGFloat.random(in: 0.18...0.28),
                alpha: 1
            )
            tree.strokeColor = tree.fillColor.darker(by: 0.1)
            tree.lineWidth = 1
            tree.zPosition = 3
            worldNode.addChild(tree)
        }

        let bench = SKShapeNode(rectOf: CGSize(width: 10, height: 4), cornerRadius: 1)
        bench.position = CGPoint(x: center.x - 20, y: center.y)
        bench.fillColor = UIColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1)
        bench.strokeColor = .clear
        bench.zPosition = 3
        worldNode.addChild(bench)
    }

    private func drawBuilding(at center: CGPoint, size: CGFloat, row: Int, col: Int) {
        let inset = CGFloat(abs(row * 3 + col * 7) % 9)
        let actualSize = size - inset
        let color = buildingColors[abs(row * 3 + col * 7) % buildingColors.count]

        let sprite = createBuildingSprite(size: actualSize, color: color, seed: row * 10 + col)
        sprite.position = center
        sprite.zPosition = 2
        worldNode.addChild(sprite)

        let shadowOffset: CGFloat = 4
        let shadow = SKShapeNode(rectOf: CGSize(width: actualSize, height: actualSize), cornerRadius: 3)
        shadow.position = CGPoint(x: center.x + shadowOffset, y: center.y - shadowOffset)
        shadow.fillColor = UIColor(white: 0, alpha: 0.15)
        shadow.strokeColor = .clear
        shadow.zPosition = 1.9
        worldNode.addChild(shadow)

        let bodyNode = SKNode()
        bodyNode.position = center
        bodyNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: actualSize, height: actualSize))
        bodyNode.physicsBody?.isDynamic = false
        bodyNode.physicsBody?.categoryBitMask = PhysicsCategory.building
        bodyNode.physicsBody?.contactTestBitMask = PhysicsCategory.player
        bodyNode.physicsBody?.friction = 0.8
        bodyNode.physicsBody?.restitution = 0.2
        worldNode.addChild(bodyNode)
    }

    private func createBuildingSprite(size: CGFloat, color: UIColor, seed: Int) -> SKSpriteNode {
        let pixelSize = CGSize(width: size, height: size)
        if let cached = buildingTextureCache[seed] {
            let sprite = SKSpriteNode(texture: cached)
            sprite.size = pixelSize
            return sprite
        }
        let renderer = UIGraphicsImageRenderer(size: pixelSize)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: pixelSize)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
            color.setFill()
            path.fill()

            color.darker(by: 0.06).setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: size, height: size * 0.25)).fill()

            color.darker(by: 0.12).setStroke()
            let outline = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: 3)
            outline.lineWidth = 1.5
            outline.stroke()

            let windowSize: CGFloat = max(5, size * 0.08)
            let spacing: CGFloat = max(8, size * 0.12)
            let margin: CGFloat = size * 0.15
            let litChance: Float = 0.65

            var wy = margin
            var rowIdx = 0
            while wy + windowSize < size - margin {
                var wx = margin
                var colIdx = 0
                while wx + windowSize < size - margin {
                    let hash = abs(seed * 31 + rowIdx * 7 + colIdx * 13)
                    let isLit = Float(hash % 100) / 100.0 < litChance

                    if isLit {
                        UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.85).setFill()
                    } else {
                        UIColor(red: 0.25, green: 0.3, blue: 0.4, alpha: 0.5).setFill()
                    }
                    UIBezierPath(rect: CGRect(x: wx, y: wy, width: windowSize, height: windowSize)).fill()
                    wx += windowSize + spacing
                    colIdx += 1
                }
                wy += windowSize + spacing
                rowIdx += 1
            }

            if seed % 4 == 0 {
                UIColor(white: 0.3, alpha: 0.6).setFill()
                UIBezierPath(rect: CGRect(x: size * 0.35, y: size * 0.05, width: size * 0.15, height: size * 0.1)).fill()
            }
            if seed % 5 == 0 {
                UIColor(white: 0.28, alpha: 0.5).setFill()
                UIBezierPath(roundedRect: CGRect(x: size * 0.6, y: size * 0.03, width: size * 0.12, height: size * 0.12), cornerRadius: 2).fill()
            }
        }

        let texture = SKTexture(image: image)
        buildingTextureCache[seed] = texture
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = pixelSize
        return sprite
    }

    private func drawSidewalkTrees(rw: CGFloat, sw: CGFloat) {
        for row in 0..<CityConfig.gridSize {
            for col in 0..<CityConfig.gridSize {
                guard (row + col) % 3 == 0 else { continue }
                let bx = CGFloat(col) * CityConfig.cellSize + rw + CityConfig.blockSize / 2
                let roadY = CGFloat(row) * CityConfig.cellSize

                let treePos = CGPoint(x: bx - CityConfig.blockSize / 2 - sw / 2 - 2, y: roadY + sw / 2)
                let tree = SKShapeNode(circleOfRadius: 5)
                tree.position = treePos
                tree.fillColor = UIColor(red: 0.2, green: 0.5, blue: 0.25, alpha: 1)
                tree.strokeColor = UIColor(red: 0.15, green: 0.4, blue: 0.2, alpha: 1)
                tree.lineWidth = 1
                tree.zPosition = 3.5
                worldNode.addChild(tree)

                let trunk = SKShapeNode(rectOf: CGSize(width: 2, height: 3))
                trunk.position = CGPoint(x: treePos.x, y: treePos.y - 3)
                trunk.fillColor = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1)
                trunk.strokeColor = .clear
                trunk.zPosition = 3.4
                worldNode.addChild(trunk)
            }
        }
    }

    // MARK: - Player

    private func setupPlayer() {
        let body = SKShapeNode(rectOf: CGSize(width: 22, height: 12), cornerRadius: 3)
        body.fillColor = UIColor(red: 1.0, green: 0.82, blue: 0.1, alpha: 1)
        body.strokeColor = UIColor(red: 0.85, green: 0.7, blue: 0.05, alpha: 1)
        body.lineWidth = 1.5
        body.zPosition = 10

        let front = SKShapeNode(rectOf: CGSize(width: 5, height: 8), cornerRadius: 1)
        front.fillColor = UIColor(red: 0.9, green: 0.72, blue: 0.05, alpha: 1)
        front.strokeColor = .clear
        front.position = CGPoint(x: 10, y: 0)
        body.addChild(front)

        let headlight = SKShapeNode(circleOfRadius: 2)
        headlight.fillColor = .white
        headlight.strokeColor = .clear
        headlight.position = CGPoint(x: 12, y: 0)
        headlight.zPosition = 1
        body.addChild(headlight)

        let packageBox = SKShapeNode(rectOf: CGSize(width: 8, height: 8), cornerRadius: 1)
        packageBox.fillColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)
        packageBox.strokeColor = UIColor(red: 0.5, green: 0.3, blue: 0.15, alpha: 1)
        packageBox.position = CGPoint(x: -5, y: 0)
        packageBox.name = "packageIndicator"
        packageBox.isHidden = true
        body.addChild(packageBox)

        playerNode.addChild(body)
        playerNode.zPosition = 10

        let startX = CityConfig.cellSize * 5 + CityConfig.roadWidth / 2
        let startY = CityConfig.cellSize * 5 + CityConfig.roadWidth / 2
        playerNode.position = CGPoint(x: startX, y: startY)

        playerNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 22, height: 12))
        playerNode.physicsBody?.categoryBitMask = PhysicsCategory.player
        playerNode.physicsBody?.collisionBitMask = PhysicsCategory.building | PhysicsCategory.boundary
        playerNode.physicsBody?.contactTestBitMask = PhysicsCategory.traffic | PhysicsCategory.police | PhysicsCategory.pickup | PhysicsCategory.delivery | PhysicsCategory.building
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.linearDamping = 4.0
        playerNode.physicsBody?.mass = 1.0
        playerNode.physicsBody?.restitution = 0.3
        playerNode.physicsBody?.friction = 0.3

        worldNode.addChild(playerNode)
    }

    private func setupWorldBoundary() {
        let ws = CityConfig.worldSize + CityConfig.roadWidth
        let boundary = SKPhysicsBody(edgeLoopFrom: CGRect(x: -10, y: -10, width: ws + 20, height: ws + 20))
        boundary.categoryBitMask = PhysicsCategory.boundary
        boundary.friction = 0.5
        let boundaryNode = SKNode()
        boundaryNode.physicsBody = boundary
        worldNode.addChild(boundaryNode)
    }

    // MARK: - Mission Markers

    func setupMission(_ mission: Mission) {
        markerNode.removeAllChildren()

        let pickupPos = mission.pickup.markerPosition
        let emoji = mission.pickup.emoji
        let marker = createMarker(at: pickupPos, color: UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1), label: "PICK UP", emoji: emoji, name: "pickup")
        markerNode.addChild(marker)
        pickupMarker = marker
        deliveryMarker = nil
    }

    func showDeliveryMarker() {
        guard let mission = viewModel?.currentMission else { return }
        markerNode.removeAllChildren()
        pickupMarker = nil

        let markerPos = mission.delivery.markerPosition
        let buildingPos = mission.delivery.worldPosition
        let emoji = mission.delivery.emoji
        let marker = createMarker(at: markerPos, color: UIColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1), label: "DELIVER", emoji: emoji, name: "delivery")
        markerNode.addChild(marker)
        deliveryMarker = marker

        let windowGlow = SKShapeNode(rectOf: CGSize(width: 18, height: 14), cornerRadius: 2)
        windowGlow.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.9)
        windowGlow.strokeColor = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1)
        windowGlow.lineWidth = 1
        windowGlow.position = CGPoint(x: buildingPos.x, y: buildingPos.y + 25)
        windowGlow.zPosition = 15
        windowGlow.name = "windowGlow"
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        windowGlow.run(SKAction.repeatForever(pulse))
        markerNode.addChild(windowGlow)

        playerNode.childNode(withName: "//packageIndicator")?.isHidden = false
        missionTimerActive = true
    }

    private func createMarker(at position: CGPoint, color: UIColor, label: String, emoji: String, name: String) -> SKNode {
        let container = SKNode()
        container.position = position
        container.name = name
        container.zPosition = 20

        let ring = SKShapeNode(circleOfRadius: 30)
        ring.fillColor = color.withAlphaComponent(0.15)
        ring.strokeColor = color
        ring.lineWidth = 3
        ring.glowWidth = 4
        container.addChild(ring)

        let innerRing = SKShapeNode(circleOfRadius: 18)
        innerRing.fillColor = color.withAlphaComponent(0.3)
        innerRing.strokeColor = color
        innerRing.lineWidth = 2
        container.addChild(innerRing)

        let emojiLabel = SKLabelNode(text: emoji)
        emojiLabel.fontSize = 20
        emojiLabel.verticalAlignmentMode = .center
        emojiLabel.horizontalAlignmentMode = .center
        emojiLabel.position = .zero
        emojiLabel.zPosition = 1
        container.addChild(emojiLabel)

        let labelNode = SKLabelNode(text: label)
        labelNode.fontName = "AvenirNext-Bold"
        labelNode.fontSize = 10
        labelNode.fontColor = color
        labelNode.position = CGPoint(x: 0, y: -45)
        container.addChild(labelNode)

        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        ring.run(SKAction.repeatForever(pulseAction))

        let triggerZone = SKNode()
        triggerZone.position = .zero
        triggerZone.physicsBody = SKPhysicsBody(circleOfRadius: 35)
        triggerZone.physicsBody?.isDynamic = false
        triggerZone.physicsBody?.categoryBitMask = name == "pickup" ? PhysicsCategory.pickup : PhysicsCategory.delivery
        triggerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        triggerZone.name = "\(name)Zone"
        container.addChild(triggerZone)

        return container
    }

    func clearMission() {
        markerNode.removeAllChildren()
        pickupMarker = nil
        deliveryMarker = nil
        throwInFlight = false
        missionTimerActive = false
        playerNode.childNode(withName: "//packageIndicator")?.isHidden = true
    }

    // MARK: - Police

    func spawnPolice() {
        for _ in 0..<2 {
            let police = createPoliceVehicle()
            let edge = Int.random(in: 0...3)
            let ws = CityConfig.worldSize
            switch edge {
            case 0: police.position = CGPoint(x: CGFloat.random(in: 0...ws), y: -50)
            case 1: police.position = CGPoint(x: CGFloat.random(in: 0...ws), y: ws + 50)
            case 2: police.position = CGPoint(x: -50, y: CGFloat.random(in: 0...ws))
            default: police.position = CGPoint(x: ws + 50, y: CGFloat.random(in: 0...ws))
            }
            policeNode.addChild(police)
        }
    }

    private func createPoliceVehicle() -> SKNode {
        let node = SKNode()
        node.name = "police"
        node.zPosition = 10

        let body = SKShapeNode(rectOf: CGSize(width: 24, height: 13), cornerRadius: 3)
        body.fillColor = UIColor(red: 0.15, green: 0.2, blue: 0.6, alpha: 1)
        body.strokeColor = UIColor(red: 0.1, green: 0.15, blue: 0.5, alpha: 1)
        body.lineWidth = 1.5
        node.addChild(body)

        let stripe = SKShapeNode(rectOf: CGSize(width: 20, height: 3))
        stripe.fillColor = .white
        stripe.strokeColor = .clear
        node.addChild(stripe)

        let lightR = SKShapeNode(circleOfRadius: 3)
        lightR.fillColor = .red
        lightR.strokeColor = .clear
        lightR.position = CGPoint(x: -4, y: 0)
        lightR.zPosition = 1
        node.addChild(lightR)

        let lightB = SKShapeNode(circleOfRadius: 3)
        lightB.fillColor = .blue
        lightB.strokeColor = .clear
        lightB.position = CGPoint(x: 4, y: 0)
        lightB.zPosition = 1
        node.addChild(lightB)

        let flashAction = SKAction.sequence([
            SKAction.run { lightR.alpha = 1; lightB.alpha = 0.2 },
            SKAction.wait(forDuration: 0.2),
            SKAction.run { lightR.alpha = 0.2; lightB.alpha = 1 },
            SKAction.wait(forDuration: 0.2)
        ])
        node.run(SKAction.repeatForever(flashAction))

        node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 24, height: 13))
        node.physicsBody?.categoryBitMask = PhysicsCategory.police
        node.physicsBody?.collisionBitMask = PhysicsCategory.building | PhysicsCategory.boundary
        node.physicsBody?.contactTestBitMask = PhysicsCategory.player
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.linearDamping = 3.0
        node.physicsBody?.mass = 1.2

        return node
    }

    func clearPolice() {
        policeNode.removeAllChildren()
    }

    // MARK: - Traffic

    private func spawnTraffic() {
        guard trafficNode.children.count < 22 else { return }

        let isHorizontal = Bool.random()
        let ws = CityConfig.worldSize
        let roadIndex = Int.random(in: 0..<CityConfig.gridSize)
        let roadCenter = CGFloat(roadIndex) * CityConfig.cellSize + CityConfig.roadWidth / 2
        let laneOffset = CGFloat.random(in: -12...12)
        let goingPositive = Bool.random()

        let vehicle = createTrafficVehicle()
        if isHorizontal {
            vehicle.position = CGPoint(
                x: goingPositive ? -30 : ws + 30,
                y: roadCenter + laneOffset
            )
            vehicle.zRotation = goingPositive ? 0 : .pi
            let vx: CGFloat = goingPositive ? CGFloat.random(in: 70...170) : -CGFloat.random(in: 70...170)
            npcVelocities[ObjectIdentifier(vehicle)] = CGVector(dx: vx, dy: 0)
        } else {
            vehicle.position = CGPoint(
                x: roadCenter + laneOffset,
                y: goingPositive ? -30 : ws + 30
            )
            vehicle.zRotation = goingPositive ? .pi / 2 : -.pi / 2
            let vy: CGFloat = goingPositive ? CGFloat.random(in: 70...170) : -CGFloat.random(in: 70...170)
            npcVelocities[ObjectIdentifier(vehicle)] = CGVector(dx: 0, dy: vy)
        }

        trafficNode.addChild(vehicle)
    }

    private func createTrafficVehicle() -> SKNode {
        let node = SKNode()
        node.name = "traffic"
        node.zPosition = 9

        let carColors: [UIColor] = [
            UIColor(red: 0.7, green: 0.15, blue: 0.15, alpha: 1),
            UIColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1),
            UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1),
            UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1),
            UIColor(red: 0.2, green: 0.55, blue: 0.25, alpha: 1),
            UIColor(red: 0.6, green: 0.3, blue: 0.5, alpha: 1),
            UIColor(red: 0.85, green: 0.75, blue: 0.3, alpha: 1),
            UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1),
        ]

        let isTruck = Int.random(in: 0...5) == 0
        let carW: CGFloat = isTruck ? 30 : 22
        let carH: CGFloat = isTruck ? 14 : 12

        let body = SKShapeNode(rectOf: CGSize(width: carW, height: carH), cornerRadius: isTruck ? 2 : 3)
        body.fillColor = carColors.randomElement()!
        body.strokeColor = body.fillColor.darker(by: 0.2)
        body.lineWidth = 1
        node.addChild(body)

        if !isTruck {
            let windshield = SKShapeNode(rectOf: CGSize(width: 6, height: 8), cornerRadius: 1)
            windshield.fillColor = UIColor(red: 0.5, green: 0.7, blue: 0.85, alpha: 0.7)
            windshield.strokeColor = .clear
            windshield.position = CGPoint(x: 5, y: 0)
            node.addChild(windshield)
        }

        let tailLight1 = SKShapeNode(circleOfRadius: 1.5)
        tailLight1.fillColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 0.8)
        tailLight1.strokeColor = .clear
        tailLight1.position = CGPoint(x: -carW / 2, y: carH / 2 - 3)
        tailLight1.zPosition = 1
        node.addChild(tailLight1)

        let tailLight2 = SKShapeNode(circleOfRadius: 1.5)
        tailLight2.fillColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 0.8)
        tailLight2.strokeColor = .clear
        tailLight2.position = CGPoint(x: -carW / 2, y: -carH / 2 + 3)
        tailLight2.zPosition = 1
        node.addChild(tailLight2)

        node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: carW, height: carH))
        node.physicsBody?.categoryBitMask = PhysicsCategory.traffic
        node.physicsBody?.collisionBitMask = PhysicsCategory.building | PhysicsCategory.boundary | PhysicsCategory.traffic
        node.physicsBody?.contactTestBitMask = PhysicsCategory.player
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.linearDamping = 2.0
        node.physicsBody?.mass = 1.5

        return node
    }

    // MARK: - Pedestrians

    private func spawnPedestrian() {
        guard pedestrianNode.children.count < 18 else { return }

        let ws = CityConfig.worldSize
        let rw = CityConfig.roadWidth
        let sw = CityConfig.sidewalkWidth
        let isHorizontal = Bool.random()
        let roadIndex = Int.random(in: 0...CityConfig.gridSize)
        let goingPositive = Bool.random()

        let pedColors: [UIColor] = [
            UIColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1),
            UIColor(red: 0.6, green: 0.4, blue: 0.3, alpha: 1),
            UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1),
            UIColor(red: 0.7, green: 0.3, blue: 0.4, alpha: 1),
            UIColor(red: 0.4, green: 0.6, blue: 0.4, alpha: 1),
            UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1),
        ]

        let ped = SKShapeNode(circleOfRadius: 3)
        ped.fillColor = pedColors.randomElement()!
        ped.strokeColor = ped.fillColor.darker(by: 0.15)
        ped.lineWidth = 0.5
        ped.zPosition = 4
        ped.name = "pedestrian"

        let sidewalkSide = Bool.random()
        let sidewalkOffset = sidewalkSide ? (sw / 2) : (rw - sw / 2)
        let speed = CGFloat.random(in: 25...50)

        if isHorizontal {
            let roadY = CGFloat(roadIndex) * CityConfig.cellSize + sidewalkOffset
            let startX: CGFloat = goingPositive ? -10 : ws + 10
            let endX: CGFloat = goingPositive ? ws + 20 : -20
            ped.position = CGPoint(x: startX, y: roadY)
            let duration = Double(abs(endX - startX) / speed)
            ped.run(SKAction.sequence([SKAction.moveTo(x: endX, duration: duration), .removeFromParent()]))
        } else {
            let roadX = CGFloat(roadIndex) * CityConfig.cellSize + sidewalkOffset
            let startY: CGFloat = goingPositive ? -10 : ws + 10
            let endY: CGFloat = goingPositive ? ws + 20 : -20
            ped.position = CGPoint(x: roadX, y: startY)
            let duration = Double(abs(endY - startY) / speed)
            ped.run(SKAction.sequence([SKAction.moveTo(y: endY, duration: duration), .removeFromParent()]))
        }

        pedestrianNode.addChild(ped)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard viewModel?.gamePhase == .playing else { return }

        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 1.0 / 60.0
        } else {
            dt = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        }
        lastUpdateTime = currentTime

        updatePlayer(dt)
        updateCamera()
        updateTraffic(dt)
        updatePolice(dt)
        updateTrafficLights(dt)
        updateMissionTimer(dt)
        updateThrowProximity()

        crashCooldown = max(0, crashCooldown - dt)
        trafficSpawnTimer += dt
        if trafficSpawnTimer > 1.0 {
            trafficSpawnTimer = 0
            spawnTraffic()
        }

        pedestrianSpawnTimer += dt
        if pedestrianSpawnTimer > 1.8 {
            pedestrianSpawnTimer = 0
            spawnPedestrian()
        }
    }

    private func updatePlayer(_ dt: TimeInterval) {
        guard let vm = viewModel else { return }
        let joy = vm.joystickDirection
        let joyMag = hypot(joy.dx, joy.dy)

        if joyMag > 0.1 {
            let targetAngle = atan2(joy.dy, joy.dx)
            let currentSpeed = hypot(
                playerNode.physicsBody?.velocity.dx ?? 0,
                playerNode.physicsBody?.velocity.dy ?? 0
            )
            let speedFactor = max(0.3, 1.0 - currentSpeed / 400.0)
            var angleDiff = targetAngle - playerAngle
            while angleDiff > .pi { angleDiff -= 2 * .pi }
            while angleDiff < -.pi { angleDiff += 2 * .pi }
            playerAngle += angleDiff * turnSpeed * speedFactor * CGFloat(dt)

            let force = CGVector(
                dx: cos(playerAngle) * thrustForce * min(joyMag, 1.0),
                dy: sin(playerAngle) * thrustForce * min(joyMag, 1.0)
            )
            playerNode.physicsBody?.applyForce(force)
        }

        playerNode.physicsBody?.clampSpeed(to: maxSpeed)

        playerNode.zRotation = playerAngle
        viewModel?.playerPosition = playerNode.position
    }

    private func updateCamera() {
        let target = playerNode.position
        let smoothing: CGFloat = 0.1
        let newX = cameraNode.position.x + (target.x - cameraNode.position.x) * smoothing
        let newY = cameraNode.position.y + (target.y - cameraNode.position.y) * smoothing
        cameraNode.position = CGPoint(x: newX, y: newY)
    }

    private func updateTraffic(_ dt: TimeInterval) {
        let ws = CityConfig.worldSize
        for vehicle in trafficNode.children {
            let vel = npcVelocities[ObjectIdentifier(vehicle)] ?? .zero
            vehicle.physicsBody?.velocity = vel

            if vehicle.position.x < -60 || vehicle.position.x > ws + 60 ||
               vehicle.position.y < -60 || vehicle.position.y > ws + 60 {
                npcVelocities.removeValue(forKey: ObjectIdentifier(vehicle))
                vehicle.removeFromParent()
            }
        }
    }

    private func updatePolice(_ dt: TimeInterval) {
        for cop in policeNode.children {
            let dx = playerNode.position.x - cop.position.x
            let dy = playerNode.position.y - cop.position.y
            let angle = atan2(dy, dx)
            cop.zRotation = angle

            let chaseSpeed: CGFloat = 220
            let force = CGVector(dx: cos(angle) * chaseSpeed * 3, dy: sin(angle) * chaseSpeed * 3)
            cop.physicsBody?.applyForce(force)

            cop.physicsBody?.clampSpeed(to: chaseSpeed)
        }
    }

    private func updateTrafficLights(_ dt: TimeInterval) {
        trafficLightTimer += dt
        guard trafficLightTimer > 6.0 else { return }
        trafficLightTimer = 0
        trafficLightGreen.toggle()
        let gColor = trafficLightGreen ? tlGreenOn : tlGreenOff
        let rColor = trafficLightGreen ? tlRedOff  : tlRedOn
        for light in greenLightNodes { light.fillColor = gColor }
        for light in redLightNodes   { light.fillColor = rColor }
    }

    private func updateMissionTimer(_ dt: TimeInterval) {
        guard let vm = viewModel, missionTimerActive else { return }
        vm.missionTimeRemaining -= dt
        if vm.missionTimeRemaining <= 0 {
            vm.missionTimeRemaining = 0
            missionTimerActive = false
            vm.missionTimedOut()
        }
    }

    private func updateThrowProximity() {
        guard !throwInFlight else { return }
        guard let vm = viewModel, let mission = vm.currentMission, mission.pickedUp else {
            viewModel?.canThrow = false
            return
        }

        let markerPos = mission.delivery.markerPosition
        let dist = hypot(playerNode.position.x - markerPos.x, playerNode.position.y - markerPos.y)
        vm.canThrow = dist < 80

        if vm.throwRequested && vm.canThrow {
            vm.throwRequested = false
            vm.canThrow = false
            throwInFlight = true
            throwPackage(to: mission.delivery.worldPosition)
        }
    }

    // MARK: - Package Throw

    private func throwPackage(to target: CGPoint) {
        let pkg = SKShapeNode(rectOf: CGSize(width: 10, height: 10), cornerRadius: 2)
        pkg.fillColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)
        pkg.strokeColor = UIColor(red: 0.5, green: 0.3, blue: 0.15, alpha: 1)
        pkg.lineWidth = 1.5
        pkg.position = playerNode.position
        pkg.zPosition = 20
        worldNode.addChild(pkg)

        playerNode.childNode(withName: "//packageIndicator")?.isHidden = true

        let windowTarget = CGPoint(x: target.x, y: target.y + 25)
        let flyAction = SKAction.move(to: windowTarget, duration: 0.5)
        flyAction.timingMode = .easeIn

        let rotate = SKAction.rotate(byAngle: .pi * 3, duration: 0.5)
        let scale = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.25),
            SKAction.scale(to: 0.5, duration: 0.25)
        ])

        let group = SKAction.group([flyAction, rotate, scale])

        pkg.run(group) { [weak self] in
            self?.throwInFlight = false
            pkg.removeFromParent()
            self?.showDeliveryEffect(at: windowTarget)
            self?.viewModel?.deliverPackage()
        }
    }

    private func showParticleEffect(at position: CGPoint, count: Int,
                                    radiusRange: ClosedRange<CGFloat>, distRange: ClosedRange<CGFloat>,
                                    duration: Double, colors: [UIColor]) {
        for _ in 0..<count {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: radiusRange))
            particle.fillColor = colors.randomElement()!
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 20
            worldNode.addChild(particle)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: distRange)
            let target = CGPoint(x: position.x + cos(angle) * dist, y: position.y + sin(angle) * dist)
            let move = SKAction.move(to: target, duration: duration)
            move.timingMode = .easeOut
            particle.run(SKAction.group([move, SKAction.fadeOut(withDuration: duration)])) {
                particle.removeFromParent()
            }
        }
    }

    private func showDeliveryEffect(at position: CGPoint) {
        showParticleEffect(at: position, count: 12, radiusRange: 2...5, distRange: 30...70,
                           duration: 0.6, colors: [.yellow, .orange, .green, .white])
        if let windowGlow = markerNode.childNode(withName: "windowGlow") {
            let flash = SKAction.sequence([
                SKAction.scale(to: 3.0, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.3)
            ])
            windowGlow.run(flash) { windowGlow.removeFromParent() }
        }
    }

    // MARK: - Contacts

    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        MainActor.assumeIsolated {
            handleContact(contact)
        }
    }

    private func handleContact(_ contact: SKPhysicsContact) {
        let a = contact.bodyA.categoryBitMask
        let b = contact.bodyB.categoryBitMask
        let combined = a | b

        if combined & PhysicsCategory.pickup != 0 && combined & PhysicsCategory.player != 0 {
            viewModel?.pickupPackage()
            return
        }

        if combined & PhysicsCategory.delivery != 0 && combined & PhysicsCategory.player != 0 {
            return
        }

        if combined & PhysicsCategory.police != 0 && combined & PhysicsCategory.player != 0 {
            viewModel?.caughtByPolice()
            return
        }

        guard crashCooldown <= 0 else { return }

        if combined & PhysicsCategory.traffic != 0 && combined & PhysicsCategory.player != 0 {
            crashCooldown = 1.0
            let impactSpeed = hypot(
                playerNode.physicsBody?.velocity.dx ?? 0,
                playerNode.physicsBody?.velocity.dy ?? 0
            )
            viewModel?.applyCrashPenalty(35)
            if impactSpeed > 150 {
                viewModel?.policeAlert = true
                viewModel?.missionMessage = "Hard crash! Police alerted!"
            }
            applyCrashImpulse(contact)
            showCrashEffect(at: contact.contactPoint)
            return
        }

        if combined & PhysicsCategory.building != 0 && combined & PhysicsCategory.player != 0 {
            let speed = hypot(
                playerNode.physicsBody?.velocity.dx ?? 0,
                playerNode.physicsBody?.velocity.dy ?? 0
            )
            if speed > 100 {
                crashCooldown = 0.5
                viewModel?.applyCrashPenalty(10)
                showCrashEffect(at: contact.contactPoint)
            }
        }
    }

    private func applyCrashImpulse(_ contact: SKPhysicsContact) {
        let impulseStrength: CGFloat = 80
        let dx = playerNode.position.x - contact.contactPoint.x
        let dy = playerNode.position.y - contact.contactPoint.y
        let dist = max(hypot(dx, dy), 1)
        playerNode.physicsBody?.applyImpulse(CGVector(dx: dx / dist * impulseStrength, dy: dy / dist * impulseStrength))
    }

    private func showCrashEffect(at point: CGPoint) {
        showParticleEffect(at: point, count: 8, radiusRange: 1...4, distRange: 12...30,
                           duration: 0.3, colors: [.orange, .yellow, .red])
    }
}

extension UIColor {
    func darker(by percentage: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: max(b - percentage, 0), alpha: a)
    }
}

extension SKPhysicsBody {
    func clampSpeed(to maxSpeed: CGFloat) {
        let speed = hypot(velocity.dx, velocity.dy)
        guard speed > maxSpeed else { return }
        let ratio = maxSpeed / speed
        velocity = CGVector(dx: velocity.dx * ratio, dy: velocity.dy * ratio)
    }
}