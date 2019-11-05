//
//  customContactCellCollectionViewCell.swift
//  HatchApp
//
//  Created by CURTIS DUNNE on 10/31/19.
//  Copyright © 2019 CURTIS DUNNE. All rights reserved.
//

import UIKit
import MessageUI

class CustomContactCell: UICollectionViewCell, MFMessageComposeViewControllerDelegate {
    
    var data: ContactData? {
        didSet {
            guard let data = data else { return }
            bg.image = data.backgroundImage
        }
    }
    
    var parentViewController: UIViewController?
    
    fileprivate let bg: UIImageView = {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        imgView.image = #imageLiteral(resourceName: "background.jpeg")
        imgView.layer.cornerRadius = 15
        return imgView
    }()
    
    fileprivate let nameLabel: UILabel = UILabel(frame: CGRect(x: 10, y: 10, width: 250, height: 40))
    
    fileprivate let distanceLabel: UILabel = UILabel(frame: CGRect(x: 10, y: 50, width: 250, height: 40))
    
    fileprivate let msgButton: UIButton = UIButton(frame: CGRect(x: 20, y: 150, width: 200, height: 50))
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        contentView.addSubview(bg)
        bg.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        bg.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        bg.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        bg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentView.sendSubviewToBack(bg)
        
        contentView.addSubview(nameLabel)
        nameLabel.textColor = UIColor(named: "charcoal")
        nameLabel.font = UIFont(name: "Knewave-Regular", size: 24)
        contentView.bringSubviewToFront(nameLabel)
        
        contentView.addSubview(distanceLabel)
        distanceLabel.textColor = UIColor(named: "chili")
        distanceLabel.font = UIFont(name: "Handlee-Regular", size: 18)
        
        contentView.addSubview(msgButton)
        msgButton.setTitleColor(.black, for: .normal)
        msgButton.backgroundColor = UIColor(named: "herb")
        
        msgButton.setTitle("Send a Message", for: .normal)
        msgButton.titleLabel?.font = UIFont(name: "Handlee-Regular", size: 22)
        msgButton.addTarget(self, action: #selector(messageAction), for: UIControl.Event.touchUpInside)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setNameLabelText(text: String) {
        self.nameLabel.text = text
    }
    
    func setDistanceText(text: String) {
        self.distanceLabel.text = text + " Miles Away."
    }
    
    func setMessageStatus() {
        if let phone = data?.phone {
            if phone.isEmpty {
                msgButton.backgroundColor = UIColor(named: "lightGray")
                msgButton.isEnabled = false
            } else {
                msgButton.backgroundColor = UIColor(named: "herb")
                msgButton.isEnabled = true
            }
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        if let vc = self.parentViewController {
            vc.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func messageAction(sender: UIButton) {
        if !MFMessageComposeViewController.canSendText() {
            print("SMS Services are not currently available")
        }

        if let data = self.data {
            if let phone = data.phone {
                let composeVC = MFMessageComposeViewController()
                composeVC.messageComposeDelegate = self
                composeVC.recipients = [phone]
                composeVC.body = "Hello from the HatchApp"
                
                if let vc = self.parentViewController {
                    vc.present(composeVC, animated: true, completion: nil)
                }

                print("message button was tapped for cell # \(data.index)")
                
                if let phone = data.phone {
                    print("Sending a text message to \(phone)")
                }
            }
        }
    }
}
