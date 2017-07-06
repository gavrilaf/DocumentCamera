//
//  ViewController.swift
//  DocumentCamera
//
//  Created by gavrilaf on 07/06/2017.
//  Copyright (c) 2017 gavrilaf. All rights reserved.
//

import UIKit
import AVFoundation
import DocumentCamera

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func actionOpenCamera(_ sender: Any) {
        let camera = DocumentCameraFactory.createCamera(withDelegate: self)
        present(camera, animated: true, completion: nil)
    }
}

extension ViewController: DocumentCameraDelegate {
    
    func docCamera(_ camera: UIViewController, checkAccess completion: @escaping (Bool) -> Void) {
        let authorizationStatus  = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        switch authorizationStatus {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: completion)
        default:
            completion(false)
        }
    }
    
    func docCameraDidClose(_ camera: UIViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func docCamera(_ camera: UIViewController, didTake photo: UIImage) {
        imageView.image = photo
        dismiss(animated: true, completion: nil)
    }
    
    func docCamera(_ camera: UIViewController, setupError error: Error) {
        print("Camera setup error: \(error)")
    }
    
    func docCamera(_ camera: UIViewController, captureError error: Error) {
        print("Camera capture error: \(error)")
    }
}

