//
//  Untitled.swift
//  GSKStretchyHeaderView
//
//  Created by Maziar Saadatfar on 10/2/24.
//  Copyright © 2024 Jose Alcalá-Correa. All rights reserved.
//
import UIKit
public extension UIScrollView {
    func gsk_fixZPositions(for headerView: GSKStretchyHeaderView) {
        headerView.layer.zPosition = 1
        for subview in self.subviews {
            if !(subview.gsk_shouldBeBelowStretchyHeaderView) && (subview.layer.zPosition == 0 || subview.layer.zPosition == 1) {
                subview.layer.zPosition = 2
            }
        }
    }
    
    func gsk_arrangeStretchyHeaderView(_ headerView: GSKStretchyHeaderView) {
        assert(headerView.superview == self, "The provided header view must be a subview of \(self)")
        guard let stretchyHeaderViewIndex = self.subviews.firstIndex(of: headerView) else { return }
        var stretchyHeaderViewNewIndex = stretchyHeaderViewIndex
        
        for i in (stretchyHeaderViewIndex + 1)..<self.subviews.count {
            let subview = self.subviews[i]
            if subview.gsk_shouldBeBelowStretchyHeaderView {
                stretchyHeaderViewNewIndex = i
            }
        }
        
        if stretchyHeaderViewIndex != stretchyHeaderViewNewIndex {
            self.exchangeSubview(at: stretchyHeaderViewIndex, withSubviewAt: stretchyHeaderViewNewIndex)
        }
    }
    
    func gsk_layoutStretchyHeaderView(_ headerView: GSKStretchyHeaderView, contentOffset: CGPoint, previousContentOffset: CGPoint) {
        if headerView.contentIsStatic {
            return
        }
        
        var headerFrame = headerView.frame
        headerFrame.origin.y = contentOffset.y
        if headerFrame.width != self.bounds.width {
            headerFrame.size.width = self.bounds.width
        }
        
        var adjustedContentOffset = contentOffset
        var adjustedPreviousContentOffset = previousContentOffset
        
        if !headerView.manageScrollViewInsets {
            let offsetAdjustment = headerView.maximumHeight - headerView.minimumHeight
            adjustedContentOffset.y -= offsetAdjustment
            adjustedPreviousContentOffset.y -= offsetAdjustment
        }
        
        var headerViewHeight = headerView.bounds.height
        switch headerView.expansionMode {
        case .topOnly:
            if adjustedContentOffset.y + headerView.maximumHeight <= 0 {
                headerViewHeight = -adjustedContentOffset.y
            } else {
                headerViewHeight = min(headerView.maximumHeight, max(-adjustedContentOffset.y, headerView.minimumHeight))
            }
        case .immediate:
            let scrollDelta = adjustedContentOffset.y - adjustedPreviousContentOffset.y
            if adjustedContentOffset.y + headerView.maximumHeight <= 0 {
                headerViewHeight = -adjustedContentOffset.y
            } else {
                headerViewHeight -= scrollDelta
                headerViewHeight = min(headerView.maximumHeight, max(headerViewHeight, headerView.minimumHeight))
            }
        @unknown default:
            break
        }
        headerFrame.size.height = headerViewHeight
        
        if headerView.frame.size != headerFrame.size {
            headerView.setNeedsLayoutContentView()
        }
        headerView.frame = headerFrame
        
        headerView.layoutContentViewIfNeeded()
    }
}

public extension UIView {
    var gsk_shouldBeBelowStretchyHeaderView: Bool {
        return self is UITableViewCell ||
               self is UITableViewHeaderFooterView ||
               self is UICollectionReusableView
    }
}

