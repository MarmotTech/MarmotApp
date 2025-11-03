import SwiftUI
import SpriteKit
import CoreMotion

class GlobeScene: SKScene {
    private let motionManager = CMMotionManager()
    private var currentSpriteHeld: SKSpriteNode?
    private let ballSpawnInterval: TimeInterval = 0.05
    
    private let emojis = [
        "😀",
        "😍",
        "😎",
        "😘",
        "😜",
        "😝",
        "😀",
        "😁",
        "😂",
        "🤣",
        "😃",
        "😄",
        "🥰",
        "🥹"
    ]
    
    func makeBall(at position: CGPoint) -> SKSpriteNode {
        if Double.random(in: 0...1) < 0.3 {
            return makeEmoji(at: position)
        }
        
        return makeHuggingFace(at: position)
    }
    
    func makeEmoji(at position: CGPoint) -> SKSpriteNode {
        let emoji = SKLabelNode(text: emojis.randomElement())
        emoji.fontSize = 60
        let texture = view!.texture(from: emoji)!
        
        let ball = SKSpriteNode(texture: texture)
        ball.size = CGSize(width: 58, height: 58)
        ball.position = position
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.restitution = 0.6
        return ball
    }
    
    func makeHuggingFace(at position: CGPoint) -> SKSpriteNode {
        let ball = SKSpriteNode(imageNamed: "HuggingFaceLogo")
        ball.size = CGSize(width: 68, height: 68)
        ball.position = position
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.restitution = 0.6
        return ball
    }
    
    func velocityCheck(vel: CGVector) -> CGVector {
        let maxSpeed: CGFloat = 1500.0
        let speed = sqrt(vel.dx * vel.dx + vel.dy * vel.dy)
        if speed > maxSpeed {
            let scale = maxSpeed / speed
            return CGVector(dx: vel.dx * scale, dy: vel.dy * scale)
        }
        return vel
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let sprite = currentSpriteHeld else { return }
        let location = touch.location(in: self)
        moveBall(sprite: sprite, to: location)
    }
    
    func moveBall(sprite: SKSpriteNode, to location: CGPoint) {
        sprite.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        
        let dx = location.x - sprite.position.x
        let dy = location.y - sprite.position.y
        
        let drag: CGFloat = 0.01
        var vel = CGVector(dx: dx / drag, dy: dy / drag)
        vel = velocityCheck(vel: vel)
        sprite.physicsBody?.velocity = vel
        sprite.position = location
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let ball = self.atPoint(location) as? SKSpriteNode {
            currentSpriteHeld = ball
            ball.physicsBody?.isDynamic = false
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let sprite = currentSpriteHeld else { return }
        let currentLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        
        let dx = currentLocation.x - previousLocation.x
        let dy = currentLocation.y - previousLocation.y
        
        let throwMultiplier: CGFloat = 150.0
        let throwVelocity = CGVector(dx: dx * throwMultiplier, dy: dy * throwMultiplier)
        
        sprite.physicsBody?.isDynamic = true
        sprite.physicsBody?.velocity = throwVelocity

        currentSpriteHeld = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentSpriteHeld = nil
    }
    
    func makeWalls(size: CGSize) -> SKSpriteNode {
        let walls = SKSpriteNode(color: .clear, size: size)
        walls.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(
            origin: CGPoint(x: 0, y: 20),
            size: CGSize(width: size.width, height: size.height + 80)
        ))
        walls.physicsBody?.isDynamic = false
        return walls
    }
    
    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                guard let self = self, let motion = motion else { return }
                
                let gravityX = motion.gravity.x * 9
                var gravityY = motion.gravity.y * 9
                
                if abs(gravityY) < 2 {
                    gravityY -= 9
                }
                
                self.physicsWorld.gravity = CGVector(dx: gravityX, dy: gravityY)
            }
        }
    }
    
    func spawnBall() {
        let randomX = CGFloat.random(in: 0...size.width)
        let ballPosition = CGPoint(x: randomX, y: size.height + 80)
        let ball = makeBall(at: ballPosition)
        addChild(ball)
    }
    
    func startSpawningBalls() {
        let wait = SKAction.wait(forDuration: ballSpawnInterval)
        let spawn = SKAction.run { [weak self] in
            self?.spawnBall()
        }
        let sequence = SKAction.sequence([spawn, wait])
        let repeatForever = SKAction.repeat(sequence, count: 50)
        run(repeatForever, withKey: "ballSpawning")
    }
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        addChild(makeWalls(size: size))
        
        startMotionUpdates()
        startSpawningBalls()
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct GlobeView: View {
    var body: some View {
        GeometryReader { geometry in
            SpriteView(
                scene: GlobeScene(
                    size: CGSize(width: geometry.size.width, height: geometry.size.height + 20)
                ),
                options: [.allowsTransparency]
            )
            .frame(
                width: geometry.size.width,
                height: geometry.size.height + 20
            )
        }
    }
}
