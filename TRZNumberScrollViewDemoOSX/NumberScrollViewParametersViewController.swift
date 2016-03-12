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

    @IBOutlet weak var animationCurveEditor: AnimationCurveEditor!
    @IBOutlet weak var upDirectionButton: NSButton!
    @IBOutlet weak var downDirectionButton: NSButton!
    
    weak var delegate:NumberScrollViewParametersViewControllerDelegate?
    
    private(set) dynamic var animationEnabled:Bool = true {
        didSet {
            if oldValue != animationEnabled {
                delegate?.parametersViewController?(self, didChangeAnimationEnabled: animationEnabled)
            }
        }
    }

    private(set) dynamic var text:String = "123456" {
        didSet {
            if oldValue != text {
                delegate?.parametersViewController?(self, didChangeText: text)
                if automaticallyCommit {
                    commit()
                }
            }
        }
    }
    
    private(set) dynamic var animationDuration:NSTimeInterval = 1.0 {
        didSet {
            if oldValue != animationDuration {
                delegate?.parametersViewController?(self, didChangeAnimationDuration: animationDuration)
            }
        }
    }
    
    private dynamic var curvePoint1x:CGFloat = 0 {
        didSet {
            if oldValue != curvePoint1x {
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }
    
    private dynamic var curvePoint1y:CGFloat = 0 {
        didSet {
            if oldValue != curvePoint1y {
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }
    
    private dynamic var curvePoint2x:CGFloat = 0.1 {
        didSet {
            if oldValue != curvePoint2x {
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }
    
    private dynamic var curvePoint2y:CGFloat = 1 {
        didSet {
            if oldValue != curvePoint2y {
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }
    
    private(set) dynamic var font:NSFont = NSFont.systemFontOfSize(48) {
        didSet {
            if oldValue != font {
                delegate?.parametersViewController?(self, didChangeFont: font)
            }
        }
    }
    
    private dynamic var displayFont:NSFont = NSFont.systemFontOfSize(NSFont.systemFontSize())
    
    private(set) dynamic var textColor:NSColor = NSColor.blackColor() {
        didSet {
            if oldValue != textColor {
                delegate?.parametersViewController?(self, didChangeTextColor: textColor)
            }
        }
    }
    
    private(set) var animationDirection:NumberScrollView.AnimationDirection = .Up {
        didSet {
            if oldValue != animationDirection {
                delegate?.parametersViewController?(self, didChangeAnimationDirection: animationDirection)
            }
        }
    }
    
    var animationCurve:CAMediaTimingFunction {
        return CAMediaTimingFunction(controlPoints: Float(curvePoint1x), Float(curvePoint1y), Float(curvePoint2x), Float(curvePoint2y))
    }
    
    dynamic var automaticallyCommit:Bool = true
    
    private func updateAnimationEditorCurves() {
        animationCurveEditor.startControlPointValue = CGPointMake(curvePoint1x, curvePoint1y)
        animationCurveEditor.endControlPointValue = CGPointMake(curvePoint2x, curvePoint2y)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateAnimationEditorCurves()
        animationCurveEditor.bind("enabled", toObject: self, withKeyPath: "animationEnabled", options: nil)
        animationCurveEditor.target = self
        animationCurveEditor.action = Selector("animationCurveEditorDidUpdate:")
    }
    
    @objc private func animationCurveEditorDidUpdate(sender: AnimationCurveEditor) {
        curvePoint1x = sender.startControlPointValue.x
        curvePoint1y = sender.startControlPointValue.y
        curvePoint2x = sender.endControlPointValue.x
        curvePoint2y = sender.endControlPointValue.y
    }
    
    @IBAction private func curvePointBoxDidEndEditing(sender: NSTextField) {
        updateAnimationEditorCurves()
    }
    
    @objc func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let val = control.stringValue

        if val.isEmpty {
            return false
        }
        
        return true
    }
    
    @IBAction private func didChangeDirectionRadioButton(sender: NSButton) {
        animationDirection = (upDirectionButton.state == NSOnState) ? .Up : .Down
    }
    
    @IBAction private func didClickSetFont(sender: NSButton) {
        let fontManager = NSFontManager.sharedFontManager()
        fontManager.target = self
        fontManager.setSelectedFont(self.font, isMultiple: false)
        fontManager.orderFrontFontPanel(self)
    }
    
    override func changeFont(sender: AnyObject?) {
        font = sender?.convertFont(font) ?? NSFont.systemFontOfSize(NSFont.systemFontSize())
        displayFont = NSFont(descriptor: font.fontDescriptor, size: NSFont.systemFontSize())!
    }
    
    private func changeAttributes(sender: AnyObject?) {
        textColor = (sender?.convertAttributes([String: AnyObject]())["NSColor"] as? NSColor) ?? NSColor.blackColor()
    }
    
    @IBAction private func didClickUpdate(sender: NSButton) {
        commit()
    }
    
    @IBAction private func didPressEnterOnTextField(sender: NSTextField) {
        commit()
    }
    
    private func commit() {
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