//
//  DocumentCameraError.swift
//  Pods
//
//  Created by Eugen Fedchenko on 7/7/17.
//
//

import Foundation

public enum DocumentCameraError: Error {
    case configurationError(reason: String)
    case captureError(reason: String)
}
