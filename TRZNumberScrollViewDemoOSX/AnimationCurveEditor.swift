//
//  AnimationCurveEditor.swift
//  TRZNumberScrollViewDemoOSX
//
//  Created by Thomas Zhao on 3/11/16.
//  Copyright © 2016 Thomas Zhao. All rights reserved.
//

import Cocoa

public class AnimationCurveEditor: NSControl {
    public var backgroundColor:NSColor? = NSColor.whiteColor() {
        didSet { needsDisplay = true }
    }
    
    public var drawsGrid = true {
        didSet { needsDisplay = true }
    }
    
    public var gridDivisions:Int = 10 {
        didSet { needsDisplay = true }
    }
    
    public var gridStrokeColor = NSColor.gridColor() {
        didSet { needsDisplay = true }
    }
    
    public var gridLineWidth:CGFloat = 1 {
        didSet { needsDisplay = true }
    }
    
    public var curveStrokeColor:NSColor = NSColor(forControlTint: .BlueControlTint) {
        didSet { needsDisplay = true }
    }
    
    public var curveLineWidth:CGFloat = 2 {
        didSet { needsDisplay = true }
    }
    
    public var handleStrokeColor:NSColor = NSColor.grayColor() {
        didSet { needsDisplay = true }
    }
    
    public var handleLineWidth:CGFloat = 2 {
        didSet { needsDisplay = true }
    }

    dynamic public var startControlPointValue:CGPoint = CGPointMake(0, 0) {
        didSet { needsDisplay = true }
    }
    
    public var startControlPointKnobFillColor:NSColor = NSColor.whiteColor() {
        didSet { needsDisplay = true }
    }

    public var startControlPointKnobLineWidth:CGFloat = 2 {
        didSet { needsDisplay = true }
    }

    public var startControlPointKnobStrokeColor:NSColor = NSColor.redColor() {
        didSet { needsDisplay = true }
    }
    
    dynamic public var endControlPointValue:CGPoint = CGPointMake(1, 1) {
        didSet { needsDisplay = true }
    }
    
    public var endControlPointKnobLineWidth:CGFloat = 2 {
        didSet { needsDisplay = true }
    }

    public var endControlPointKnobFillColor:NSColor = NSColor.whiteColor() {
        didSet { needsDisplay = true }
    }

    public var endControlPointKnobStrokeColor:NSColor = NSColor.blueColor() {
        didSet { needsDisplay = true }
    }
    
    public var controlPointKnobDiameter:CGFloat = 5 {
        didSet { needsDisplay = true }
    }
    
    override public var enabled:Bool {
        didSet { panGestureRecognizer.enabled = enabled }
    }
    
    private var _target:AnyObject?
    private var _action:Selector = nil
    private var panGestureRecognizer = NSPanGestureRecognizer();

    override public var target:AnyObject? {
        get { return _target }
        set { _target = newValue }
    }
    
    override public var action:Selector {
        get { return _action }
        set { _action = newValue }
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
        panGestureRecognizer.target = self
        panGestureRecognizer.action = Selector("panGestureRecognizerDidRecognize:")
        addGestureRecognizer(panGestureRecognizer)
    }
    
    private var startControlPointKnobIsOnTop = true
    
    private var adjustingStartControlPoint:Bool = false
    private var adjustingEndControlPoint:Bool = false
    
