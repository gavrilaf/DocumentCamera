//
//  PreviewView.swift
//  DocumentCamera
//
//  Created by Eugen Fedchenko on 7/4/17.
//  Copyright © 2017 gavrilaf. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    
    static let gravity = AVLayerVideoGravityResizeAspectFill
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.black
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        let previewlayer = layer as! AVCaptureVideoPreviewLayer
        previewlayer.videoGravity = PreviewView.gravity
        return previewlayer
    }
    
    var session: AVCaptureSession? {
        get { return videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }
    
    override class var layerClass : AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
