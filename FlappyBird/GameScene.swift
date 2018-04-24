//
//  GameScene.swift
//  FlappyBird
//
//  Created by USER on 2018/04/17.
//  Copyright © 2018年 shuuhei-sutou. All rights reserved.
//

import UIKit
import SpriteKit
import AudioToolbox

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var coinNode:SKNode!
    
    var soundIdRing:SystemSoundID = 0
    
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemScoreCategory: UInt32 = 1 << 4
    
    var score = 0
    var item_score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemScoreScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        coinNode = SKNode()
        scrollNode.addChild(coinNode)
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupCoin()
        
        setupScoreLabel()
    }
    
    func setupCoin(){
        let coinTexture = SKTexture(imageNamed: "coin")
        coinTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + coinTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveCoin = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        
        // 自身を取り除くアクションを作成
        let removeCoin = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let coinAnimation = SKAction.sequence([moveCoin, removeCoin])
        
        // 壁を生成するアクションを作成
        let createCoinAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let coin = SKNode()
            coin.position = CGPoint(x: self.frame.size.width + coinTexture.size().width / 2, y: 0.0)
            coin.zPosition = -50.0 // 雲より手前、地面より奥
            
            let coins = SKSpriteNode(texture: coinTexture)
            let under_x = arc4random_uniform(100)
            let under_y = arc4random_uniform(500)
            
            coins.position = CGPoint(x: CGFloat(under_x), y: CGFloat(under_y))
            coin.addChild(coins)
            
            coins.physicsBody = SKPhysicsBody(circleOfRadius: coins.size.height / 2.0)
            coins.physicsBody?.categoryBitMask = self.itemScoreCategory
            coins.physicsBody?.isDynamic = false
            
            coin.run(coinAnimation)
            
            self.coinNode.addChild(coin)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createCoinAnimation, waitAnimation]))
        
        coinNode.run(repeatForeverAnimation)
    }
    
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        item_score = 0
        itemScoreScoreLabelNode = SKLabelNode()
        itemScoreScoreLabelNode.fontColor = UIColor.black
        itemScoreScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreScoreLabelNode.zPosition = 100 // 一番手前に表示する
        itemScoreScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreScoreLabelNode.text = "ItemScore:\(item_score)"
        self.addChild(itemScoreScoreLabelNode)
    }
    
    func setupGround(){
        
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        for i in 0..<needNumber{
            let sprite = SKSpriteNode(texture: groundTexture)
            
            sprite.position = CGPoint(x: groundTexture.size().width * (CGFloat(i) + 0.5), y: groundTexture.size().height * 0.5)
            
            sprite.run(repeatScrollGround)
            
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            sprite.physicsBody?.isDynamic = false
            
            scrollNode.addChild(sprite)
        }
        
    }
    
    func setupCloud(){
        
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        for i in 0..<needCloudNumber{
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100
            
            sprite.position = CGPoint(x: cloudTexture.size().width * (CGFloat(i) + 0.5), y: self.size.height - cloudTexture.size().height * 0.5)
            
            sprite.run(repeatScrollCloud)
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall(){
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        
        let removeWall = SKAction.removeFromParent()
        
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        let createWallAnimation = SKAction.run({
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y:0.0)
            wall.zPosition = -50.0
            
            let center_y = self.frame.size.height / 2
            
            let random_y_range = self.frame.size.height / 4
            
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 - random_y_range / 2)
            
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            let slit_length = self.frame.size.height / 6
            
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x:0.0, y:under_wall_y)
            wall.addChild(under)
            
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            under.physicsBody?.isDynamic = false
            
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y:self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird(){
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texuresAnimation)
        
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x:self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | itemScoreCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | itemScoreCategory
        
        bird.run(flap)
        
        addChild(bird)
    }
    
    func restart(){
        score = 0
        item_score = 0
        scoreLabelNode.text = String("Score:\(score)")
        itemScoreScoreLabelNode.text = "ItemScore:\(item_score)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | itemScoreCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            bird.physicsBody?.velocity = CGVector.zero
            
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        }else if bird.speed == 0{
            restart()
        }
    }
    
    func playSound() {
        let url = Bundle.main.url(forResource: "itemgetsea", withExtension: "mp3")!
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        var firstBody, secondBody: SKPhysicsBody
        
        // firstを赤、secondを緑とする。
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if scrollNode.speed <= 0{
            return
        }
        
        if(firstBody.categoryBitMask & scoreCategory) == scoreCategory || (secondBody.categoryBitMask & scoreCategory) == scoreCategory {
            
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        }else if (firstBody.categoryBitMask == birdCategory)  &&
            (secondBody.categoryBitMask == itemScoreCategory)  {
            secondBody.node?.removeFromParent()
            print("CoinUp")
            item_score += 1
            itemScoreScoreLabelNode.text = "ItemScore:\(item_score)"
            playSound()
        }
        else{
            print("GameOver")
            
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
}
