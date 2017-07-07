//
//  DocumentCameraDelegate.swift
//  Pods
//
//  Created by Eugen Fedchenko on 7/6/17.
//
//

import Foundation

public protocol DocumentCameraDelegate: class {
    
    func docCamera(_ camera: UIViewController, checkAccess completion: @escaping (Bool) -> Void)
    
    func docCamera(_ camera: UIViewController, didTake photo: UIImage)
    func docCameraDidClose(_ camera: UIViewController)
    
    func docCameraConfigurationError(_ camera: UIViewController)
    func docCameraAccessDenied(_ camera: UIViewController)
    
    func docCamera(_ camera: UIViewController, logError error: Error)
    
    func docCameraRetakeButtonTitle(_ camera: UIViewController) -> String
    func docCameraUseButtonTitle(_ camera: UIViewController) -> String
}

// MARK: Default implementation
public extension DocumentCameraDelegate {
    
    func docCameraConfigurationError(_ camera: UIViewController) {}
    
    func docCameraAccessDenied(_ camera: UIViewController) {}
    
    func docCamera(_ camera: UIViewController, logError error: Error) {
        print("Document camera setup error: \(error)")
    }
    
    func docCameraRetakeButtonTitle(_ camera: UIViewController) -> String {
        return "Retake"
    }
    
    func docCameraUseButtonTitle(_ camera: UIViewController) -> String {
        return "Use"
    }
}
