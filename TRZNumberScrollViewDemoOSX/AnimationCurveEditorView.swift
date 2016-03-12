//
//  AnimationCurveEditorView.swift
//  TRZNumberScrollViewDemoOSX
//
//  Created by Thomas Zhao on 3/11/16.
//  Copyright © 2016 Thomas Zhao. All rights reserved.
//

import Cocoa

public class AnimationCurveEditorView: NSView {
    public var backgroundColor:NSColor? = NSColor.whiteColor() {
        didSet {
            needsDisplay = true
        }
    }
    
    public var drawsGrid = true {
        didSet {
            needsDisplay = true
        }
    }
    
    public var gridDivisions:Int = 10 {
        didSet {
            needsDisplay = true
        }
    }
    
    public var gridStrokeColor = NSColor.gridColor() {
        didSet {
            needsDisplay = true
        }
    }
    
    public var gridLineWidth:CGFloat = 1 {
        didSet {
            needsDisplay = true
        }
    }
    
    public var curveStrokeColor:NSColor = NSColor(forControlTint: .BlueControlTint) {
        didSet {
            needsDisplay = true
        }
    }
    
    public var curveLineWidth:CGFloat = 2 {
        didSet {
            needsDisplay = true
        }
    }
    
    public var handleStrokeColor:NSColor = NSColor.grayColor() {
        didSet {
            needsDisplay = true
        }
    }
    
    public var handleLineWidth:CGFloat = 2 {
        didSet {
            needsDisplay = true
        }
    }

    dynamic public var firstControlPoint:CGPoint = CGPointMake(0, 0) {
        didSet {
            needsDisplay = true
        }
    }
    
    public var firstControlPointKnobFillColor:NSColor = NSColor.whiteColor() {
        didSet {
            needsDisplay = true
        }
    }

    public var firstControlPointKnobLineWidth:CGFloat = 2 {
        didSet {
            needsDisplay = true
        }
    }

    public var firstControlPointKnobStrokeColor:NSColor = NSColor.redColor() {
        didSet {
            needsDisplay = true
        }
    }
    
    dynamic public var secondControlPoint:CGPoint = CGPointMake(1, 1) {
        didSet {
            needsDisplay = true
        }
    }
    
    public var secondControlPointKnobLineWidth:CGFloat = 2 {
        didSet {
            needsDisplay = true
        }
    }

    public var secondControlPointKnobFillColor:NSColor = NSColor.whiteColor() {
        didSet {
            needsDisplay = true
        }
    }

    public var secondControlPointKnobStrokeColor:NSColor = NSColor.blueColor() {
        didSet {
            needsDisplay = true
        }
    }
    
    public var controlPointKnobDiameter:CGFloat = 5 {
        didSet {
            needsDisplay = true
        }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        let gestureRecognizer = NSPanGestureRecognizer(target: self, action: Selector("panGestureRecognizerDidRecognize:"))
        addGestureRecognizer(gestureRecognizer)
    }
    
    private var firstControlPointKnobIsOnTop = true
    
    private var adjustingFirstControlPoint:Bool = false
    private var adjustingSecondControlPoint:Bool = false
    
