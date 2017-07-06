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
    
    func docCameraDidClose(_ camera: UIViewController)
    func docCamera(_ camera: UIViewController, didTake photo: UIImage)
    
    func docCamera(_ camera: UIViewController, setupError error: Error)
    func docCamera(_ camera: UIViewController, captureError error: Error)
}
