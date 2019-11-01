//
//  ViewController.swift
//  HatchApp
//
//  Created by CURTIS DUNNE on 10/31/19.
//  Copyright © 2019 CURTIS DUNNE. All rights reserved.
//

import UIKit
import Contacts

class ViewController: UIViewController {
    
    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(CustomContactCell.self, forCellWithReuseIdentifier: "Cell")
        return cv
    }()

    var contactsArray = [ContactData]()

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
    
    func fetchAllContacts() {
        let contactStore = CNContactStore()
        
        let keysToFetch = [CNContactPhoneNumbersKey, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)] as [Any]
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
                
                self.contactsArray.append(contactData)
            }
            print(self.contactsArray)
        } catch {
            print("There was a problem fetching Contacts on your device.")
        }
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

