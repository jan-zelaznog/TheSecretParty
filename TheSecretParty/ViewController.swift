//
//  ViewController.swift
//  TheSecretParty
//
//  Created by Ángel González on 13/12/24.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    // GeoLocalización.- trabajar con coordenadas y direcciones
    var admUbicacion : CLLocationManager!
    // Las clases del framework CoreLocation utilizan las coordenadas en formato decimal
    // TODO: - Implementar una forma en que estas variables lleguen de otra vista.
    var latitud = 19.432601
    var longitud = -99.133204 // (zócalo de CDMX)
    // generalmente (aunque no indispensable) para la geolocalización se usa un mapa:
    var elMapa: MKMapView!
    var destino: CLLocation!
    
    let colores:[UIColor] = [.blue, .green, .yellow, .gray, .orange, .red]
    var colorIndex = 0
    
    var tipoMapa: UISegmentedControl!
    
    // MARK: - ViewController life cycle
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // este view controller solo se va a mostrar en portrait, no importa si toda el app esta
        // configurada para soportar la rotación
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        admUbicacion = CLLocationManager()
        admUbicacion.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        admUbicacion.delegate = self
        elMapa = MKMapView()
        elMapa.frame = self.view.bounds //.insetBy(dx:50, dy:100)
        elMapa.delegate = self
        self.view.addSubview(elMapa)
        elMapa.mapType = .hybrid
        tipoMapa = UISegmentedControl(items:["Estándar", "Satélite", "Híbrido"])
        tipoMapa.frame.origin = CGPoint(x:0, y:48)
        tipoMapa.frame.size = CGSize(width:self.view.bounds.width, height:45)
        tipoMapa.backgroundColor = .white
        tipoMapa.selectedSegmentTintColor = .purple
        tipoMapa.selectedSegmentIndex = 2
        self.view.addSubview(tipoMapa)
        tipoMapa.addTarget(self, action:#selector(tipoMapaChange), for:.valueChanged)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // verificar los permisos para usar la geolocalización
        switch admUbicacion.authorizationStatus {
            case .notDetermined:
                admUbicacion.delegate = self
                admUbicacion.requestAlwaysAuthorization()
                break
            case .restricted, .denied:
                let alert = UIAlertController(title: "Error", message: "Se requiere su permiso para usar la ubicación, Autoriza ahora?", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "SI", style: UIAlertAction.Style.default, handler: { action in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {return}
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, options: [:],completionHandler:nil)
                    }
                }))
                alert.addAction(UIAlertAction(title: "NO", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            break
            default:    // .authorizedWhenInUse, .authorizedAlways
                admUbicacion.startUpdatingLocation()
                break
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        print ("shake shake shake.... Swiftiessssss!!")
        if tipoMapa.selectedSegmentIndex == 2 {
            tipoMapa.selectedSegmentIndex = 0
        }
        else {
            tipoMapa.selectedSegmentIndex += 1
        }
        tipoMapaChange()
    }
    
    // MARK: - select methods
    @objc func tipoMapaChange() {
        switch tipoMapa.selectedSegmentIndex {
        case 0: elMapa.mapType = .standard
        case 1: elMapa.mapType = .satellite
        default: elMapa.mapType = .hybrid
        }
    }
    
    // MARK: - MapView delegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identificador = "unPin"
        var anotacion:MKMarkerAnnotationView? = elMapa.dequeueReusableAnnotationView(withIdentifier:identificador) as? MKMarkerAnnotationView
        if anotacion == nil {
            // para configurar un pin
            anotacion = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identificador)
            // para configurar otra anotación, ej. una imagen:
            // anotacion = MKAnnotationView(annotation: annotation, reuseIdentifier: identificador)
        }
        anotacion!.markerTintColor = .purple
        if anotacion?.annotation?.coordinate.latitude == destino.coordinate.latitude &&
            anotacion?.annotation?.coordinate.longitude == destino.coordinate.longitude {
            anotacion!.markerTintColor = .blue
        }
        anotacion?.canShowCallout = true
        return anotacion
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        render.strokeColor = colores[colorIndex]
        render.lineWidth = 5
        return render
    }
    
    // MARK: - LocationManager delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        // a) si solo necesitaba una ubicación:
        admUbicacion.stopUpdatingLocation()
        guard let origen = locations.first else { return }
        // centramos el mapa en la ubicación obtenida
        var region = MKCoordinateRegion(center:origen.coordinate, latitudinalMeters: 1000, longitudinalMeters:1000)
        elMapa.setRegion(region, animated:true)
        ////// obtenemos las direcciones de las dos ubicaciones
        // print ("usted está en \(ubicacion.coordinate.latitude), \(ubicacion.coordinate.longitude)")
        // obtenemos la dirección que corresponde a una ubicación (reverse geolocation)
        print ("Ud. está en: ")
        obtenerDirección(de: origen)
        // ahora encontramos la ubicación de destino:
        print ("Y debe llegar a: ")
        destino = CLLocation(latitude: latitud, longitude: longitud)
        obtenerDirección(de: destino)
        if let region = MKCoordinateRegion(coordinates:[origen.coordinate, destino.coordinate]) {
            elMapa.setRegion(region, animated:true)
        }
        trazaRuta (origen, destino)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // a) no hacer nada y seguir esperando lecturas?
        // b) ya no tiene caso seguir buscando geolocalización...
        admUbicacion.stopUpdatingLocation()
    }
    
    // MARK: - Custom methods
    func trazaRuta (_ desde:CLLocation, _ hasta:CLLocation) {
        /*
        let linea = MKPolyline(coordinates:[desde.coordinate, hasta.coordinate], count:2)
        elMapa.addOverlay(linea)
        */
        // Indicaciones de rutas, para llegar de un punto a otro:
        let peticion = MKDirections.Request()
        peticion.source = MKMapItem(placemark: MKPlacemark(coordinate:desde.coordinate))
        peticion.destination = MKMapItem(placemark: MKPlacemark(coordinate:hasta.coordinate))
        peticion.transportType = .automobile
        peticion.requestsAlternateRoutes = true
        // TODO: - validar la conexión a Internet
        let indicaciones = MKDirections(request: peticion)
        indicaciones.calculate(completionHandler: { response, error in
            if error != nil {
                print ("No se obtuvo respuesta del servicio Directions \(error?.localizedDescription)")
            }
            guard let rutas = response?.routes
            else {
                print ("No hay rutas disponibles")
                return
            }
            self.colorIndex = 0
            for ruta in rutas {
                self.elMapa.addOverlay(ruta.polyline)
                self.colorIndex += 1
            }
        })
    }
    
    func obtenerDirección(de ubicacion:CLLocation) {
        // TODO: - validar la conexión a Internet
        CLGeocoder().reverseGeocodeLocation(ubicacion, completionHandler:{ lugares, error in
            var direccion = ""
            if error != nil {
                print ("no se pudo encontrar la dirección correspondiente a la coordenada destino")
            }
            else {
                guard let lugar = lugares?.first else { return }
                let thoroughfare = (lugar.thoroughfare ?? "")
                let subThoroughfare = (lugar.subThoroughfare ?? "")
                let locality = (lugar.locality ?? "")
                let subLocality = (lugar.subLocality ?? "")
                let administrativeArea = (lugar.administrativeArea ?? "")
                let subAdministrativeArea = (lugar.subAdministrativeArea ?? "")
                let postalCode = (lugar.postalCode ?? "")
                let country = (lugar.country ?? "")
                direccion = "\(thoroughfare) \(subThoroughfare) \(locality) \(subLocality) \(administrativeArea) \(subAdministrativeArea) \(postalCode) \(country)"
                print (direccion)
            }
            self.colocarPinEn (ubicacion.coordinate, direccion: direccion)
        })
    }
    
    func colocarPinEn (_ coordenada:CLLocationCoordinate2D, direccion:String) {
        let elPin = MKPointAnnotation()
        elPin.coordinate = coordenada
        elPin.title = direccion
        elMapa.addAnnotation(elPin)
    }
}

