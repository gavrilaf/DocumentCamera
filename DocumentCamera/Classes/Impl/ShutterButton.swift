//
//  ShutterButton.swift
//  DocumentCamera
//
//  Created by Eugen Fedchenko on 7/4/17.
//  Copyright © 2017 gavrilaf. All rights reserved.
//

import UIKit

class ShutterButton: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    var action: (() -> Void)?
    
    private func initSubviews() {
        self.backgroundColor = UIColor.clear
        self.isExclusiveTouch = true
        
        ringView = UIImageView(frame: self.bounds)
        if let ringView = ringView {
            ringView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            ringView.image = ShutterButton.ringImage(withFrame: self.frame)
            self.addSubview(ringView)
        }
        
        button = UIButton(frame: CGRect(x: 8, y: 8, width: self.frame.width - 16, height: self.frame.height - 16))
        if let button = button {
            button.backgroundColor = UIColor.white
            button.layer.cornerRadius = button.frame.width / 2
            button.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside])
            button.addTarget(self, action: #selector(buttonPressed), for: [.touchDown])
            self.addSubview(button)
        }
    }
    
    @objc private func buttonPressed() {
        button?.alpha = 0.7
    }
    
    @objc private func buttonReleased() {
        button?.alpha = 1.0
        action?()
    }
    
    private static func ringImage(withFrame rc: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(rc.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(6.0)
        context?.strokeEllipse(in: CGRect(x: 3, y: 3, width: rc.width - 6, height: rc.height - 6))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    var ringView: UIImageView?
    var button: UIButton?
}