    @objc private func panGestureRecognizerDidRecognize(gestureRecognizer:NSPanGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            let location = gestureRecognizer.locationInView(self)
            let checkStartControl:(CGFloat)->Bool = { tolerance in
                if self.startControlPointKnobBounds.insetBy(dx: -tolerance, dy: -tolerance).contains(location) {
                    self.adjustingStartControlPoint = true
                    self.startControlPointKnobIsOnTop = true
                    return true
                }
                return false
            }
            
            let checkEndControl:(CGFloat)->Bool = { tolerance in
                if self.endControlPointKnobBounds.insetBy(dx: -tolerance, dy: -tolerance).contains(location) {
                    self.adjustingEndControlPoint = true
                    self.startControlPointKnobIsOnTop = false
                    return true
                }
                return false
            }
            
            if startControlPointKnobIsOnTop {
                if checkStartControl(0) { return }
                if checkEndControl(0) { return }
                if checkStartControl(10) { return }
                if checkEndControl(10) { return }
            } else {
                if checkEndControl(0) { return }
                if checkStartControl(0) { return }
                if checkEndControl(10) { return }
                if checkStartControl(10) { return }
            }
            
        } else if gestureRecognizer.state == .Changed {
            if adjustingStartControlPoint || adjustingEndControlPoint {
                let location = gestureRecognizer.locationInView(self)
                let relativePoint = CGPoint(x: (location.x - squareBounds.minX)/squareBounds.width, y: (location.y - squareBounds.minY)/squareBounds.height)
                
                let restrictedPoint = CGPoint(x: max(min(relativePoint.x, 1), 0), y: max(min(relativePoint.y, 1), 0))
                
                if adjustingStartControlPoint {
                    startControlPointValue = restrictedPoint
                } else if adjustingEndControlPoint {
                    endControlPointValue = restrictedPoint
                }
                
                sendAction(action, to: target)
            }
        } else if gestureRecognizer.state == .Cancelled || gestureRecognizer.state == .Ended {
            adjustingStartControlPoint = false
            adjustingEndControlPoint = false
        }
    }
    
    private var squareBounds:CGRect {
        let length = min(bounds.width, bounds.height)
        
        let squareSize = CGSize(width: length, height: length)
        let rect = CGRect(origin: CGPoint(x: (bounds.width - length)/2, y: (bounds.height - length)/2), size: squareSize).integral
        return rect
    }
    
    private func controlPointsForRect(rect:CGRect) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let cp1x = startControlPointValue.x * rect.width + rect.minX
        let cp1y = startControlPointValue.y * rect.height + rect.minY
        let cp2x = endControlPointValue.x * rect.width + rect.minX
        let cp2y = endControlPointValue.y * rect.height + rect.minY
        return (cp1x, cp1y, cp2x, cp2y)
    }

    private var startControlPointKnobBounds:CGRect {
        let (cp1x, cp1y, _, _) = controlPointsForRect(squareBounds)
        return CGRect(origin: CGPointMake(cp1x, cp1y), size: CGSizeZero).insetBy(dx: -controlPointKnobDiameter, dy: -controlPointKnobDiameter).integral
    }
    
    private var endControlPointKnobBounds:CGRect {
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
        
        let drawStartHandle = {
            CGContextSetStrokeColorWithColor(ctx, self.handleStrokeColor.CGColor)
            CGContextSetLineWidth(ctx, self.handleLineWidth)
            CGContextMoveToPoint(ctx, rect.minX, rect.minY)
            CGContextAddLineToPoint(ctx, cp1x, cp1y)
            CGContextStrokePath(ctx)
            
            let startControlPointKnobBounds = self.startControlPointKnobBounds
            
            CGContextSetFillColorWithColor(ctx, self.startControlPointKnobFillColor.CGColor)
            CGContextFillEllipseInRect(ctx, startControlPointKnobBounds)
            let strokeColor = self.enabled ? self.startControlPointKnobStrokeColor : NSColor.disabledControlTextColor()
            CGContextSetStrokeColorWithColor(ctx, strokeColor.CGColor)
            CGContextSetLineWidth(ctx, self.startControlPointKnobLineWidth)
            CGContextStrokeEllipseInRect(ctx, startControlPointKnobBounds)
        }
        
        let drawEndHandle = {
            CGContextSetStrokeColorWithColor(ctx, self.handleStrokeColor.CGColor)
            CGContextSetLineWidth(ctx, self.handleLineWidth)
            CGContextMoveToPoint(ctx, rect.maxX, rect.maxY)
            CGContextAddLineToPoint(ctx, cp2x, cp2y)
            CGContextStrokePath(ctx)

            let endControlPointKnobBounds = self.endControlPointKnobBounds
            CGContextSetFillColorWithColor(ctx, self.endControlPointKnobFillColor.CGColor)
            CGContextFillEllipseInRect(ctx, endControlPointKnobBounds)
            let strokeColor = self.enabled ? self.endControlPointKnobStrokeColor : NSColor.disabledControlTextColor()
            CGContextSetStrokeColorWithColor(ctx, strokeColor.CGColor)
            CGContextSetLineWidth(ctx, self.endControlPointKnobLineWidth)
            CGContextStrokeEllipseInRect(ctx, endControlPointKnobBounds)
        }

        if startControlPointKnobIsOnTop {
            drawEndHandle()
            drawStartHandle()
        } else {
            drawStartHandle()
            drawEndHandle()
        }
        
        CGContextRestoreGState(ctx)
    }
}
