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
        
        if let delegate = delegate {
            useButton.titleLabel?.text = delegate.docCameraUseButtonTitle(self)
            retakeButton.titleLabel?.text = delegate.docCameraRetakeButtonTitle(self)
        }
        
        camera.setup(withPreview: cameraPreviewView, delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camera.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        camera.stop()
    }
    
    override func viewDidLayoutSubviews() {
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
    
    // MARK:
    
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
    
    
    // MARK:
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        cameraPreviewView.frame = self.view.bounds
    }
    
    // MARK:
    
    @IBOutlet weak var cameraTopView: UIView!
    @IBOutlet weak var previewTopView: UIView!
    
    @IBOutlet weak var cameraPreviewView: PreviewView!
    @IBOutlet weak var shutterButton: ShutterButton!
    @IBOutlet weak var torchButton: UIButton!
    
    @IBOutlet weak var imagePreviewImageView: UIImageView!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var useButton: UIButton!
    
    // MARK:
    private var camera = Camera()
}

extension CameraViewController: CameraDelegate {
    
    func checkAccess(checkAccess completion: @escaping (Bool) -> Void) {
        if let delegate = delegate {
            delegate.docCamera(self, checkAccess: completion)
        } else {
            completion(false)
        }
    }
    
    func didTakePhoto(_ photo: UIImage) {
        cameraTopView.isHidden = true
        previewTopView.isHidden = false
        imagePreviewImageView.image = photo
    }
    
    func sessionStateDidChange(running: Bool) {
        // disable shutter button
        print("sessionStateDidChange running(\(running))")
    }
    
    func logError(_ error: DocumentCameraError) {
        delegate?.docCamera(self, logError: error)
    }
    
    func accessDenied() {
        delegate?.docCameraAccessDenied(self)
    }
    
    func configurationFailed() {
        delegate?.docCameraConfigurationError(self)
    }

}

