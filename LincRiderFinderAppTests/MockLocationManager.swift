//
//  MockLocationManager.swift
//  LincRiderFinderAppTests
//
//  Created by Olanrewaju Olakunle  on 08/03/2025.
//

import Foundation
import CoreLocation

class MockLocationManager: CLLocationManager {
    var delegateMock: CLLocationManagerDelegate?

    override var delegate: CLLocationManagerDelegate? {
        get { return delegateMock }
        set { delegateMock = newValue }
    }

    func triggerLocationUpdate(location: CLLocation) {
        delegateMock?.locationManager?(self, didUpdateLocations: [location])
    }
}
