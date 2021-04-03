//
//  ContentView.swift
//  GPSExample
//
//  Created by mimi on 4/1/21.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct ContentView: View {
    @ObservedObject private var locationManager = LocationManager()
    @State private var directions: [String] = []
    @State private var showDirections: Bool = false
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 65, longitude: 38), span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.15))
    @State var latitude: CLLocationDegrees = 0
    @State var longitude: CLLocationDegrees = 0
    @State var presentView: Bool = false
    var body: some View {
        ZStack {
        if presentView == true {
            VStack {

                MapView(region: $region, directions: $directions, latitude: locationManager.latitude!, longitude: locationManager.longtitude!)
                Button(action: {
                    showDirections.toggle()
                }) {
                    Text("Show Directions")
                }.padding()
                .disabled(directions.isEmpty ? true : false)
                
            }.sheet(isPresented: $showDirections, content: {
                NavigationView {
                    VStack {
                        List {
                            ForEach(0..<directions.count, id: \.self) { step in
                                Text("\(directions[step])")
                            }
                        }.padding()
                    }.navigationBarTitle("Directions")
                }
            })
        }
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                presentView.toggle()
//                locationManager.$location.sink { location in
//                    region = MKCoordinateRegion(center: location?.coordinate ?? CLLocationCoordinate2D(), latitudinalMeters: 500, longitudinalMeters: 500)
//                    region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: locationManager.latitude!, longitude: locationManager.longtitude!), latitudinalMeters: 500, longitudinalMeters: 500)
//                }
                print("success")
            }
            
        }.edgesIgnoringSafeArea(.top)
    }
}

struct MapView: UIViewRepresentable {
    typealias UIViewType = MKMapView
    @ObservedObject var locationManager = LocationManager()
    @Binding var region: MKCoordinateRegion
    @Binding var directions: [String]
    @State var latitude = LocationManager().latitude
    @State var longitude = LocationManager().longtitude

    func makeCoordinator() -> MapViewCoordinator {
        return MapViewCoordinator()
    }
    
    func makeUIView(context: Context) -> MKMapView {
        
            let mapView = MKMapView()
            mapView.delegate = context.coordinator
            //        var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.71, longitude: -82), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
            
            mapView.setRegion(region, animated: true)
            if latitude != nil || longitude != nil {
            let p3 = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!))
            let p1 = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 40.71, longitude: -82))
                _ = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 42.46, longitude: -71.05))
            
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: p1)
            request.destination = MKMapItem(placemark: p3)
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { (response, err) in
                //          checking to make sure something is there and would assign it to "route" response is not nil.
                guard let route = response?.routes.first else { return }
                mapView.addAnnotations([p1, p3])
                
                //          a route that would be drawn between these 2 places
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
                
                self.directions = route.steps.map { $0.instructions }//.filter { !$0.isEmpty }
            }
        }
        
            return mapView
        
    }
    
    
    func updateUIView(_ uiView: MKMapView, context: Context) { }
        
    class MapViewCoordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(#colorLiteral(red: 0, green: 0.6509803922, blue: 1, alpha: 1))
            renderer.lineWidth = 5
            return renderer
        }
    }
}

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var longtitude: Double?
    @Published var latitude: Double?
    
    override init() {
        super.init()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last
            else { return }
    
        DispatchQueue.main.async {
            self.location = location
            self.longtitude = location.coordinate.longitude
            self.latitude = location.coordinate.latitude
            print("Longitude \(self.longtitude), latitude \(self.latitude)")
        }
    }
}
