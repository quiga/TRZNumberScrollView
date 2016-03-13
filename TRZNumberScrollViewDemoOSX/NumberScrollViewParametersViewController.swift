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
    
    dynamic var startControlPoint:ObservablePoint = ObservablePoint(x: 0, y: 0) {
        didSet {
            if oldValue != startControlPoint {
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }
    
    dynamic var endControlPoint:ObservablePoint = ObservablePoint(x: 0.1, y: 1)  {
        didSet {
            if oldValue != endControlPoint {
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
        return CAMediaTimingFunction(controlPoints: Float(startControlPoint.x), Float(startControlPoint.y), Float(endControlPoint.x), Float(endControlPoint.y))
    }
    
    dynamic var automaticallyCommit:Bool = true
    
    func configureAnimationCurveEditor() {
        animationCurveEditor.startControlPointValue = self.startControlPoint.pointValue
        animationCurveEditor.endControlPointValue = self.endControlPoint.pointValue
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAnimationCurveEditor();
        
        animationCurveEditor.bind("enabled", toObject: self, withKeyPath: "animationEnabled", options: nil)
        let toNSValueOptions = [NSValueTransformerBindingOption: ObservablePointToNSValueTransformer()]
        bind("startControlPoint", toObject: animationCurveEditor, withKeyPath: "startControlPointValue", options: toNSValueOptions)
        bind("endControlPoint", toObject: animationCurveEditor, withKeyPath: "endControlPointValue", options: toNSValueOptions)
    }
    
    @IBAction private func didEndEditingPointTextField(sender: NSTextField) {
        configureAnimationCurveEditor()
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

class ObservablePointToNSValueTransformer: NSValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSValue.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        if let point = value as? ObservablePoint {
            return NSValue(point:CGPoint(x:point.x , y: point.y))
        } else if let point = (value as? NSValue)?.pointValue {
            return ObservablePoint(x: point.x, y: point.y)
        }
        return nil
    }
}

class ObservablePoint:NSObject {
    dynamic var x:CGFloat = 0
    dynamic var y:CGFloat = 0
    
    init(x:CGFloat, y:CGFloat) {
        self.x = x
        self.y = y
    }
    
    var pointValue:CGPoint {
        return CGPoint(x: x, y: y)
    }
}