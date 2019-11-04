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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        view.addSubview(collectionView)
        collectionView.backgroundColor = UIColor(named: "herb")
        collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: view.frame.height - 80).isActive = true
        
        fetchAllContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getCurrentUserLocation()
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
        let contactStore = CNContactStore()
        
        let keysToFetch = [CNContactPostalAddressesKey, CNContactPhoneNumbersKey, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])
        
        var indexCount = 0
        
        do {
            try contactStore.enumerateContacts(with: request) { (contact, stop) in
                var contactData = ContactData(index: indexCount)

                indexCount += 1
                contactData.givenName = contact.givenName
                contactData.familyName = contact.familyName
                contactData.backgroundImage = #imageLiteral(resourceName: "background.jpeg")
                // getting only first mobile phone number if one exists
                if let number = contact.phoneNumbers.first {
                    contactData.phone = number.value.stringValue
                }
                contactData.locationDistance = self.buildContactLocation(contact: contact)
                
                self.contactsArray.append(contactData)
            }
            print(self.contactsArray)
        } catch {
            print("There was a problem fetching Contacts on your device.")
        }
    }
    
    func buildContactLocation(contact: CNContact) -> Double {
        // for now always using only the first address as a default
        if let addressString: CNLabeledValue<CNPostalAddress> = contact.postalAddresses.first {
            return calcContactLocationDistanceFromUserLocation(postalAddress: addressString)
        } else {
            return 0
        }
    }
    
    func calcContactLocationDistanceFromUserLocation(postalAddress: CNLabeledValue<CNPostalAddress>?) -> Double {
        let geoCoder = CLGeocoder()
        var coordinate: CLLocation? = nil
        var distanceInMiles: Double = 0

        if let postalAddress = postalAddress {
            if let postalAddressString = buildAddressString(postalAddress: postalAddress) {
                geoCoder.geocodeAddressString(postalAddressString) { (placemarks, error) in
                    if let error = error {
                        print("Unable to create a location from given address: \(error).")
                    } else {
                        var location: CLLocation?
                        
                        if let placemarks = placemarks, placemarks.count > 0 {
                            location = placemarks.first?.location
                        }
                        
                        if let location = location {
                            coordinate = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                            
                            if let currentUserLocation = self.appDelegate.currentUserLocation {
                                if let coordinate = coordinate {
                                    //                                if let distance = coordinate?.distance(from: currentUserLocation) {
                                    let distanceInMeters = currentUserLocation.distance(from: coordinate)
                                    print("Distance in meters = \(distanceInMeters)")
                                    distanceInMiles = distanceInMeters/1609.344
                                    print("** Distance in miles = \(distanceInMiles)")
                                }
                            }
                        }
                    }
                }
            }
        }
        return distanceInMiles
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
        }
        
        return "Unknown Name"        
    }
}

extension UIViewController {
    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
}
