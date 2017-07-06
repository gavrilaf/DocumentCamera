//
//  Camera.swift
//  DocumentCamera
//
//  Created by Eugen Fedchenko on 7/4/17.
//  Copyright © 2017 gavrilaf. All rights reserved.
//

import UIKit
import AVFoundation


class Camera: UIView {
    
    var captureAction: ((UIImage) -> Void)?
    
    func setup(withPreview preview: PreviewView) {
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.preview = preview
            self.preview?.session = self.session
        }
    }
    
    
    func start() {
        deviceOrientation = UIDevice.current.orientation
        
        sessionQueue.async { [unowned self] in
            self.addObservers()
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            
            DispatchQueue.main.async {
                self.preview?.videoPreviewLayer.connection?.videoOrientation = self.getPreviewLayerOrientation()
            }
        }
    }
    
    func stop() {
        sessionQueue.async { [unowned self] in
            self.session.stopRunning()
            self.isSessionRunning = self.session.isRunning
            self.removeObservers()
        }
    }
    
    func takePicture() {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. We do this to ensure UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = preview?.videoPreviewLayer.connection?.videoOrientation ?? .portrait
        
        sessionQueue.async { [weak self] in
            guard let sself = self else { return }
            
            if let photoOutputConnection = sself.photoOutput.connection(withMediaType: AVMediaTypeVideo) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation
            }
            
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.availablePreviewPhotoPixelFormatTypes.first!]
            }
            
            sself.photoOutput.capturePhoto(with: photoSettings, delegate: sself)
        }
    }
    
    // MARK:
    
    var isSessionRunning = false
    var isSetupSuccess = true
    
    // MARK:
    
    fileprivate let session = AVCaptureSession()
    
    fileprivate weak var preview: PreviewView?
    
    fileprivate let sessionQueue = DispatchQueue(label: "DocCameraSessionQueue")
    fileprivate var videoDeviceInput: AVCaptureDeviceInput!
    fileprivate let photoOutput = AVCapturePhotoOutput()
    
    fileprivate var deviceOrientation: UIDeviceOrientation?
    
    // MARK:
    private func configureSession() {
        guard isSetupSuccess else { return }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if #available(iOS 10.2, *) {
                if let dualCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInDualCamera,
                                                                        mediaType: AVMediaTypeVideo,
                                                                        position: .back) {
                    defaultVideoDevice = dualCameraDevice
                } else if let backCameraDevice =  AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera,
                                                                                mediaType: AVMediaTypeVideo,
                                                                                position: .back)  {
                    defaultVideoDevice = backCameraDevice
                }
            } else {
                defaultVideoDevice = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera,
                                                                   mediaType: AVMediaTypeVideo,
                                                                   position: .back)
            }
            
            guard let videoDevice = defaultVideoDevice  else {
                isSetupSuccess = false
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                // Set preview orientation here
            } else {
                print("Could not add video device input to the session")
                return
            }
        } catch {
            print("Could not create video device input: \(error)")
            isSetupSuccess = false
            return
        }
        
        // Add photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = false
        } else {
            print("Could not add photo output to the session")
            isSetupSuccess = false
            return
        }
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDidRotate), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    private func removeObservers() {
        
    }
    
    fileprivate func getPreviewLayerOrientation() -> AVCaptureVideoOrientation {
        switch UIApplication.shared.statusBarOrientation {
        case .portrait, .unknown:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        }
    }
    
    fileprivate func processPhoto(_ imageData: Data) -> UIImage {
        let dataProvider = CGDataProvider(data: imageData as CFData)
        let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: self.getImageOrientation())
        
        return image
    }
    
    fileprivate func getImageOrientation() -> UIImageOrientation {
        guard let deviceOrientation = self.deviceOrientation else { return .right }
        
        switch deviceOrientation {
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        case .portraitUpsideDown:
            return .left
        default:
            return .right
        }
    }



}

extension Camera {
    @objc fileprivate func deviceDidRotate() {
        if !UIDevice.current.orientation.isFlat {
            self.deviceOrientation = UIDevice.current.orientation
        }
    }
}

extension Camera: AVCapturePhotoCaptureDelegate {
    
    func capture(_ captureOutput: AVCapturePhotoOutput, willBeginCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("Start capturing animation")
        DispatchQueue.main.async { [unowned self] in
            self.preview?.videoPreviewLayer.opacity = 0
            UIView.animate(withDuration: 0.25) { [unowned self] in
                self.preview?.videoPreviewLayer.opacity = 1
            }
        }

    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!,
                                                                             previewPhotoSampleBuffer: previewPhotoSampleBuffer)
            let image = self.processPhoto(imageData!)
            
            self.captureAction?(image)
            
            
        }
    }
}



