//
//  ViewController.swift
//  TheSecretParty
//
//  Created by Ángel González on 13/12/24.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    // GeoLocalización.- trabajar con coordenadas y direcciones
    var admUbicacion : CLLocationManager!
    // Las clases del framework CoreLocation utilizan las coordenadas en formato decimal
    // TODO: - Implementar una forma en que estas variables lleguen de otra vista.
    var latitud = 19.432601
    var longitud = -99.133204 // (zócalo de CDMX)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        admUbicacion = CLLocationManager()
        admUbicacion.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        admUbicacion.delegate = self
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        // a) si solo necesitaba una ubicación:
        admUbicacion.stopUpdatingLocation()
        guard let ubicacion = locations.first else { return }
        // print ("usted está en \(ubicacion.coordinate.latitude), \(ubicacion.coordinate.longitude)")
        // obtenemos la dirección que corresponde a una ubicación (reverse geolocation)
        CLGeocoder().reverseGeocodeLocation(ubicacion, completionHandler:{ lugares, error in
            var direccion = ""
            if error != nil {
                print ("no se pudo encontrar la dirección correspondiente a la coordenada origen")
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
                direccion = "Ud. está en: \(thoroughfare) \(subThoroughfare) \(locality) \(subLocality) \(administrativeArea) \(subAdministrativeArea) \(postalCode) \(country)"
                print (direccion)
            }
            // self.colocarPinEn (ubicacion.coordinate, direccion: direccion)
        })
        // ahora encontramos la ubicación de destino:
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitud, longitude: longitud), completionHandler:{ lugares, error in
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
                direccion = "Y debe llegar a: \(thoroughfare) \(subThoroughfare) \(locality) \(subLocality) \(administrativeArea) \(subAdministrativeArea) \(postalCode) \(country)"
                print (direccion)
            }
            // self.colocarPinEn (ubicacion.coordinate, direccion: direccion)
        })
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // a) no hacer nada y seguir esperando lecturas?
        // b) ya no tiene caso seguir buscando geolocalización...
        admUbicacion.stopUpdatingLocation()
    }
}

