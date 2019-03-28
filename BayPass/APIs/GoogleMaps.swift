//
//  GoogleMaps.swift
//  BayPass
//
//  Created by Tim Roesner on 2/17/19.
//  Copyright © 2019 Tim Roesner. All rights reserved.
//

import Alamofire
import Foundation
import MapKit

class GoogleMaps {
    func getRoutes(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, departureTime: Date = Date(), completion: @escaping ([Route]) -> Void) {
        let params = [
            "origin": "\(from.latitude),\(from.longitude)",
            "destination": "\(to.latitude),\(to.longitude)",
            "mode": "transit",
            "alternatives": "true",
            "departure_time": String(Int(departureTime.timeIntervalSince1970)),
            "key": Credentials().googleDirections,
        ]
        let radius = CLLocation.distance(from: from, to: to)
        var results = [Route]()
        Alamofire.request("https://maps.googleapis.com/maps/api/directions/json", method: .get, parameters: params).responseJSON { response in
            if let json = response.result.value as? [String: Any],
                let routesJson = json["routes"] as? [[String: Any]] {
                for routeJson in routesJson {
                    if let newRoute = self.parseRoute(from: routeJson) {
                        results.append(newRoute)
                    }
                }
                completion(results)
            }
        }
    }

    func parseRoute(from json: [String: Any]) -> Route? {
        guard let legs = json["legs"] as? [[String: Any]],
            let arrivalJson = legs[0]["arrival_time"] as? [String: Any],
            let departureJson = legs[0]["departure_time"] as? [String: Any],
            let arrivalInterval = arrivalJson["value"] as? Int,
            let departureInterval = departureJson["value"] as? Int
        else {
            return nil
        }

        let departureDate = Date(timeIntervalSince1970: Double(departureInterval))
        let arrivalDate = Date(timeIntervalSince1970: Double(arrivalInterval))

        var segments = [RouteSegment]()
        if let segmentsJson = legs[0]["steps"] as? [[String: Any]] {
            for segmentJson in segmentsJson {
                if let newSegment = parseSegment(from: segmentJson) {
                    segments.append(newSegment)
                }
            }
        }

        return Route(departureTime: departureDate, arrivalTime: arrivalDate, segments: segments)
    }

    func parseSegment(from json: [String: Any]) -> RouteSegment? {
        let group = DispatchGroup()
        guard let distanceJson = json["distance"] as? [String: Any],
            let distance = distanceJson["value"] as? Int,
            let polylineJson = json["polyline"] as? [String: Any],
            let encodedPolyline = polylineJson["points"] as? String
        else {
            return nil
        }

        var polyline = MKPolyline()
        if let coordinates = decodePolyline(encodedPolyline) {
            polyline = MKPolyline(coordinates: coordinates)
        }

        // Transit
        if let transitDetails = json["transit_details"] as? [String: Any] {
            var waypoints = [Station]()

            guard let arrivalJson = transitDetails["arrival_time"] as? [String: Any],
                let arrivalInterval = arrivalJson["value"] as? Int,
                let departureJson = transitDetails["departure_time"] as? [String: Any],
                let departureInterval = departureJson["value"] as? Int,
                let lineJson = transitDetails["line"] as? [String: Any],
                let arrivalStop = transitDetails["arrival_stop"] as? [String: Any],
                let locationForArrival = arrivalStop["location"] as? [String: Any],
                let latForArrival = locationForArrival["lat"] as? Double,
                let lngForArrival = locationForArrival["lng"] as? Double,
                let departureStop = transitDetails["departure_stop"] as? [String: Any],
                let locationForDeparture = departureStop["location"] as? [String: Any],
                let latForDeparture = locationForDeparture["lat"] as? Double,
                let lngForDeparture = locationForDeparture["lng"] as? Double
            else {
                return nil
            }

            let departureDate = Date(timeIntervalSince1970: Double(departureInterval))
            let arrivalDate = Date(timeIntervalSince1970: Double(arrivalInterval))

            // CLLocation for Arrival
            let latArrival: CLLocationDegrees = latForArrival
            let longArrival: CLLocationDegrees = lngForArrival
            let arrivalLocation = CLLocationCoordinate2D(latitude: latForArrival, longitude: longArrival)
            let arrivalLoc = CLLocation(latitude: latForArrival, longitude: longArrival)

            // CLLocation for Departure
            let latDeparture: CLLocationDegrees = latForDeparture
            let longDeparture: CLLocationDegrees = lngForDeparture
            let departureLocation = CLLocationCoordinate2D(latitude: latDeparture, longitude: longDeparture)
            let departureLoc = CLLocation(latitude: latForArrival, longitude: longArrival)

            let center = CLLocation.middlePointOfListMarkers(listCoords: [arrivalLocation, departureLocation])
            let radius = Int(CLLocation.distance(from: arrivalLocation, to: departureLocation)) // arrivalLoc.distance(from: departureLoc)
            print("center=\(center)")
            print(radius)

            group.enter()
            Here.shared.getStationsNearby(center: center, radius: Int(radius), max: 50, time: departureDate.description, completion: { resp in
                waypoints = resp
                print("waypoints=\(waypoints)")
                group.leave()
            })

            group.wait()
            let line = waypoints[0].lines[0]
            print(line)

            // TODO: This section relies on getting the fare prices from firebase and the line from the API first
            let price = 2.50

            return RouteSegment(distanceInMeters: distance, departureTime: departureDate, arrivalTime: arrivalDate, polyline: polyline, travelMode: .transit, line: line, price: price, waypoints: waypoints)
        } else {
            guard let durationJson = json["duration"] as? [String: Any],
                var duration = durationJson["value"] as? Int
            else {
                return nil
            }
            duration = Int(duration / 60)
            return RouteSegment(distanceInMeters: distance, durationInMinutes: duration, polyline: polyline, travelMode: .walking)
        }
    }

    func getHereStations(center: CLLocationCoordinate2D, radius: Int, max _: Int, time: String, completion: @escaping ([Station]) -> Void) {
//        let group = DispatchGroup()
        var stations = [Station]()
//        group.enter()
        Here.shared.getStationsNearby(center: center, radius: Int(radius), max: 50, time: time, completion: { resp in
            stations = resp
//            group.leave()
        })
//        group.notify(queue: .main) {
        completion(stations)
//        }
    }
}
