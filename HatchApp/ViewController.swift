//
//  ViewController.swift
//  HatchApp
//
//  Created by CURTIS DUNNE on 10/31/19.
//  Copyright © 2019 CURTIS DUNNE. All rights reserved.
//

import UIKit
import Contacts
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(CustomContactCell.self, forCellWithReuseIdentifier: "Cell")
        return cv
    }()

    var contactsArray = [ContactData]()
    
    var locationManageer: CLLocationManager!
    
    var spinner = UIActivityIndicatorView(style: .whiteLarge)
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)
        collectionView.backgroundColor = UIColor(named: "herb")
        collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: view.frame.height - 80).isActive = true

        getCurrentUserLocation()

        spinner.startAnimating()
        view.addSubview(spinner)
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        fetchAllContacts()
        
        spinner.stopAnimating()
    }
    
    func getCurrentUserLocation() {
        locationManageer = CLLocationManager()
        locationManageer.delegate = self
        locationManageer.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManageer.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManageer.startUpdatingLocation()
        }
    }
    
    func fetchAllContacts() {
        DispatchQueue.global().async {
            let contactStore = CNContactStore()
            
            let keysToFetch = [CNContactPostalAddressesKey, CNContactPhoneNumbersKey, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)] as [Any]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])
            
            var indexCount = 0
            
            do {
                try contactStore.enumerateContacts(with: request) { (contact, stop) in
                    self.buildContactLocation(contact: contact, locationCompletionHandler: { distance, error in
                        var contactData = ContactData(index: indexCount)

                        indexCount += 1
                        contactData.givenName = contact.givenName
                        contactData.familyName = contact.familyName
                        contactData.backgroundImage = #imageLiteral(resourceName: "background.jpeg")
                        // getting only first mobile phone number if one exists
                        if let number = contact.phoneNumbers.first {
                            contactData.phone = number.value.stringValue
                        }
                        
                        if let distance = distance {
                            contactData.locationDistance = distance
                        }
                        self.contactsArray.append(contactData)
                        
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                    })
                }
            } catch {
                print("There was a problem fetching Contacts on your device.")
            }
        }
    }
    
    func buildContactLocation(contact: CNContact, locationCompletionHandler: @escaping (Double?, Error?) -> Void) {
        // for now always using only the first address as a default
        if let postalAddress: CNLabeledValue<CNPostalAddress> = contact.postalAddresses.first {
            let geoCoder = CLGeocoder()
            var coordinate: CLLocation? = nil
            var distanceInMiles: Double = 0

            if let postalAddressString = buildAddressString(postalAddress: postalAddress) {
                geoCoder.geocodeAddressString(postalAddressString) { (placemarks, error) in
                    if let error = error {
                        print("Unable to create a location from given address: \(error).")
                        locationCompletionHandler(nil, error)
                    } else {
                        var location: CLLocation?
                        
                        if let placemarks = placemarks, placemarks.count > 0 {
                            location = placemarks.first?.location
                        }
                        
                        if let location = location {
                            coordinate = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                            
                            if let currentUserLocation = self.appDelegate.currentUserLocation {
                                if let coordinate = coordinate {
                                    let distanceInMeters = currentUserLocation.distance(from: coordinate)
                                    distanceInMiles = distanceInMeters/1609.344
                                    locationCompletionHandler(distanceInMiles.rounded(toPlaces: 1), nil)
                                } else {
                                    locationCompletionHandler(nil, nil)
                                }
                            } else {
                                locationCompletionHandler(nil, nil)
                            }
                        } else {
                            locationCompletionHandler(nil, nil)
                        }
                    }
                }
            } else {
                locationCompletionHandler(nil, nil)
            }
        } else {
            locationCompletionHandler(nil, nil)
        }
    }
    
    func buildAddressString(postalAddress: CNLabeledValue<CNPostalAddress>) -> String? {
        return postalAddress.value.country + ", " +
               postalAddress.value.city + ", " +
               postalAddress.value.street
    }
    
    // MARK - CLLocationDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0] as CLLocation
        
        // we only need our User location once....not worrying about updating it yet so stop updating location
        manager.stopUpdatingLocation()
        
        print("User Lattitude = \(userLocation.coordinate.latitude)")
        print("User Longitude = \(userLocation.coordinate.longitude)")

        // store userer location in appDelegate
        appDelegate.currentUserLocation = userLocation
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("An Error occurred when attempting to get or compute device location: \(error)")
    }
    
}

extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/1.5, height: collectionView.frame.height/2.2)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contactsArray.count 
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CustomContactCell
        cell.data = self.contactsArray[indexPath.item]
        cell.setNameLabelText(text: buildFullName(contactData: self.contactsArray[indexPath.item]) ?? "Unknown")
        
        cell.setDistanceText(text: cell.data?.locationDistance?.description ?? "Unknown ")
        return cell 
    }
    
    func buildFullName(contactData: ContactData) -> String? {
        if let givenName = contactData.givenName {
            if let familyName = contactData.familyName {
                return givenName + " " + familyName
            } else {
                return givenName
            }
        } else if let familyName = contactData.familyName {
            return familyName
        } else {
            return "Unknown Name"
        }
    }
}

extension UIViewController {
    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
}

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
