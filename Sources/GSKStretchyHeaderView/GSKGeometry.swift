//
//  GSKGeometry.swift
//  GSKStretchyHeaderView
//
//  Created by Maziar Saadatfar on 10/2/24.
//  Copyright © 2024 Jose Alcalá-Correa. All rights reserved.
//
import Foundation
import CoreGraphics
public func CGFloatInterpolate(_ factor: CGFloat,_ min: CGFloat,_ max: CGFloat) -> CGFloat {
    return min + (max - min) * factor
}

public func CGFloatTranslateRange(_ value: CGFloat, _ oldMin: CGFloat, _ oldMax: CGFloat, _ newMin: CGFloat, _ newMax: CGFloat) -> CGFloat {
    let oldRange = oldMax - oldMin
    let newRange = newMax - newMin
    return (value - oldMin) * newRange / oldRange + newMin
}
public func CGPointInterpolate(_ factor: CGFloat, _ origin: CGPoint, _ end: CGPoint) -> CGPoint {
    return CGPoint(
        x: CGFloatInterpolate(factor, origin.x, end.x),
        y: CGFloatInterpolate(factor, origin.y, end.y))
}
public func CGSizeInterpolate(_ factor: CGFloat, _ minSize: CGSize, _ maxSize: CGSize) -> CGSize {
    return CGSize(
        width: CGFloatInterpolate(factor, minSize.width, maxSize.width),
        height: CGFloatInterpolate(factor, minSize.height, maxSize.height))
}


public func CGRectInterpolate(_ factor: CGFloat, _ minRect: CGRect, _ maxRect: CGRect) -> CGRect {
    var rect = CGRect()
    rect.origin = CGPointInterpolate(factor, minRect.origin, maxRect.origin)
    rect.size = CGSizeInterpolate(factor, minRect.size, maxRect.size)
    return rect
}
