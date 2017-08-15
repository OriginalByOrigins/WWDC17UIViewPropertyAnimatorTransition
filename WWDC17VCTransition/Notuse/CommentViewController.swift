//
//  CommentViewController.swift
//  WWDC17VCTransition
//
//  Created by Harry Cao on 4/8/17.
//  Copyright © 2017 Harry Cao. All rights reserved.
//

import UIKit

class CommentViewController: UIViewController {
  lazy var bottomBar: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    let label = UILabel()
    label.text = "Comments"
    label.font = UIFont(name: "Helvetica-Bold", size: 20)
    label.textColor = UIColor(red: 78/265, green: 119/265, blue: 140/265, alpha: 1)
    label.textAlignment = .center
    view.addSubview(label)
    _ = label.constraintAnchorTo(top: view.topAnchor, topConstant: 30, bottom: nil, bottomConstant: nil, left: view.leftAnchor, leftConstant: 0, right: view.rightAnchor, rightConstant: 0)
    _ = label.constraintSizeToConstant(widthConstant: nil, heightConstant: 30)
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    return view
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let bgImageView = UIImageView(frame: self.view.frame)
    bgImageView.image = #imageLiteral(resourceName: "comment")
    bgImageView.contentMode = .scaleAspectFill
    self.view.addSubview(bgImageView)
    
    self.view.addSubview(bottomBar)
    _ = bottomBar.constraintSizeToConstant(widthConstant: nil, heightConstant: 90)
    _ = bottomBar.constraintAnchorTo(top: self.view.topAnchor, topConstant: 0, bottom: nil, bottomConstant: nil, left: self.view.leftAnchor, leftConstant: 0, right: self.view.rightAnchor, rightConstant: 0)
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  @objc func handleTap(_ gesture: UITapGestureRecognizer) {
    dismiss(animated: true) {
      // maydo smth
    }
  }
}
