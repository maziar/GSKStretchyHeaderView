//
//  GSKStretchyHeaderView.swift
//  GSKStretchyHeaderView
//
//  Created by Maziar Saadatfar on 10/2/24.
//  Copyright © 2024 Jose Alcalá-Correa. All rights reserved.
//
import UIKit

public let kNibDefaultMaximumContentHeight: CGFloat = 240
public enum GSKStretchyHeaderViewContentAnchor: Int {
    case top = 0
    case bottom = 1
}
public enum GSKStretchyHeaderViewExpansionMode: Int {
    case topOnly = 0
    case immediate = 1
}
public protocol GSKStretchyHeaderViewStretchDelegate: AnyObject {
    func stretchyHeaderView(_ headerView: GSKStretchyHeaderView,
                            didChangeStretchFactor stretchFactor: CGFloat)
}

public class GSKStretchyHeaderView: UIView {
    public var minimumContentHeight: CGFloat = 0
    public var contentAnchor: GSKStretchyHeaderViewContentAnchor = .top
    public var manageScrollViewInsets: Bool = true
    public var manageScrollViewSubviewHierarchy: Bool = true
    public var contentShrinks: Bool = true
    public var contentExpands: Bool = true
    public var contentIsStatic: Bool = false
    public var needsLayoutContentView: Bool = false
    public var arrangingSelfInScrollView: Bool = false
    
    public weak var scrollView: UIScrollView?
    public var observingScrollView: Bool = false
    public weak var stretchDelegate: GSKStretchyHeaderViewStretchDelegate?
    public var stretchFactor: CGFloat = 0
    
