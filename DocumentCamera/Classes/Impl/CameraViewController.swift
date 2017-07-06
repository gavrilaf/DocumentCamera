//
//  CameraViewController.swift
//  DocumentCamera
//
//  Created by Eugen Fedchenko on 7/4/17.
//  Copyright © 2017 gavrilaf. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    weak var delegate: DocumentCameraDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shutterButton.action = { [weak self] in
            self?.camera.takePicture()
        }
        
        camera.captureAction = { [weak self] (img) in
            guard let sself = self else { return }
            print("Photo taken, show preview")
            
            sself.cameraTopView.isHidden = true
            sself.previewTopView.isHidden = false
            
            sself.imagePreviewImageView.image = img
        }
        
        camera.setup(withPreview: cameraPreviewView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camera.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        camera.stop()
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection =  cameraPreviewView.videoPreviewLayer.connection, connection.isVideoOrientationSupported  {
            switch (UIDevice.current.orientation) {
            case .portrait:
                updatePreviewLayer(layer: connection, orientation: .portrait)
            case .landscapeRight:
                updatePreviewLayer(layer: connection, orientation: .landscapeLeft)
            case .landscapeLeft:
                updatePreviewLayer(layer: connection, orientation: .landscapeRight)
            case .portraitUpsideDown:
                updatePreviewLayer(layer: connection, orientation: .portraitUpsideDown)
            default:
                updatePreviewLayer(layer: connection, orientation: .portrait)
            }
        }
    }
    
    @IBAction func closeAction(_ sender: Any) {
        delegate?.docCameraDidClose(self)
    }
    
    
    @IBAction func torchAction(_ sender: Any) {
    }
    
    @IBAction func retakeAction(_ sender: Any) {
        cameraTopView.isHidden = false
        previewTopView.isHidden = true
    }
    
    
    @IBAction func usePhotoAction(_ sender: Any) {
        delegate?.docCamera(self, didTake: imagePreviewImageView.image!)
    }
    
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        cameraPreviewView.frame = self.view.bounds
    }


    var camera = Camera()
    
    @IBOutlet weak var cameraTopView: UIView!
    @IBOutlet weak var previewTopView: UIView!
    
    @IBOutlet weak var cameraPreviewView: PreviewView!
    @IBOutlet weak var shutterButton: ShutterButton!
    @IBOutlet weak var torchButton: UIButton!
    
    @IBOutlet weak var imagePreviewImageView: UIImageView!
}

