//
//  DocumentCameraFactory.swift
//  Pods
//
//  Created by Eugen Fedchenko on 7/6/17.
//
//

import UIKit

public struct DocumentCameraFactory {
    
    public static func createCamera(withDelegate delegate: DocumentCameraDelegate) -> UIViewController {
        let storyboard = UIStoryboard(name: "DocumentCamera", bundle: Bundle(for: CameraViewController.self))
        let controller = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        controller.delegate = delegate
        return controller
    }

}