    var maximumContentHeight: CGFloat = 0 {
        didSet {
            setupScrollViewInsetsIfNeeded()
            scrollView?.gsk_layoutStretchyHeaderView(
                self,
                contentOffset: scrollView?.contentOffset ?? .zero,
                previousContentOffset: scrollView?.contentOffset ?? .zero
            )
        }
    }
    
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            setupScrollViewInsetsIfNeeded()
        }
    }
    
    public var expansionMode: GSKStretchyHeaderViewExpansionMode = .topOnly {
        didSet {
            scrollView?.gsk_layoutStretchyHeaderView(
                self,
                contentOffset: scrollView?.contentOffset ?? .zero,
                previousContentOffset: scrollView?.contentOffset ?? .zero
            )
        }
    }
    
    public var contentView: GSKStretchyHeaderContentView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.maximumContentHeight = self.frame.size.height
        setupView()
        setupContentView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
        setupContentView()
    }
    
    public func setupView() {
        self.clipsToBounds = true
        self.minimumContentHeight = 0
        self.contentAnchor = .top
        self.contentExpands = true
        self.contentShrinks = true
        self.contentIsStatic = false
        self.manageScrollViewInsets = true
        self.manageScrollViewSubviewHierarchy = true
    }
    
    public func setupContentView() {
        contentView = GSKStretchyHeaderContentView(frame: self.bounds)
        gsk_transplantSubviewsToView(contentView)
        self.addSubview(contentView)
        setNeedsLayoutContentView()
    }
    
    func setMaximumContentHeight(_ maximumContentHeight: CGFloat, resetAnimated animated: Bool) {
        self.maximumContentHeight = maximumContentHeight
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            self.scrollView?.contentOffset = CGPoint(x: 0, y: -(self.maximumContentHeight + self.contentInset.top))
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        if maximumContentHeight == 0 {
            self.maximumContentHeight = kNibDefaultMaximumContentHeight
        }
    }
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if window != nil {
            observeScrollViewIfPossible()
        } else {
            stopObservingScrollView()
        }
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if !manageScrollViewSubviewHierarchy {
            return
        }
        
        if #available(iOS 11.0, *) {
            scrollView?.gsk_fixZPositions(for: self)
        }
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if self.superview !== scrollView {
            stopObservingScrollView()
            scrollView = nil
        }
        
        if let scrollView = self.superview as? UIScrollView {
            self.scrollView = scrollView
            observeScrollViewIfPossible()
            setupScrollViewInsetsIfNeeded()
        }
    }
    
    public func observeScrollViewIfPossible() {
        guard let scrollView = scrollView, !observingScrollView else { return }
        
        scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), options: [.new, .old], context: nil)
        scrollView.layer.addObserver(self, forKeyPath: #keyPath(CALayer.sublayers), options: .new, context: nil)
        observingScrollView = true
    }
    
    public override func removeFromSuperview() {
        stopObservingScrollView()
        super.removeFromSuperview()
    }
    
    public func stopObservingScrollView() {
        guard observingScrollView else { return }
        
        scrollView?.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset))
        scrollView?.layer.removeObserver(self, forKeyPath: #keyPath(CALayer.sublayers))
        
        observingScrollView = false
    }
    
    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if object as? UIScrollView === scrollView {
            guard keyPath == #keyPath(UIScrollView.contentOffset) else {
                assertionFailure("keyPath '\(String(describing: keyPath))' is not being observed")
                return
            }
            
            let contentOffset = change?[.newKey] as? CGPoint ?? .zero
            let previousContentOffset = change?[.oldKey] as? CGPoint ?? .zero
            scrollView?.gsk_layoutStretchyHeaderView(self, contentOffset: contentOffset, previousContentOffset: previousContentOffset)
        } else if object as? CALayer === scrollView?.layer {
            guard keyPath == #keyPath(CALayer.sublayers) else {
                assertionFailure("keyPath '\(String(describing: keyPath))' is not being observed")
                return
            }
            
            if !arrangingSelfInScrollView && manageScrollViewSubviewHierarchy {
                arrangingSelfInScrollView = true
                scrollView?.gsk_arrangeStretchyHeaderView(self)
                arrangingSelfInScrollView = false
            }
        }
    }
    
    public var verticalInset: CGFloat {
        return contentInset.top + contentInset.bottom
    }
    
    public var horizontalInset: CGFloat {
        return contentInset.left + contentInset.right
    }
    
    public var maximumHeight: CGFloat {
        return maximumContentHeight + verticalInset
    }
    
    public var minimumHeight: CGFloat {
        return minimumContentHeight + verticalInset
    }
    
    public func setupScrollViewInsetsIfNeeded() {
        guard let scrollView = scrollView, manageScrollViewInsets else { return }
        
        var scrollViewContentInset = scrollView.contentInset
        scrollViewContentInset.top = maximumContentHeight + contentInset.top + contentInset.bottom
        scrollView.contentInset = scrollViewContentInset
    }
    
    public func setNeedsLayoutContentView() {
        needsLayoutContentView = true
    }
    
    public func layoutContentViewIfNeeded() {
        guard needsLayoutContentView else { return }
        
        if contentIsStatic {
            needsLayoutContentView = false
            return
        }
        
        let ownHeight = bounds.height
        let ownWidth = bounds.width
        let contentHeightDif = maximumContentHeight - minimumContentHeight
        let maxContentViewHeight = ownHeight - verticalInset
        
        var contentViewHeight = maxContentViewHeight
        if !contentExpands {
            contentViewHeight = min(contentViewHeight, maximumContentHeight)
        }
        if !contentShrinks {
            contentViewHeight = max(contentViewHeight, maximumContentHeight)
        }
        
        var contentViewTop: CGFloat = 0
        switch contentAnchor {
        case .top:
            contentViewTop = contentInset.top
        case .bottom:
            contentViewTop = ownHeight - contentViewHeight
            if !contentExpands {
                contentViewTop = min(0, contentViewTop)
            }
        }
        
        contentView.frame = CGRect(x: contentInset.left, y: contentViewTop, width: ownWidth - horizontalInset, height: contentViewHeight)
        
        let newStretchFactor = (maxContentViewHeight - minimumContentHeight) / contentHeightDif
        if newStretchFactor != stretchFactor {
            stretchFactor = newStretchFactor
            didChangeStretchFactor(newStretchFactor)
            stretchDelegate?.stretchyHeaderView(self, didChangeStretchFactor: newStretchFactor)
        }
        
        needsLayoutContentView = false
    }
    
    func didChangeStretchFactor(_ stretchFactor: CGFloat) {
        // to be implemented in subclasses
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutContentViewIfNeeded()
    }
    
    func contentViewDidLayoutSubviews() {
        // default implementation does not do anything
    }
}

public class GSKStretchyHeaderContentView: UIView {
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let stretchyHeaderView = self.superview as? GSKStretchyHeaderView {
            stretchyHeaderView.contentViewDidLayoutSubviews()
        }
    }
}