    @objc private func panGestureRecognizerDidRecognize(gestureRecognizer:NSPanGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            let location = gestureRecognizer.locationInView(self)
            let checkFirstControl:(CGFloat)->Bool = { tolerance in
                if self.firstControlPointKnobBounds.insetBy(dx: -tolerance, dy: -tolerance).contains(location) {
                    self.adjustingFirstControlPoint = true
                    self.firstControlPointKnobIsOnTop = true
                    return true
                }
                return false
            }
            
            let checkSecondControl:(CGFloat)->Bool = { tolerance in
                if self.secondControlPointKnobBounds.insetBy(dx: -tolerance, dy: -tolerance).contains(location) {
                    self.adjustingSecondControlPoint = true
                    self.firstControlPointKnobIsOnTop = false
                    return true
                }
                return false
            }
            
            if firstControlPointKnobIsOnTop {
                if checkFirstControl(0) { return }
                if checkSecondControl(0) { return }
                if checkFirstControl(10) { return }
                if checkSecondControl(10) { return }
            } else {
                if checkSecondControl(0) { return }
                if checkFirstControl(0) { return }
                if checkSecondControl(10) { return }
                if checkFirstControl(10) { return }
            }
            
        } else if gestureRecognizer.state == .Changed {
            if adjustingFirstControlPoint || adjustingSecondControlPoint {
                let location = gestureRecognizer.locationInView(self)
                let relativePoint = CGPoint(x: (location.x - squareBounds.minX)/squareBounds.width, y: (location.y - squareBounds.minY)/squareBounds.height)
                
                let restrictedPoint = CGPoint(x: max(min(relativePoint.x, 1), 0), y: max(min(relativePoint.y, 1), 0))
                
                if adjustingFirstControlPoint {
                    firstControlPoint = restrictedPoint
                } else if adjustingSecondControlPoint {
                    secondControlPoint = restrictedPoint
                }
            }
        } else if gestureRecognizer.state == .Cancelled || gestureRecognizer.state == .Ended {
            adjustingFirstControlPoint = false
            adjustingSecondControlPoint = false
        }
    }
    
    private var squareBounds:CGRect {
        let length = min(bounds.width, bounds.height)
        
        let squareSize = CGSize(width: length, height: length)
        let rect = CGRect(origin: CGPoint(x: (bounds.width - length)/2, y: (bounds.height - length)/2), size: squareSize).integral
        return rect
    }
    
    private func controlPointsForRect(rect:CGRect) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let cp1x = firstControlPoint.x * rect.width + rect.minX
        let cp1y = firstControlPoint.y * rect.height + rect.minY
        let cp2x = secondControlPoint.x * rect.width + rect.minX
        let cp2y = secondControlPoint.y * rect.height + rect.minY
        return (cp1x, cp1y, cp2x, cp2y)
    }

    private var firstControlPointKnobBounds:CGRect {
        let (cp1x, cp1y, _, _) = controlPointsForRect(squareBounds)
        return CGRect(origin: CGPointMake(cp1x, cp1y), size: CGSizeZero).insetBy(dx: -controlPointKnobDiameter, dy: -controlPointKnobDiameter).integral
    }
    
    private var secondControlPointKnobBounds:CGRect {
        let (_, _, cp2x, cp2y) = controlPointsForRect(squareBounds)
        return CGRect(origin: CGPointMake(cp2x, cp2y), size: CGSizeZero).insetBy(dx: -controlPointKnobDiameter, dy: -controlPointKnobDiameter).integral
    }
    
    override public func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        let rect = squareBounds
        
        if let backgroundColor = backgroundColor {
            backgroundColor.setFill()
            NSRectFill(rect)
        }
        
        if drawsGrid {
            drawGrid(rect)
        }
        
        drawCurve(rect)
        
        drawHandles(rect)
    }
    
    private func drawGrid(rect: CGRect) {
        guard gridDivisions > 0 else { return }
        
        let subLength = rect.width / CGFloat(gridDivisions)
        guard let ctx = NSGraphicsContext.currentContext()?.CGContext else { return }
        CGContextSaveGState(ctx)
        CGContextSetStrokeColorWithColor(ctx, gridStrokeColor.CGColor)
        CGContextSetLineWidth(ctx, gridLineWidth)
        CGContextStrokeRect(ctx, rect.insetBy(dx: gridLineWidth / 2, dy: gridLineWidth / 2))
        
        for i in 1..<gridDivisions {
            let offset = CGFloat(i) * subLength
            CGContextMoveToPoint(ctx, rect.minX + offset, rect.minY)
            CGContextAddLineToPoint(ctx, rect.minX + offset, rect.maxY)
            CGContextStrokePath(ctx)
            
            CGContextMoveToPoint(ctx, rect.minX, rect.minY + offset)
            CGContextAddLineToPoint(ctx, rect.maxY + rect.height, rect.minY  + offset)
            CGContextStrokePath(ctx)
        }
        CGContextRestoreGState(ctx)
    }
    
    private func drawCurve(rect: CGRect) {
        guard let ctx = NSGraphicsContext.currentContext()?.CGContext else { return }
        CGContextSaveGState(ctx)
        CGContextSetStrokeColorWithColor(ctx, curveStrokeColor.CGColor)
        CGContextSetLineWidth(ctx, curveLineWidth)
        CGContextMoveToPoint(ctx, rect.minX, rect.minY)
        let (cp1x, cp1y, cp2x, cp2y) = controlPointsForRect(rect)
        CGContextAddCurveToPoint(ctx, cp1x, cp1y, cp2x, cp2y, rect.maxX, rect.maxY)
        CGContextStrokePath(ctx)
        CGContextRestoreGState(ctx)
    }
    
    private func drawHandles(rect:CGRect) {
        guard let ctx = NSGraphicsContext.currentContext()?.CGContext else { return }
        CGContextSaveGState(ctx)
        
        let (cp1x, cp1y, cp2x, cp2y) = controlPointsForRect(rect)
        
        let drawFirstHandle = {
            CGContextSetStrokeColorWithColor(ctx, self.handleStrokeColor.CGColor)
            CGContextSetLineWidth(ctx, self.handleLineWidth)
            CGContextMoveToPoint(ctx, rect.minX, rect.minY)
            CGContextAddLineToPoint(ctx, cp1x, cp1y)
            CGContextStrokePath(ctx)
            
            let firstControlPointKnobBounds = self.firstControlPointKnobBounds
            
            CGContextSetFillColorWithColor(ctx, self.firstControlPointKnobFillColor.CGColor)
            CGContextFillEllipseInRect(ctx, firstControlPointKnobBounds)
            CGContextSetStrokeColorWithColor(ctx, self.firstControlPointKnobStrokeColor.CGColor)
            CGContextSetLineWidth(ctx, self.firstControlPointKnobLineWidth)
            CGContextStrokeEllipseInRect(ctx, firstControlPointKnobBounds)
        }
        
        let drawSecondHandle = {
            CGContextSetStrokeColorWithColor(ctx, self.handleStrokeColor.CGColor)
            CGContextSetLineWidth(ctx, self.handleLineWidth)
            CGContextMoveToPoint(ctx, rect.maxX, rect.maxY)
            CGContextAddLineToPoint(ctx, cp2x, cp2y)
            CGContextStrokePath(ctx)

            let secondControlPointKnobBounds = self.secondControlPointKnobBounds
            CGContextSetFillColorWithColor(ctx, self.secondControlPointKnobFillColor.CGColor)
            CGContextFillEllipseInRect(ctx, secondControlPointKnobBounds)
            CGContextSetStrokeColorWithColor(ctx, self.secondControlPointKnobStrokeColor.CGColor)
            CGContextSetLineWidth(ctx, self.secondControlPointKnobLineWidth)
            CGContextStrokeEllipseInRect(ctx, secondControlPointKnobBounds)
            
        }

        if firstControlPointKnobIsOnTop {
            drawSecondHandle()
            drawFirstHandle()
        } else {
            drawFirstHandle()
            drawSecondHandle()
        }
        
        CGContextRestoreGState(ctx)
    }
}
