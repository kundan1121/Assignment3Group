//
//
//import SwiftUI
//import MapKit
//
//struct MapView: View {
//    /// Map Properties
//    /// Use .userLocation(followsHeading: true, fallback: .region(.myRegion)), To follow the User in the Map
//    @State private var cameraPosition: MapCameraPosition = .region(.myRegion)
//    @State private var mapSelection: MKMapItem?
//    @Namespace private var locationSpace
//    @State private var viewingRegion: MKCoordinateRegion?
//    
//    /// Search Properties
//    @State private var searchText: String = ""
//    @State private var showSearch: Bool = false
//    @State private var searchResults: [MKMapItem] = []
//    /// Map Selection Detail Properties
//    @State private var showDetails: Bool = false
//    @State private var lookAroundScene: MKLookAroundScene?
//    /// Route Properties
//    @State private var routeDisplaying: Bool = false
//    @State private var route: MKRoute?
//    @State private var routeDestination: MKMapItem?
//    var body: some View {
//        NavigationStack {
//            Map(position: $cameraPosition, selection: $mapSelection, scope: locationSpace) {
//                /// Map Annotations
//                Annotation("Your location", coordinate: .myLocation) {
//                    ZStack {
//                        Image(systemName: "mappin.circle.fill")
//                            .foregroundColor(.blue)
//                            .font(.title)
//                    }
//                }
//               
//                
//                /// Simply Display Annotations as Marker, as we seen before
//                ForEach(searchResults, id: \.self) { mapItem in
//                    /// Hiding All other Markers, Expect Destionation one
//                    if routeDisplaying {
//                        if mapItem == routeDestination {
//                            let placemark = mapItem.placemark
//                            Marker(placemark.name ?? "Place", coordinate: placemark.coordinate)
//                                .tint(.blue)
//                        }
//                    } else {
//                        let placemark = mapItem.placemark
//                        Marker(placemark.name ?? "Place", coordinate: placemark.coordinate)
//                            .tint(.blue)
//                    }
//                }
//                
//                /// Display Route using Polyline
//                if let route {
//                    MapPolyline(route.polyline)
//                    /// Applying Bigger Stroke
//                        .stroke(.blue, lineWidth: 7)
//                }
//                
//                /// To Show User Current Location
//                /// This will work only when the User Gave Location Access
//                UserAnnotation()
//            }
//            .onMapCameraChange({ ctx in
//                viewingRegion = ctx.region
//            })
//            .overlay(alignment: .bottomTrailing) {
//                VStack(spacing: 15) {
//                    MapCompass(scope: locationSpace)
//                    MapPitchToggle(scope: locationSpace)
//                    /// As this will work only when the User Gave Location Access
//                    MapUserLocationButton(scope: locationSpace)
//                    /// This will Goes to the Defined User Region
//                    Button {
//                        withAnimation(.smooth) {
//                            cameraPosition = .region(.myRegion)
//                        }
//                    } label: {
//                        Image(systemName: "mappin")
//                            .font(.title3)
//                    }
//                    .buttonStyle(.borderedProminent)
//                }
//                .buttonBorderShape(.circle)
//                .padding()
//            }
//            .mapScope(locationSpace)
//            .navigationTitle("Are you looking for nearest grocery store?")
//            .navigationBarTitleDisplayMode(.inline)
//            /// Search Bar
//            .searchable(text: $searchText, isPresented: $showSearch)
//            /// Showing Trasnlucent ToolBar
//            .toolbarBackground(.visible, for: .navigationBar)
//            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
//            /// When Route Displaying Hiding Top And Bottom Bar
//            .toolbar(routeDisplaying ? .hidden : .visible, for: .navigationBar)
//            .sheet(isPresented: $showDetails, onDismiss: {
//                withAnimation(.snappy) {
//                    /// Zooming Region
//                    if let boundingRect = route?.polyline.boundingMapRect, routeDisplaying {
//                        cameraPosition = .rect(boundingRect.reducedRect(0.45))
//                    }
//                }
//            }, content: {
//                MapDetails()
//                    .presentationDetents([.height(300)])
//                    .presentationBackgroundInteraction(.enabled(upThrough: .height(300)))
//                    .presentationCornerRadius(25)
//                    .interactiveDismissDisabled(true)
//            })
//            .safeAreaInset(edge: .bottom) {
//                if routeDisplaying {
//                    Button("End Route") {
//                        /// Closing The Route and Setting the Selection
//                        withAnimation(.snappy) {
//                            routeDisplaying = false
//                            showDetails = true
//                            mapSelection = routeDestination
//                            routeDestination = nil
//                            route = nil
//                            if let coordinate = mapSelection?.placemark.coordinate {
//                                cameraPosition = .region(.init(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000))
//                            }
//                        }
//                    }
//                    .foregroundStyle(.white)
//                    .frame(maxWidth: .infinity)
//                    .contentShape(Rectangle())
//                    .padding(.vertical, 12)
//                    .background(.blue.gradient, in: .rect(cornerRadius: 15))
//                    .padding()
//                    .background(.ultraThinMaterial)
//                }
//            }
//        }
//        .onSubmit(of: .search) {
//            Task {
//                guard !searchText.isEmpty else { return }
//                
//                await searchPlaces()
//            }
//        }
//        .onChange(of: showSearch, initial: false) {
//            if !showSearch {
//                /// Clearing Search Results
//                searchResults.removeAll(keepingCapacity: false)
//                showDetails = false
//                /// Zooming out to User Region when Search Cancelled
//                withAnimation(.smooth) {
//                    cameraPosition = .region(viewingRegion ?? .myRegion)
//                }
//            }
//        }
//        .onChange(of: mapSelection) { oldValue, newValue in
//            /// Displaying Details about the Selected Place
//            showDetails = newValue != nil
//            /// Fetching Look Around Preview, when ever selection Changes
//            fetchLookAroundPreview()
//        }
//    }
//    
//    /// Map Details View
//    @ViewBuilder
//    func MapDetails() -> some View {
//        VStack(spacing: 15) {
//            ZStack {
//                /// New Look Around API
//                if lookAroundScene == nil {
//                    /// New Empty View API
//                    ContentUnavailableView("No Preview Available", systemImage: "eye.slash")
//                } else {
//                    LookAroundPreview(scene: $lookAroundScene)
//                }
//            }
//            .frame(height: 200)
//            .clipShape(.rect(cornerRadius: 15))
//            /// Close Button
//            .overlay(alignment: .topTrailing) {
//                Button(action: {
//                    /// Closing View
//                    showDetails = false
//                    withAnimation(.snappy) {
//                        mapSelection = nil
//                    }
//                }, label: {
//                    Image(systemName: "xmark.circle.fill")
//                        .font(.title)
//                        .foregroundStyle(.black)
//                        .background(.white, in: .circle)
//                })
//                .padding(10)
//            }
//            
//            /// Direction's Button
//            Button("Get Directions", action: fetchRoute)
//                .foregroundStyle(.white)
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 12)
//                .contentShape(Rectangle())
//                .background(.blue.gradient, in: .rect(cornerRadius: 15))
//        }
//        .padding(15)
//    }
//    
//    /// Search Places
//    func searchPlaces() async {
//        let request = MKLocalSearch.Request()
//        request.naturalLanguageQuery = searchText
//        request.region = viewingRegion ?? .myRegion
//        
//        let results = try? await MKLocalSearch(request: request).start()
//        searchResults = results?.mapItems ?? []
//    }
//    
//    /// Fetching Location Preview
//    func fetchLookAroundPreview() {
//        if let mapSelection {
//            /// Clearing Old One
//            lookAroundScene = nil
//            Task.detached(priority: .background) {
//                let request = MKLookAroundSceneRequest(mapItem: mapSelection)
//                lookAroundScene = try? await request.scene
//            }
//        }
//    }
//    
//    /// Fetching Route
//    func fetchRoute() {
//        if let mapSelection {
//            let request = MKDirections.Request()
//            request.source = .init(placemark: .init(coordinate: .myLocation))
//            request.destination = mapSelection
//            
//            Task {
//                let result = try? await MKDirections(request: request).calculate()
//                route = result?.routes.first
//                /// Saving Route Destination
//                routeDestination = mapSelection
//                
//                withAnimation(.snappy) {
//                    routeDisplaying = true
//                    showDetails = false
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//}
//
//extension MKMapRect {
//    func reducedRect(_ fraction: CGFloat = 0.35) -> MKMapRect {
//        var regionRect = self
//
//        let wPadding = regionRect.size.width * fraction
//        let hPadding = regionRect.size.height * fraction
//                    
//        regionRect.size.width += wPadding
//        regionRect.size.height += hPadding
//                    
//        regionRect.origin.x -= wPadding / 2
//        regionRect.origin.y -= hPadding / 2
//        
//        return regionRect
//    }
//}
//
///// Location Data
//extension CLLocationCoordinate2D {
//    static var myLocation: CLLocationCoordinate2D {
//        return .init(latitude: -33.8835, longitude: 151.2005)
//    }
//}
//
//extension MKCoordinateRegion {
//    static var myRegion: MKCoordinateRegion {
//        return .init(center: .myLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
//    }
//}
import SwiftUI
import MapKit

