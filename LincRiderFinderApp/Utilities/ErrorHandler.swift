//
//  ErrorHandler.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import Foundation

enum LocationError: Error {
    case permissionDenied
    case locationNotFound
    case unknownError
}
