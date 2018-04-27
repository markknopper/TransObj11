//
//  PrerollController.swift
//  TransObj11
//
//  Created by Mark Knopper on 11/4/17.
//  Copyright © 2017 Bulbous Ventures LLC. All rights reserved.
//
// Do some nice pre-roll animation of a lemon going up.

import UIKit

class PrerollController: UIViewController {
    
    @IBOutlet weak var bigLemon: UIImageView!
    
    override func viewDidLoad() {
        bigLemon.translatesAutoresizingMaskIntoConstraints = false
        let horizontalCenterConstraint = NSLayoutConstraint(item: bigLemon, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
        horizontalCenterConstraint.isActive = true
        self.view.addConstraint(horizontalCenterConstraint)
        let widthConstraint = NSLayoutConstraint(item: bigLemon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: bigLemon.frame.size.width)
        widthConstraint.isActive = true
        self.view.addConstraint(widthConstraint)
        let verticalTopConstraint = NSLayoutConstraint(item: bigLemon, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 345)
        verticalTopConstraint.isActive = true
        self.view.addConstraint(verticalTopConstraint)

        verticalTopConstraint.constant = 4
        widthConstraint.constant = 42
        UIView.animate(withDuration: 2, animations: {
            self.view.layoutIfNeeded()
        }, completion: { (finished: Bool) in
            self.performSegue(withIdentifier: "lemonToStart", sender: self)
        })
    }
}
