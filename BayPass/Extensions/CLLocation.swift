//
//  CLLocation.swift
//  BayPass
//
//  Created by Ayesha Khan on 3/27/19.
//  Copyright © 2019 Tim Roesner. All rights reserved.
//

import Foundation
import MapKit

extension CLLocation {
    /// Get distance between two points
    ///
    /// - Parameters:
    ///   - from: first point
    ///   - to: second point
    /// - Returns: the distance in meters
    class func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }

    // From Argus and grandagile
    // https://stackoverflow.com/a/30364000/10458607
    //        /** Degrees to Radian **/
    class func degreeToRadian(angle: CLLocationDegrees) -> CGFloat {
        return (CGFloat(angle) / 180.0 * CGFloat(M_PI))
    }

    //        /** Radians to Degrees **/
    class func radianToDegree(radian: CGFloat) -> CLLocationDegrees {
        return CLLocationDegrees(radian * CGFloat(180.0 / M_PI))
    }

    class func middlePointOfListMarkers(listCoords: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        var x = 0.0 as CGFloat
        var y = 0.0 as CGFloat
        var z = 0.0 as CGFloat

        for coordinate in listCoords {
            var lat: CGFloat = degreeToRadian(angle: coordinate.latitude)
            var lon: CGFloat = degreeToRadian(angle: coordinate.longitude)
            x = x + cos(lat) * cos(lon)
            y = y + cos(lat) * sin(lon)
            z = z + sin(lat)
        }

        x = x / CGFloat(listCoords.count)
        y = y / CGFloat(listCoords.count)
        z = z / CGFloat(listCoords.count)

        var resultLon: CGFloat = atan2(y, x)
        var resultHyp: CGFloat = sqrt(x * x + y * y)
        var resultLat: CGFloat = atan2(z, resultHyp)

        var newLat = radianToDegree(radian: resultLat)
        var newLon = radianToDegree(radian: resultLon)
        var result: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: newLat, longitude: newLon)

        return result
    }
}
