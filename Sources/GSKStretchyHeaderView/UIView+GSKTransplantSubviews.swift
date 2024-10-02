//
//  UIView+GSKTransplantSubviews.swift
//  GSKStretchyHeaderView
//
//  Created by Maziar Saadatfar on 10/2/24.
//  Copyright © 2024 Jose Alcalá-Correa. All rights reserved.
//
import UIKit
public extension UIView {
    func gsk_isSelfOrLayoutGuide(_ object: Any) -> Bool {
        // We can't transplant constraints to layout guides like safe area insets (introduced in iOS 11)
        // So we assume the constraints will be related to the superview
        // This may become a problem if the safe area insets are not zero, but for header views it's always the case
        if object as AnyObject === self {
            return true
        } else if #available(iOS 9.0, *) {
            return object is UILayoutGuide
        }
        return false
    }
    
    func gsk_transplantSubviewsToView(_ newSuperview: UIView) {
        let oldSubviews = self.subviews
        let oldConstraints = self.constraints
        var oldConstraintsActiveValues: [Bool] = []
        
        if NSLayoutConstraint.instancesRespond(to: #selector(getter: NSLayoutConstraint.isActive)) {
            oldConstraintsActiveValues = oldConstraints.map { $0.isActive }
        }
        
        for view in oldSubviews {
            view.removeFromSuperview()
            newSuperview.addSubview(view)
        }
        
        self.removeConstraints(oldConstraints)
        oldConstraints.enumerated().forEach { index, oldConstraint in
            let firstItem = self.gsk_isSelfOrLayoutGuide(oldConstraint.firstItem as Any) ? newSuperview : oldConstraint.firstItem
            let secondItem = self.gsk_isSelfOrLayoutGuide(oldConstraint.secondItem as Any) ? newSuperview : oldConstraint.secondItem
            let constraint = oldConstraint.gsk_copy(withFirstItem: firstItem, secondItem: secondItem)
            
            if constraint.responds(to: #selector(setter: NSLayoutConstraint.isActive)) {
                constraint.isActive = oldConstraintsActiveValues[index]
            } else {
                newSuperview.addConstraint(constraint)
            }
        }
    }
}

extension NSLayoutConstraint {
    func gsk_copy(withFirstItem firstItem: Any?, secondItem: Any?) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: firstItem as Any,
                                            attribute: self.firstAttribute,
                                            relatedBy: self.relation,
                                            toItem: secondItem,
                                            attribute: self.secondAttribute,
                                            multiplier: self.multiplier,
                                            constant: self.constant)
        constraint.identifier = self.identifier
        if self.responds(to: #selector(getter: NSLayoutConstraint.isActive)) {
            constraint.isActive = self.isActive
        }
        return constraint
    }
}

