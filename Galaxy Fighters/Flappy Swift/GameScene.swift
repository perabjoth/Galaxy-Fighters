//
//  GameScene.swift
//  Flappy Swift
//
//  Created by Julio Montoya on 13/07/14.
//  Copyright (c) 2015 Julio Montoya. All rights reserved.
//
//  Copyright (c) 2015 AvionicsDev
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


import SpriteKit
import iAd
import AVFoundation
import Darwin
// Math Helpers
extension Float {
  static func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
    if (value > max) {
      return max
    } else if (value < min) {
      return min
    } else {
      return value
    }
  }
    
  static func range(min: CGFloat, max: CGFloat) -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
  }
}
public var backGroundMusic = AVAudioPlayer()
class GameScene: SKScene, SKPhysicsContactDelegate, ADInterstitialAdDelegate {
    var spaceship: SKSpriteNode!
    var lastTouch: CGPoint? = nil
    let screenSize: CGRect = UIScreen.mainScreen().bounds
    var enemy_x: CGFloat = 0.0
    var start: SKSpriteNode!
    var options: SKSpriteNode!
    var restart: SKSpriteNode!
    var soundON: SKSpriteNode!
    var soundOFF: SKSpriteNode!
    var close: SKSpriteNode!
    var resume: SKSpriteNode!
    // Background
    var background: SKNode!
    let background_speed = 100.0
    var hits = 0
    // Time Values
    var delta = NSTimeInterval(0)
    var last_update_time = NSTimeInterval(0)
    var pause: SKSpriteNode!
    var effectsPlayer = AVAudioPlayer()
    var bgMusicUrl:NSURL = NSBundle.mainBundle().URLForResource("Reformat", withExtension: "mp3")!
    var laser:NSURL = NSBundle.mainBundle().URLForResource("laser", withExtension: "wav")!
    var ow:NSURL = NSBundle.mainBundle().URLForResource("ow", withExtension: "wav")!
    // Physics Categories
    let FSBoundaryCategory: UInt32 = 1 << 0
    let FSPlayerCategory: UInt32   = 1 << 1
    let FSPipeCategory: UInt32     = 1 << 2
    let FSGapCategory: UInt32      = 1 << 3
    var heart1: SKSpriteNode!
    var heart2: SKSpriteNode!
    var heart3: SKSpriteNode!
    var volume = true
    var interstitialAd:ADInterstitialAd!
    var placeHolderView:UIView!
    var interstitialAdView: UIView = UIView()
    var num = 0.0
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
        interstitialAdView.removeFromSuperview()
    }
    
    func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
        
    }
    
    func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
        interstitialAdView = UIView()
        interstitialAdView.frame = self.view!.bounds
        self.view!.addSubview(interstitialAdView)
        
        interstitialAd.presentInView(interstitialAdView)
        UIViewController.prepareInterstitialAds()
    }
    
    func interstitialAdActionDidFinish(interstitialAd: ADInterstitialAd!) {
        interstitialAdView.removeFromSuperview()
    }
    
    func interstitialAdActionShouldBegin(interstitialAd: ADInterstitialAd!, willLeaveApplication willLeave: Bool) -> Bool {
        return true
    }
    
    
    func interstitialAdWillLoad(interstitialAd: ADInterstitialAd!) {
        
    }
    enum FSGameState: Int {
        case FSGameStateStarting
        case FSGameStatePlaying
        case FSGameStateEnded
        case FSGameStateSetting
        case FSGameStatePaused
    }
    func playSound(soundVariable : SKAction)
    {
        
        SKAction.repeatActionForever(SKAction(runAction(soundVariable)))
        
    }
    // 2
    var state:FSGameState = .FSGameStateStarting
    
    var score = 0
    var highscore = 0
    var label_score: SKLabelNode!
    var label_highscore: SKLabelNode!

  // MARK: - SKScene Initializacion
  override func didMoveToView(view: SKView) {
    
    if((NSUserDefaults.standardUserDefaults().objectForKey("highscore") != nil)){
        
        highscore = NSUserDefaults.standardUserDefaults().objectForKey("highscore") as Int
        
        
    }
    
    backGroundMusic = AVAudioPlayer(contentsOfURL:bgMusicUrl, error: nil)
    backGroundMusic.numberOfLoops = (-1)
    backGroundMusic.prepareToPlay()
    backGroundMusic.volume = 1.0
    effectsPlayer = AVAudioPlayer(contentsOfURL:laser, error: nil)
    initWorld()
    initBackground()
    initHUD()
  }
    
  // MARK: - Init Physics
  func initWorld() {
    physicsWorld.contactDelegate = self
    physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
    // 2
    physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
    // 3
    physicsBody?.categoryBitMask = FSBoundaryCategory
    physicsBody?.collisionBitMask = FSPlayerCategory
  }

    func loadInterstitialAd() {
        interstitialAd = ADInterstitialAd()
        interstitialAd.delegate = self
    }
    
    
  // MARK: - Init spaceship
  func initSpaceship() {
    // 1
    spaceship = SKSpriteNode(imageNamed: "Spaceship1")
    // 2
    spaceship.position = CGPoint(x: screenSize.width/2 , y: 0.0)
    // 3
    spaceship.physicsBody = SKPhysicsBody(circleOfRadius: spaceship.size.width / 2)
    spaceship.physicsBody?.categoryBitMask = FSPlayerCategory
    spaceship.physicsBody?.contactTestBitMask = FSPipeCategory | FSGapCategory | FSBoundaryCategory
    spaceship.physicsBody?.collisionBitMask = FSPipeCategory | FSBoundaryCategory
    spaceship.physicsBody?.allowsRotation = false
    spaceship.physicsBody?.restitution = 0.0
    spaceship.physicsBody?.mass = 0.225
    spaceship.zPosition = 50
    addChild(spaceship)
    runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.waitForDuration(0.5), SKAction.runBlock { self.runGame()}])), withKey: "generator")
    heart1 = SKSpriteNode(imageNamed: "heart")
    heart1.position = CGPoint(x: heart1.size.width/2 , y: screenSize.height - heart1.size.height/2)
    heart1.zPosition = 70
    addChild(heart1)
    heart2 = SKSpriteNode(imageNamed: "heart")
    heart2.position = CGPoint(x: heart1.position.x + heart2.size.width, y: screenSize.height - heart2.size.height/2)
    heart2.zPosition = 70
    addChild(heart2)
    heart3 = SKSpriteNode(imageNamed: "heart")
    heart3.position = CGPoint(x: heart2.position.x + heart3.size.width , y: screenSize.height - heart1.size.height/2)
    heart3.zPosition = 70
    addChild(heart3)
    
    
  }
    
  // MARK: - Background Functions
  func initBackground() {
    // 1
    background = SKNode()
    addChild(background)
    
    // 2
    for i in 0...2 {
        let tile = SKSpriteNode(imageNamed: "background")
        tile.anchorPoint = CGPointZero
        tile.position = CGPoint(x: 0.0 , y: CGFloat(i) * screenSize.height)
        tile.name = "background"
        tile.zPosition = 10
        background.addChild(tile)
    }

  }
   
    
    
  func moveBackground() {
    // 3
    let posY = -background_speed * delta
    background.position = CGPoint(x: 0.0 , y: background.position.y + CGFloat(posY))
    
    // 4
    background.enumerateChildNodesWithName("background") { (node, stop) in
        let background_screen_position = self.background.convertPoint(node.position, toNode: self)
        
        if background_screen_position.y <= -node.frame.size.height {
            node.position = CGPoint(x: node.position.x , y: node.position.y + (node.frame.size.height * 2))
        }
        
    }

  }
    func getEnemy() -> SKSpriteNode {
        let enemy =  SKSpriteNode(imageNamed: "enemy")
        var value = cos(CGFloat(num/M_PI))
            if value <= 0{
                value = 0 - value
            }
        enemy.position.x = CGFloat((screenSize.width - enemy.size.width)*value + enemy.size.width/2)
        num++
        //enemy.position.x = CGFloat(arc4random_uniform(UInt32(screenSize.width - enemy.size.width)))
        enemy.position.y = CGFloat(UInt32(screenSize.height)) - enemy.size.height/2
        enemy.physicsBody = SKPhysicsBody(rectangleOfSize: enemy.size)
        enemy.physicsBody?.categoryBitMask = FSPipeCategory;
        enemy.physicsBody?.contactTestBitMask = FSPlayerCategory;
        enemy.physicsBody?.collisionBitMask = FSPlayerCategory;
        enemy.physicsBody?.mass = 0.225
        enemy.physicsBody?.velocity.dy = CGFloat(-100.0)
        enemy.physicsBody?.allowsRotation = false
        
        
        
        enemy.zPosition = 30
        return enemy
    }
    func startMoving(velocityMultiplier: CGFloat) {
        
    }
    
    
    
    
    
    func getMissile() ->SKSpriteNode{
        let missile = SKSpriteNode(imageNamed: "missile")
        missile.position.x = spaceship.position.x
        missile.position.y = spaceship.position.y
        missile.physicsBody = SKPhysicsBody( rectangleOfSize: missile.size)
        missile.physicsBody?.categoryBitMask = FSGapCategory
        missile.physicsBody?.contactTestBitMask = FSPipeCategory
        missile.physicsBody?.collisionBitMask = FSPipeCategory
        missile.physicsBody?.mass = 1.0
        missile.physicsBody?.velocity.dy = CGFloat(200.0)
        missile.physicsBody?.allowsRotation = false
        missile.zPosition = 30
        return missile
    }
    
    func initMissile(){
        let missile = getMissile()
        addChild(missile)
    }
  // MARK: - Pipes Functions
  func initEnemy() {
    let enemy = getEnemy()
    addChild(enemy)
  }
    
  // MARK: - Game Over helpers
  func gameOver() {
    state = .FSGameStateEnded
    
        if(score > highscore){
            highscore = score
            NSUserDefaults.standardUserDefaults().setObject(score, forKey: "highscore")
            NSUserDefaults.standardUserDefaults().synchronize()

        }else{
            NSUserDefaults.standardUserDefaults().setObject(highscore, forKey: "highscore")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    
    // 2
    backGroundMusic.pause()
    hits  = 0
    spaceship.physicsBody?.categoryBitMask = 0
    spaceship.physicsBody?.collisionBitMask = FSBoundaryCategory
    removeActionForKey("generator")
    spaceship.removeAllChildren()
    spaceship.removeFromParent()
    removeAllChildren()
    initBackground()
    restart = SKSpriteNode(imageNamed: "Restart")
    restart.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
    restart.zPosition = 70
    initHighscore()
  
   
    addChild(restart)
    
    // 3
    label_score.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMaxY(frame) - 100)
    addChild(label_score)
  }
    
  func restartGame() {
    state = .FSGameStateStarting
    initWorld()
    initBackground()
    initHUD()
    score = 0
    label_score.text = "Score: 0"
    background.addChild(SKSpriteNode(imageNamed: "background"))
  }
    func initHUD() {
        
        // 1
        label_score = SKLabelNode(fontNamed:"Copperplate")
        label_score.fontSize = 20
        label_score.position.x = screenSize.width - 50
        label_score.position.y = screenSize.height - 20
        label_score.text = "Score: \(score)"
        label_score.zPosition = 50
        addChild(label_score)
        
        // 2
        start = SKSpriteNode(imageNamed: "Start")
        start.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame)  + start.size.height + 10)
        start.zPosition = 70
        addChild(start)
        
        options = SKSpriteNode(imageNamed: "Options")
        options.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame) )
        options.zPosition = 70
        addChild(options)
        
        soundON = SKSpriteNode(imageNamed: "soundON")
        soundON.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame) + soundON.size.height)
        soundON.zPosition = 70
        soundON.hidden = true
        soundON.removeFromParent()
        
        soundOFF = SKSpriteNode(imageNamed: "soundOFF")
        soundOFF.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame) - soundOFF.size.height)
        soundOFF.zPosition = 70
        soundOFF.hidden = true
        soundOFF.removeFromParent()
        
        close = SKSpriteNode(imageNamed: "close")
        close.position = CGPoint(x: close.size.width, y: size.height - close.size.height)
        close.zPosition = 70
        close.hidden = true
        close.removeFromParent()
        
        pause = SKSpriteNode(imageNamed: "pause")
        pause.position = CGPoint(x: screenSize.width - pause.size.width, y: label_score.position.y - pause.size.height)
        pause.zPosition = 70
        pause.hidden = true
        pause.removeFromParent()
        
        resume = SKSpriteNode(imageNamed: "resume")
        resume.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        resume.zPosition = 70
        resume.hidden = true
        resume.removeFromParent()
        
    }
    
    func initHighscore(){
        label_highscore = SKLabelNode(fontNamed:"Copperplate")
        label_highscore.fontSize = 20
        label_highscore.position.x = screenSize.width/2
        label_highscore.position.y = screenSize.height - 30
        label_highscore.text = "Highscore: \(highscore)"
        label_highscore.zPosition = 50
        addChild(label_highscore)
    }
    
    
    
    
    func resumeGame(){
        self.scene?.paused = false
    }
    func pauseGame(){
        self.scene?.paused = true
    }
  // MARK: - SKPhysicsContactDelegate
  func didBeginContact(contact: SKPhysicsContact) {
    let firstBody = contact.bodyA
    let secondBody = contact.bodyB
    let collision:UInt32 = (firstBody.categoryBitMask | secondBody.categoryBitMask)
    
    // 1
    if collision == (FSPipeCategory | FSGapCategory) {
        score++
        label_score.text = "Score: \(score)"
        
        firstBody.node?.removeFromParent()
        secondBody.node?.removeFromParent()
        effectsPlayer = AVAudioPlayer(contentsOfURL:laser, error: nil)
        effectsPlayer.prepareToPlay()
        if volume{
        effectsPlayer.play()
        }
    }
    
    // 2
    if collision == (FSPlayerCategory | FSPipeCategory) {
        hits = hits + 1
        effectsPlayer = AVAudioPlayer(contentsOfURL:ow, error: nil)
        effectsPlayer.prepareToPlay()
        if volume{
            effectsPlayer.play()
        }
        
        if hits <= 3{
            if hits == 1{
                heart3.removeFromParent()
                firstBody.node?.removeFromParent()
                secondBody.node?.removeFromParent()
                spaceship.position = CGPoint(x: screenSize.width/2 , y: 0.0)
                let delayTime = dispatch_time(DISPATCH_TIME_NOW,Int64(0.35 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime , dispatch_get_main_queue(), {self.addChild(self.spaceship)})

            }
            if hits == 2{
                heart2.removeFromParent()
                firstBody.node?.removeFromParent()
                secondBody.node?.removeFromParent()
                spaceship.position = CGPoint(x: screenSize.width/2 , y: 0.0)
                let delayTime = dispatch_time(DISPATCH_TIME_NOW,Int64(0.35 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime , dispatch_get_main_queue(), {self.addChild(self.spaceship)})
            }
            if hits == 3{
                heart3.removeFromParent()
                gameOver()
            }
        }
        
    }
    
    if collision == (FSPipeCategory | FSBoundaryCategory)
    {
        firstBody.node?.removeFromParent()
        secondBody.node?.removeFromParent()
    }
    
}
    
    // Be sure to clear lastTouch when touches end so that the impulses stop being applies
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        lastTouch = nil
    }
    
  // MARK: - Touch Events
  override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    let touch = touches.anyObject() as UITouch
    let touchLocation = touch.locationInNode(self)
    if state == .FSGameStateStarting && start.containsPoint(touchLocation){
        state = .FSGameStatePlaying
        backGroundMusic.play()
   
    lastTouch = touchLocation
        pause.hidden = false
        addChild(pause)
        start.hidden = true
        options.hidden = true
        initSpaceship()
    }
    
    if state == .FSGameStatePlaying && pause.containsPoint(touchLocation){
        state = .FSGameStatePaused
        backGroundMusic.pause()
        pauseGame()
        pause.removeFromParent()
        pause.hidden = true
        resume.hidden = false
        addChild(resume)
        if backGroundMusic.volume == 1.0{
            soundON.hidden = false
            addChild(soundON)
        }
        if backGroundMusic.volume == 0.0{
            soundOFF.hidden = false
            addChild(soundOFF)
        }
        
    }
    
    if state == .FSGameStatePaused && resume.containsPoint(touchLocation){
        resumeGame()
        backGroundMusic.play()
        resume.hidden = true
        soundOFF.hidden = true
        soundOFF.removeFromParent()
        soundON.hidden = true
        soundON.removeFromParent()
        resume.removeFromParent()
        pause.hidden = false
        addChild(pause)
        state = .FSGameStatePlaying
        
    }
    if state == .FSGameStateStarting && options.containsPoint(touchLocation){
        start.removeFromParent()
        options.removeFromParent()
        close.hidden = false
        addChild(close)
        state = .FSGameStateSetting
        if backGroundMusic.volume == 1.0{
            soundON.hidden = false
            addChild(soundON)
        }
        if backGroundMusic.volume == 0.0{
            soundOFF.hidden = false
            addChild(soundOFF)
        }
    }
    if state == .FSGameStateSetting && close.containsPoint(touchLocation){
        state = .FSGameStateStarting
        close.removeFromParent()
        close.hidden = true
        soundOFF.hidden = true
        soundOFF.removeFromParent()
        soundON.hidden = true
        soundON.removeFromParent()
        addChild(start)
        addChild(options)
    }
    if (state == .FSGameStateSetting || state == .FSGameStatePaused) && soundOFF.containsPoint(touchLocation){
        soundOFF.hidden = true
        soundOFF.removeFromParent()
        backGroundMusic.volume = 1.0
        effectsPlayer.volume = 1.0
        volume = true
        soundON.hidden = false
        addChild(soundON)
    }
    
    if (state == .FSGameStateSetting || state == .FSGameStatePaused) && soundON.containsPoint(touchLocation){
        soundON.hidden = true
        soundON.removeFromParent()
        backGroundMusic.volume = 0.0
        effectsPlayer.volume = 0.0
        volume = false
        soundOFF.hidden = false
        addChild(soundOFF)
    }
    
    if state == .FSGameStateEnded && restart.containsPoint(touchLocation)
    {
        label_highscore.text = ""
        label_score.removeFromParent()
        restart.removeFromParent()
        self.restartGame()
    }
  }
    func runGame(){
        initMissile()
        initEnemy()
    }
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let touchLocation = touch.locationInNode(self)
        lastTouch = touchLocation
    }
  // MARK: - Frames Per Second
  override func update(currentTime: CFTimeInterval) {
    // 6
    
    let max_speed = CGFloat(0.5)
    if state == .FSGameStatePlaying{
    if spaceship.physicsBody?.velocity.dx > max_speed{
        spaceship.physicsBody?.velocity.dx = max_speed
    }
    if spaceship.physicsBody?.velocity.dy > max_speed{
        spaceship.physicsBody?.velocity.dy = max_speed
    }
//    if spaceship.position.x == lastTouch?.x && spaceship.position.y == lastTouch?.y{
//        spaceship.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
//    }
    spaceship.physicsBody?.linearDamping = 1.0
    spaceship.physicsBody?.angularDamping = 1.0
    delta = (last_update_time == 0.0) ? 0.0 : currentTime - last_update_time
    last_update_time = currentTime
    if let touch = lastTouch {
        let impulseVector = CGVector(dx: touch.x - spaceship.position.x, dy: touch.y - spaceship.position.y)
        // If myShip starts moving too fast or too slow, you can multiply impulseVector by a constant or clamp its range
        spaceship.physicsBody?.applyImpulse(impulseVector)
    }else if !(spaceship.physicsBody?.resting != nil) {
        // Adjust the -0.5 constant accordingly
        let impulseVector = CGVector(dx: (spaceship.physicsBody?.velocity.dx)! * -0.5, dy: (spaceship.physicsBody?.velocity.dy)! * -0.5)
        spaceship.physicsBody?.applyImpulse(impulseVector)
    }
    // 7
    moveBackground()
  }else {
        //
    }
    }
}