struct Store: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let description: String
}

struct MapView: View {
    @State private var selectedStore: Store?
    @ObservedObject var viewModel = ContentViewModel()
//    @ObservedObject var viewModel = GroceryListViewModel()
    let stores: [Store] = [
        Store(name: "Sell Fresh", coordinate: CLLocationCoordinate2D(latitude: -33.8835, longitude: 151.2005), description: "Find your daily needs at one place"),
        Store(name: "Sell Fresh", coordinate: CLLocationCoordinate2D(latitude: -33.8000, longitude: 151.2008), description: "Find your daily needs at one place"),
        Store(name: "Sell Fresh", coordinate: CLLocationCoordinate2D(latitude: -33.7835, longitude: 151.3005), description: "Find your daily needs at one place"),
        Store(name: "Sell Fresh", coordinate: CLLocationCoordinate2D(latitude: -33.7615, longitude: 151.1005), description: "Find your daily needs at one place"),
        Store(name: "Sell Fresh", coordinate: CLLocationCoordinate2D(latitude: -37.7879, longitude: 151.2005), description: "Find your daily needs at one place")
    ]
    
    var body: some View {
        ZStack{
            Map(coordinateRegion:   .constant(MKCoordinateRegion(center: CLLocationCoordinate2D (latitude:-33.8835, longitude: 151.2005), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))), showsUserLocation:true, annotationItems: stores) { store in
                MapAnnotation(coordinate: store.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            self.selectedStore = store
                        }
                        .accentColor(.black)
                    
                }
                
            }
            .sheet(item: $selectedStore) { store in
                StoreDetailView(store: store)
            }
//            Map(coordinateRegion: $viewModel.region, showsUserLocation: true)
//                .ignoresSafeArea()
//                .accentColor(Color(.black))
//                .onAppear(){
//                    viewModel.checkIfLocationServiceIsEnable() // Call method from ContentViewModel
//
//                }
            .ignoresSafeArea()
        }
    }
    
    
}

struct StoreDetailView: View {
    let store: Store

    var body: some View {
        VStack {
            Text(store.name)
                .font(.title)
            Text(store.description)
                .padding()
            Spacer()
        }
    }
}
final class ContentViewModel:NSObject, ObservableObject, CLLocationManagerDelegate{
    

    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:-33.865143, longitude:151.2093),
                                                   span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    var locationManager: CLLocationManager?
    func checkIfLocationServiceIsEnable(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager = CLLocationManager()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager!.delegate = self
        } else {
            print("your location is turned of ")
        }
    }
        private func checkLocationAuthorization(){
            guard let locationManager = locationManager else {return}
            
            switch locationManager.authorizationStatus{
                
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("Your location is restricted")
            case .denied:
                print("You have denied app location please allow location from settings" )
            case .authorizedAlways, .authorizedWhenInUse:
                region = MKCoordinateRegion(center: locationManager.location!.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            @unknown default:
                break
            }
        }
        
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager){
            checkLocationAuthorization()
        }
    }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
