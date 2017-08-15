//
//  ViewController.swift
//  WWDC17VCTransition
//
//  Created by Harry Cao on 4/8/17.
//  Copyright © 2017 Harry Cao. All rights reserved.
//

import UIKit

let animationDuration = 1.0

class ViewController: UIViewController {
  enum State: Int {
    case Expanded = -1
    case Collapsed = 1
  }
  
  lazy var blurEffectView: UIVisualEffectView = {
    let view = UIVisualEffectView(frame: self.view.frame)
    view.backgroundColor = .clear
    return view
  }()
  
  lazy var control: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.masksToBounds = true
    view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
    return view
  }()
  
  let smallLabel: UILabel = {
    let label = UILabel()
    label.text = "Comments"
    label.font = UIFont(name: "Helvetica-Bold", size: 20)
    label.textColor = UIColor(red: 66/265, green: 134/265, blue: 244/265, alpha: 1)
    label.textAlignment = .center
    label.alpha = 1
    return label
  }()
  
  let largeLabel: UILabel = {
    let label = UILabel()
    label.text = "Comments"
    label.font = UIFont(name: "Helvetica-Bold", size: 35)
    label.textColor = UIColor(red: 78/265, green: 119/265, blue: 140/265, alpha: 1)
    label.textAlignment = .center
    label.alpha = 0
    return label
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let bgImageView = UIImageView(frame: self.view.frame)
    bgImageView.image = #imageLiteral(resourceName: "west")
    bgImageView.contentMode = .scaleAspectFill
    self.view.addSubview(bgImageView)
    
    self.view.addSubview(blurEffectView)
    
    setupControl()
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  func setupControl() {
    self.view.addSubview(control)
    control.frame = CGRect(x: 0, y: self.view.frame.height - 90, width: self.view.frame.width, height: self.view.frame.height)
    
    let bgImageView = UIImageView(frame: control.bounds)
    bgImageView.image = #imageLiteral(resourceName: "comment")
    bgImageView.contentMode = .scaleAspectFill
    control.addSubview(bgImageView)
    
    control.addSubview(smallLabel)
    smallLabel.frame = CGRect(x: 0, y: 30, width: control.frame.width, height: 30)
    control.addSubview(largeLabel)
    largeLabel.frame = CGRect(x: 0, y: 60, width: control.frame.width, height: 52.5)
  }
  
  // Tracks all running animators
  var runningAnimators = [UIViewPropertyAnimator]()
  
  var progressWhenInterrupted: CGFloat = 0
  
  var state: State = .Expanded
}


