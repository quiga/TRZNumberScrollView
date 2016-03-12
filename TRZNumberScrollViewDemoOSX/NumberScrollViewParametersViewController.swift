//
//  NumberScrollViewParametersViewController.swift
//  TRZNumberScrollViewDemoOSX
//
//  Created by Thomas Zhao on 3/11/16.
//  Copyright © 2016 Thomas Zhao. All rights reserved.
//

import Cocoa

@objc protocol NumberScrollViewParametersViewControllerDelegate {
    optional func parametersViewController(sender:NumberScrollViewParametersViewController, didChangeAnimationEnabled animationEnabled:Bool)
    optional func parametersViewController(sender:NumberScrollViewParametersViewController, didChangeAnimationDuration animationDuration:NSTimeInterval)
    optional func parametersViewController(sender:NumberScrollViewParametersViewController, didChangeAnimationCurve animationCurve:CAMediaTimingFunction)
    optional func parametersViewController(sender:NumberScrollViewParametersViewController, didChangeText text:String)
    optional func parametersViewController(sender:NumberScrollViewParametersViewController, didChangeFont font:NSFont)
    optional func parametersViewController(sender:NumberScrollViewParametersViewController, didChangeTextColor textColor:NSColor)
    optional func parametersViewController(sender:NumberScrollViewParametersViewController, didChangeAnimationDirection animationDirection:NumberScrollView.AnimationDirection)
    optional func parametersViewControllerDidCommit(sender:NumberScrollViewParametersViewController)
}

class NumberScrollViewParametersViewController: NSViewController, NSControlTextEditingDelegate {

    @IBOutlet weak var animationCurveEditorView: AnimationCurveEditorView!
    @IBOutlet weak var upDirectionButton: NSButton!
    @IBOutlet weak var downDirectionButton: NSButton!
    
    weak var delegate:NumberScrollViewParametersViewControllerDelegate?
    
    dynamic var animationEnabled:Bool = true {
        didSet {
            if oldValue != animationEnabled {
                delegate?.parametersViewController?(self, didChangeAnimationEnabled: animationEnabled)
            }
        }
    }

    dynamic var text:String = "123456" {
        didSet {
            if oldValue != text {
                delegate?.parametersViewController?(self, didChangeText: text)
                if automaticallyCommit {
                    commit()
                }
            }
        }
    }
    
    dynamic var animationDuration:NSTimeInterval = 1.0 {
        didSet {
            if oldValue != animationDuration {
                delegate?.parametersViewController?(self, didChangeAnimationDuration: animationDuration)
            }
        }
    }
    
    private dynamic var curvePoint1x:Float = 0 {
        didSet {
            if oldValue != curvePoint1x {
                updateEditorViewControlPoints()
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }
    
    private dynamic var curvePoint1y:Float = 0 {
        didSet {
            if oldValue != curvePoint1y {
                updateEditorViewControlPoints()
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }
    
    private dynamic var curvePoint2x:Float = 0.1 {
        didSet {
            if oldValue != curvePoint2x {
                updateEditorViewControlPoints()
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }
    
    private dynamic var curvePoint2y:Float = 1 {
        didSet {
            if oldValue != curvePoint2y {
                updateEditorViewControlPoints()
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }
    
    dynamic var font:NSFont = NSFont.systemFontOfSize(NSFont.systemFontSize()) {
        didSet {
            if oldValue != font {
                delegate?.parametersViewController?(self, didChangeFont: font)
            }
        }
    }
    
    private dynamic var displayFont:NSFont = NSFont.systemFontOfSize(NSFont.systemFontSize())
    
    dynamic var textColor:NSColor = NSColor.blackColor() {
        didSet {
            if oldValue != textColor {
                delegate?.parametersViewController?(self, didChangeTextColor: textColor)
            }
        }
    }
    
    var animationDirection:NumberScrollView.AnimationDirection = .Up {
        didSet {
            if oldValue != animationDirection {
                delegate?.parametersViewController?(self, didChangeAnimationDirection: animationDirection)
            }
        }
    }
    
    var animationCurve:CAMediaTimingFunction {
        return CAMediaTimingFunction(controlPoints: curvePoint1x, curvePoint1y, curvePoint2x, curvePoint2y)
    }
    
    dynamic var automaticallyCommit:Bool = true
    
    
    dynamic var firstControlPoint = CGPointZero {
        didSet {
            if oldValue != firstControlPoint {
                curvePoint1x = Float(firstControlPoint.x)
                curvePoint1y = Float(firstControlPoint.y)
            }
        }
    }
    
    dynamic var secondControlPoint = CGPointZero {
        didSet {
            if oldValue != secondControlPoint {
                curvePoint2x = Float(secondControlPoint.x)
                curvePoint2y = Float(secondControlPoint.y)
            }
        }
    }
    
    func updateEditorViewControlPoints() {
        animationCurveEditorView.firstControlPoint = CGPoint(x: CGFloat(curvePoint1x), y: CGFloat(curvePoint1y))
        animationCurveEditorView.secondControlPoint = CGPoint(x: CGFloat(curvePoint2x), y: CGFloat(curvePoint2y))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateEditorViewControlPoints()
        bind("firstControlPoint", toObject: animationCurveEditorView, withKeyPath: "firstControlPoint", options: nil)
        bind("secondControlPoint", toObject: animationCurveEditorView, withKeyPath: "secondControlPoint", options: nil)
    }
    
    func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let val = control.stringValue

        if val.isEmpty {
            return false
        }
        
        return true
    }
    
    @IBAction func didChangeDirectionRadioButton(sender: NSButton) {
        animationDirection = (upDirectionButton.state == NSOnState) ? .Up : .Down
    }
    
    @IBAction func didClickSetFont(sender: NSButton) {
        let fontManager = NSFontManager.sharedFontManager()
        fontManager.target = self
        fontManager.setSelectedFont(self.font, isMultiple: false)
        fontManager.orderFrontFontPanel(self)
    }
    
    override func changeFont(sender: AnyObject?) {
        font = sender?.convertFont(font) ?? NSFont.systemFontOfSize(NSFont.systemFontSize())
        displayFont = NSFont(descriptor: font.fontDescriptor, size: NSFont.systemFontSize())!
    }
    
    func changeAttributes(sender: AnyObject?) {
        textColor = (sender?.convertAttributes([String: AnyObject]())["NSColor"] as? NSColor) ?? NSColor.blackColor()
    }
    
    @IBAction func didClickUpdate(sender: NSButton) {
        commit()
    }
    
    @IBAction func didPressEnterOnTextField(sender: NSTextField) {
        commit()
    }
    
    func commit() {
        delegate?.parametersViewControllerDidCommit?(self)
    }
}


@objc(TRZFontNameValueTransformer) class FontNameValueTransformer: NSValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        guard let font = value as? NSFont else { return nil }
        
        return String(format: "%@ %.1fpt", font.displayName ?? "(null)", font.pointSize)
    }
}