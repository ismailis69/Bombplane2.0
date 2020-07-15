// 
//  GameScene.swift
//  Bombplane
//
//  Created by Steven Ismaili

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    let birdTimePerFrame = 0.1
    let maxTimeBgMoving: CGFloat = 3
    let bgAnimatedInSecs: TimeInterval = 7
    let haptics = UINotificationFeedbackGenerator()

    var bird: SKSpriteNode = SKSpriteNode()
    var background: SKSpriteNode = SKSpriteNode()
    var scoreLabel: SKLabelNode = SKLabelNode()
    var score: Int = 0
    var gameOver: Bool = false
    var gameOverLabel: SKLabelNode = SKLabelNode()
    var timer: Timer = Timer()

    enum ColliderType: UInt32 {
        case Bird = 1
        case Object = 2
        case Gap = 4
    }

    override func didMove(to view: SKView) -> Void {
        self.physicsWorld.contactDelegate = self
        initializeGame()
    }

    func initializeGame() -> Void {
        timer = Timer.scheduledTimer(
            timeInterval: 3,
             target: self,
             selector: #selector(self.drawPipes),
             userInfo: nil,
             repeats: true
        )

        drawBackground()
        drawBird()
        drawPipes()
    }

    func drawBird() -> Void {
        let birdTexture = SKTexture(imageNamed: "canary1.png")
        let birdTexture2 = SKTexture(imageNamed: "canary1.png")

        let animation = SKAction.animate(with: [birdTexture, birdTexture2], timePerFrame: birdTimePerFrame)
        let makeBirdFlap = SKAction.repeatForever(animation)

        bird = SKSpriteNode(texture: birdTexture)

        bird.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        bird.run(makeBirdFlap)

        // For colisions
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdTexture.size().height / 2 - 10)

        bird.physicsBody!.isDynamic = false

        bird.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        bird.physicsBody!.categoryBitMask = ColliderType.Bird.rawValue
        bird.physicsBody!.collisionBitMask = ColliderType.Bird.rawValue

        self.addChild(bird)

        makeGround()

        self.setScoreStyle()

        scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.height / 2 - 120)
        self.addChild(scoreLabel)
    }

    func drawBackground() -> Void {
        let bgTexture = SKTexture(imageNamed: "background.jpg")

        let moveBgAnimation = SKAction.move(by: CGVector(dx: -bgTexture.size().width, dy: 0), duration: bgAnimatedInSecs)
        let shiftBgAnimation = SKAction.move(by: CGVector(dx: bgTexture.size().width, dy: 0), duration: 0)
        let bgAnimation = SKAction.sequence([moveBgAnimation, shiftBgAnimation])
        let moveBgForever = SKAction.repeatForever(bgAnimation)

        var i: CGFloat = 0

        while i < maxTimeBgMoving {
            background = SKSpriteNode(texture: bgTexture)
            background.position = CGPoint(x: bgTexture.size().width * i , y: self.frame.midY)
            background.size.height = self.frame.height
            background.run(moveBgForever)

            self.addChild(background)

            i += 1

            // Set background first
            background.zPosition = -100
        }
    }

    // Draws the pipes and move them around the bird
    @objc func drawPipes() -> Void {
        let gapHeight = bird.size.height * 2

        let movePipes = SKAction.move(
            by: CGVector(dx: -2 * self.frame.width, dy: 0),
            duration: TimeInterval(self.frame.width / 100)
        )

        let removePipes = SKAction.removeFromParent()

        let movementAmount = arc4random() % UInt32(self.frame.height / 2)
        let moveAndRemovePipes = SKAction.sequence([movePipes, removePipes])

        let pipeOffset = CGFloat(movementAmount) - self.frame.height / 4

        makePipe1(moveAndRemovePipes, gapHeight, pipeOffset)
        makePipe2(moveAndRemovePipes, gapHeight, pipeOffset)
        makeGap(moveAndRemovePipes, gapHeight, pipeOffset)
    }

    func didBegin(_ contact: SKPhysicsContact) -> Void {
        if gameOver == false {
            if contact.bodyA.categoryBitMask == ColliderType.Gap.rawValue ||
                contact.bodyB.categoryBitMask == ColliderType.Gap.rawValue {
                score += 1
                scoreLabel.text = String(score)
            } else {
                resetGame()

                setMessageScoreStyle()
                gameOverLabel.text = "Game Over"
                gameOverLabel.position = CGPoint(x: self.frame.midY, y: self.frame.midY)

                self.addChild(gameOverLabel)
            }
        }
    }

    func makePipe1(_ moveAndRemovePipes: SKAction, _ gapHeight: CGFloat, _ pipeOffset: CGFloat) -> Void {
        let pipeTexture = SKTexture(imageNamed: "pipe1.png")
        let pipe1 = SKSpriteNode(texture: pipeTexture)
        pipe1.position = CGPoint(
            x: self.frame.midX + self.frame.width,
            y: self.frame.midY + pipeTexture.size().height / 2 + gapHeight / 2 + pipeOffset
        )
        pipe1.run(moveAndRemovePipes)

        pipe1.physicsBody = SKPhysicsBody(rectangleOf: pipeTexture.size())
        pipe1.physicsBody!.isDynamic = false

        pipe1.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        pipe1.physicsBody!.categoryBitMask = ColliderType.Object.rawValue
        pipe1.physicsBody!.collisionBitMask = ColliderType.Object.rawValue
        setPipePosition(pipe1)

        self.addChild(pipe1)
    }

    func makePipe2(_ moveAndRemovePipes: SKAction, _ gapHeight: CGFloat, _ pipeOffset: CGFloat) -> Void {
        let pipe2Texture = SKTexture(imageNamed: "pipe2.png")
        let pipe2 = SKSpriteNode(texture: pipe2Texture)
        pipe2.position = CGPoint(
            x: self.frame.midX + self.frame.width,
            y: self.frame.midY - pipe2Texture.size().height / 2 - gapHeight / 2  + pipeOffset
        )
        pipe2.run(moveAndRemovePipes)

        pipe2.physicsBody = SKPhysicsBody(rectangleOf: pipe2Texture.size())
        pipe2.physicsBody!.isDynamic = false

        pipe2.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        pipe2.physicsBody!.categoryBitMask = ColliderType.Object.rawValue
        pipe2.physicsBody!.collisionBitMask = ColliderType.Object.rawValue
        setPipePosition(pipe2)

        self.addChild(pipe2)
    }

    // Set the pipe second position after background
    func setPipePosition(_ pipe: SKSpriteNode) -> Void {
        pipe.zPosition = -1
    }

    func makeGap(_ moveAndRemovePipes: SKAction, _ gapHeight: CGFloat , _ pipeOffset: CGFloat) -> Void {
        let pipeTexture = SKTexture(imageNamed: "pipe1.png")

        let gap = SKNode()
        gap.position = CGPoint(x: self.frame.midX + self.frame.width , y: self.frame.midY + pipeOffset)
        gap.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipeTexture.size().width, height: gapHeight))

        gap.physicsBody!.isDynamic = false
        gap.run(moveAndRemovePipes)

        gap.physicsBody!.contactTestBitMask = ColliderType.Bird.rawValue
        gap.physicsBody!.categoryBitMask = ColliderType.Gap.rawValue
        gap.physicsBody!.collisionBitMask = ColliderType.Gap.rawValue

        self.addChild(gap)
    }

    func makeGround() -> Void {
        let ground = SKNode()
        ground.position = CGPoint(x: self.frame.midX, y: -self.frame.height / 2)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.width, height: 1))

        ground.physicsBody!.isDynamic = false

        ground.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        ground.physicsBody!.categoryBitMask = ColliderType.Object.rawValue
        ground.physicsBody!.collisionBitMask = ColliderType.Object.rawValue

        self.addChild(ground)
    }

    func setScoreStyle() -> Void {
        scoreLabel.fontName = "Helvetica"
        scoreLabel.fontSize = 80
        scoreLabel.text = "0"
    }

    func setMessageScoreStyle() -> Void {
        gameOverLabel.fontName = "Helvetica"
        gameOverLabel.fontSize = 50
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
        if gameOver == false {
            bird.physicsBody!.isDynamic = true
            bird.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
            bird.physicsBody!.applyImpulse(CGVector(dx: 0, dy: 300))
        } else {
            startGame()
            removeAllChildren()
            initializeGame()
        }
    }

    func startGame() -> Void {
        gameOver = false
        score = 0
        self.speed = 1
        playSound(sound: "Backgroundmusic", type: "mp3")
    }

    func resetGame() -> Void {
        self.speed = 0
        gameOver = true
        timer.invalidate()
        haptics.notificationOccurred(.success)
        playSound(sound: "Allahu Akbar", type: "mp3")
        
    }
}
