//
//  Camera.swift
//  DocumentCamera
//
//  Created by Eugen Fedchenko on 7/4/17.
//  Copyright © 2017 gavrilaf. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraDelegate: class {
    func checkAccess(checkAccess completion: @escaping (Bool) -> Void)
    func didTakePhoto(_ photo: UIImage)
    func logError(_ error: DocumentCameraError)
    
    func accessDenied()
    func configurationFailed()
}

// MARK:
class Camera: UIView {
    
    enum CameraSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    var setupResult = CameraSetupResult.success
    var isSessionRunning = false
    
    // MARK:
    
    func setup(withPreview preview: PreviewView, delegate: CameraDelegate) {
        self.delegate = delegate
        
        sessionQueue.suspend()
        
        delegate.checkAccess { [weak self] (granted) in
            if granted {
                self?.sessionQueue.resume()
            } else {
                self?.setupResult = .notAuthorized
            }
        }
        
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.preview = preview
            self.preview?.session = self.session
        }
    }
    
    func start() {
        deviceOrientation = UIDevice.current.orientation
        
        sessionQueue.async { [unowned self] in
            
            switch self.setupResult {
            case .success:
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
                DispatchQueue.main.async {
                    self.preview?.videoPreviewLayer.connection?.videoOrientation = self.getPreviewLayerOrientation()
                }
                
            case .configurationFailed:
                self.delegate?.configurationFailed()
                
            case .notAuthorized:
                self.delegate?.accessDenied()
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
    
    fileprivate weak var delegate: CameraDelegate?
    fileprivate weak var preview: PreviewView?
    
    fileprivate let session = AVCaptureSession()
    
    fileprivate let sessionQueue = DispatchQueue(label: "DocCameraSessionQueue")
    
    fileprivate var videoDeviceInput: AVCaptureDeviceInput!
    fileprivate let photoOutput = AVCapturePhotoOutput()
    
    fileprivate var deviceOrientation: UIDeviceOrientation?
    
    // MARK:
    private func configureSession() {
        guard setupResult == .success else { return }
        
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
            
            guard let videoDevice = defaultVideoDevice else {
                delegate?.logError(.configurationError(reason: "Could not retrieve default device"))
                setupResult = .configurationFailed
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                // Set preview orientation here
            } else {
                delegate?.logError(.configurationError(reason: "Could not add video device input to the session"))
                setupResult = .configurationFailed
                return
            }
        } catch {
            delegate?.logError(.configurationError(reason: "Could not create video device input: \(error)"))
            setupResult = .configurationFailed
            return
        }
        
        // Add photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = false
        } else {
            delegate?.logError(.configurationError(reason: "Could not add photo output to the session"))
            setupResult = .configurationFailed
            return
        }
    }
    
    private func addObservers() {
        let nc = NotificationCenter.default
        
        nc.addObserver(self, selector: #selector(deviceDidRotate), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
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
    
    fileprivate func processPhoto(_ imageData: Data) {
        guard let dataProvider = CGDataProvider(data: imageData as CFData),
            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider,
                                     decode: nil, shouldInterpolate: true,
                                     intent: CGColorRenderingIntent.defaultIntent)
            else {
                delegate?.logError(.captureError(reason: "Processing image error"))
                return
        }
        
        let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: self.getImageOrientation())
        
        delegate?.didTakePhoto(image)
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

// MARK:

extension Camera {
    @objc fileprivate func deviceDidRotate() {
        if !UIDevice.current.orientation.isFlat {
            self.deviceOrientation = UIDevice.current.orientation
        }
    }
}

// MARK:

extension Camera: AVCapturePhotoCaptureDelegate {
    
    func capture(_ captureOutput: AVCapturePhotoOutput, willBeginCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        DispatchQueue.main.async { [unowned self] in
            self.preview?.captureAnimation()
        }
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {
        
        if let error = error {
            delegate?.logError(.captureError(reason: "Error capturing photo: \(error)"))
        } else {
            
            guard let sampleBuffer = photoSampleBuffer else {
                delegate?.logError(.captureError(reason: "photoSampleBuffer is nil"))
                return
            }
            
            guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer,
                                                                                   previewPhotoSampleBuffer: previewPhotoSampleBuffer)
                else {
                    delegate?.logError(.captureError(reason: "Processing image error"))
                    return
            }
            
            self.processPhoto(imageData)
        }
    }
}



