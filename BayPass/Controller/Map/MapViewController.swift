//
//  ViewController.swift
//  BayPass
//
//  Created by Tim Roesner on 9/14/18.
//  Copyright © 2018 Tim Roesner. All rights reserved.
//

import CoreLocation
import SnapKit
import MapKit
import OverlayContainer
import UIKit

class MapViewController: UIViewController {
    
    private(set) var mapView = MKMapView()
    let bottomSheet = OverlayContainerViewController(style: .rigid)
    let searchVC = SearchViewController()
    let locationManager = CLLocationManager()
    var notchPercentages = [CGFloat]()
    
    // Route Search properties
    var startIndex = 0
    var routes = [Route]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupLocation()
        //setupRoutesView(with: [Route(departureTime: Date(), arrivalTime: Date(timeIntervalSinceNow: 3000), segments: []), Route(departureTime: Date(), arrivalTime: Date(timeIntervalSinceNow: 6000), segments: [])])
    }
    
    func setupViews() {
        mapView.showsUserLocation = true
        mapView.delegate = self
        centerOnUserLocation()
        view.addSubview(mapView)
        mapView.snp.makeConstraints { (make) in
            make.top.bottom.right.left.equalToSuperview()
        }
        
        let blurredStatusBar = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(blurredStatusBar)
        blurredStatusBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        
        bottomSheet.delegate = self
        searchVC.delegate = self
        searchVC.parentMapVC = self
        setupSearchView()
        addChild(bottomSheet, in: view)
    }
}