extension ViewController {
  @objc func handleTap(_ gesture: UITapGestureRecognizer) {
    animateOrReverseRunningTransition(state: state, duration: animationDuration)
  }
  
  
  @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
    switch gesture.state {
    case .began:
      startInteractiveTransition(state: state, duration: animationDuration)
    case .changed:
      let translation = gesture.translation(in: control)
      let fractionComplete = max(0.001, min(0.999, CGFloat(state.rawValue)*translation.y/500 + progressWhenInterrupted))
      
      updateInteractiveTransition(fractionComplete: fractionComplete)
    case .ended:
      let cancel = isCancelingAnimation(state: state, panGesture: gesture)
      continueInteractiveTransition(cancel: cancel)
    default:
      return
    }
  }
  
  
  
  
  
  // Perform all animations with animators if not already running
  func animateTransitionIfNeeded(state: State, duration: TimeInterval) {
    if runningAnimators.isEmpty {
      
      // FRAME ANIMATOR
      let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
        switch state {
        case .Expanded:
          self.control.frame = CGRect(x: 0, y: 47, width: self.view.frame.width, height: self.view.frame.height)
        case .Collapsed:
          self.control.frame = CGRect(x: 0, y: self.view.frame.height - 90, width: self.view.frame.width, height: self.view.frame.height)
        } }
      frameAnimator.addCompletion({ position in
        if let index = self.runningAnimators.index(of: frameAnimator) {
          self.runningAnimators.remove(at: index)
        }
        self.state = position == .start ? state : state == .Expanded ? .Collapsed : .Expanded
      })
      
      frameAnimator.startAnimation()
      runningAnimators.append(frameAnimator)
      
      
      // BLUR ANIMATOR
      let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
        switch state {
        case .Expanded:
          self.blurEffectView.effect = UIBlurEffect(style: .dark)
        case .Collapsed:
          self.blurEffectView.effect = nil
        }
      }
      
      blurAnimator.addCompletion({ position in
        if let index = self.runningAnimators.index(of: blurAnimator) {
          self.runningAnimators.remove(at: index)
        }
        self.blurEffectView.effect = state == .Expanded && position == .end || state == .Collapsed && position == .start ? UIBlurEffect(style: .dark) : nil
      })
      blurAnimator.startAnimation()
      runningAnimators.append(blurAnimator)
    }
    
    
    // LABEL ANIMATOR
      // Determine what inGoing and outGoing labels are
    let inLabel = state == .Expanded ? largeLabel : smallLabel
    let outLabel = state == .Expanded ? smallLabel : largeLabel
    
      //Scale
    let scale = inLabel.font.pointSize/outLabel.font.pointSize
    let inLabelScale = CGAffineTransform(scaleX: scale, y: scale)
    
      // Apply scale to calculate the translation
    inLabel.transform = CGAffineTransform(scaleX: 1/scale, y: 1/scale)
    
      // Translation
    let translateY = inLabel.frame.origin.y - outLabel.frame.origin.y
    let inLabelTranslation = CGAffineTransform(translationX: 0, y: translateY)
    
      // Apply transform to inGoing label so it match the initial state of outGoing label
    inLabel.transform = CGAffineTransform(scaleX: 1/scale, y: 1/scale).concatenating(CGAffineTransform(translationX: 0, y: -translateY))
    
      // Animate tranform
    let transformAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
      inLabel.transform = CGAffineTransform.identity
      outLabel.transform = inLabelScale.concatenating(inLabelTranslation)
    }
    transformAnimator.addCompletion({ position in
      if let index = self.runningAnimators.index(of: transformAnimator) {
        self.runningAnimators.remove(at: index)
      }
    })
    transformAnimator.startAnimation()
    runningAnimators.append(transformAnimator)
    
      // Animate in inGoing label
    let inLabelAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeIn) {
      inLabel.alpha = 1
    }
    inLabelAnimator.scrubsLinearly = false
    inLabelAnimator.addCompletion({ _ in
      if let index = self.runningAnimators.index(of: inLabelAnimator) {
        self.runningAnimators.remove(at: index)
      }
    })
    inLabelAnimator.startAnimation()
    runningAnimators.append(inLabelAnimator)
    
      // Animate out outGoing label
    let outLabelAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeOut) {
      outLabel.alpha = 0
    }
    outLabelAnimator.scrubsLinearly = false
    outLabelAnimator.addCompletion({ _ in
      if let index = self.runningAnimators.index(of: outLabelAnimator) {
        self.runningAnimators.remove(at: index)
      }
    })
    outLabelAnimator.startAnimation()
    runningAnimators.append(outLabelAnimator)
    
    
    // ANIMATE CORNER RADIUS
    let cornerAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
      switch state {
      case .Expanded:
        self.control.layer.cornerRadius = 20
      case .Collapsed:
        self.control.layer.cornerRadius = 0
      }
    }
    cornerAnimator.addCompletion { _ in
      if let index = self.runningAnimators.index(of: cornerAnimator) {
        self.runningAnimators.remove(at: index)
      }
    }
    cornerAnimator.startAnimation()
    runningAnimators.append(cornerAnimator)
    
  }
  
  
  
  // Starts transition if necessary or reverses it on tap
  func animateOrReverseRunningTransition(state: State, duration: TimeInterval) {
    if runningAnimators.isEmpty {
      animateTransitionIfNeeded(state: state, duration: duration)
    } else {
      for animator in runningAnimators {
        animator.isReversed = !animator.isReversed
      }
    }
  }
  
  
  
  // Starts transition if necessary and pauses on pan .begin
  func startInteractiveTransition(state: State, duration: TimeInterval) {
    if runningAnimators.isEmpty {
      animateTransitionIfNeeded(state: state, duration: duration)
    }
    
    for animator in runningAnimators {
      animator.pauseAnimation()
    }
    
    progressWhenInterrupted = runningAnimators[0].fractionComplete
  }
  
  
  
  // Scrubs transition on pan .changed
  func updateInteractiveTransition(fractionComplete: CGFloat) {
    for animator in runningAnimators {
      animator.fractionComplete = fractionComplete
    }
  }
  
  
  
  // Continues or reverse transition on pan .ended
  func continueInteractiveTransition(cancel: Bool) {
    for animator in runningAnimators {
      if cancel { animator.isReversed = true }
      animator.continueAnimation(withTimingParameters: nil, durationFactor: 0.0)
    }
  }
  
  
  
  
  
  
  
  
  private func isCancelingAnimation(state: State, panGesture: UIPanGestureRecognizer) -> Bool {
    let completionThreshold: CGFloat = 0.33
    let flickMagnitude: CGFloat = 1200 //pts/sec
    let velocity = panGesture.velocity(in: control).vector
    let isFlick = (velocity.magnitude > flickMagnitude)
    let isFlickDown = isFlick && (velocity.dy > 0.0)
    let isFlickUp = isFlick && (velocity.dy < 0.0)
    
    if (state == .Expanded && isFlickUp) || (state == .Collapsed && isFlickDown) {
      return false
    } else if (state == .Expanded && isFlickDown) || (state == .Collapsed && isFlickUp) {
      return true
    } else if runningAnimators[0].fractionComplete > completionThreshold {
      return false
    } else {
      return true
    }
  }
}




extension CGPoint {
  var vector: CGVector {
    return CGVector(dx: x, dy: y)
  }
}

extension CGVector {
  var magnitude: CGFloat {
    return sqrt(dx*dx + dy*dy)
  }
}
