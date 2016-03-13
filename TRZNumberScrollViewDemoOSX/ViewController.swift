//
//  ViewController.swift
//  TRZNumberScrollViewDemoOSX
//
//  Created by Thomas Zhao on 3/11/16.
//  Copyright © 2016 Thomas Zhao. All rights reserved.
//

import Cocoa

class ViewController: NSSplitViewController, NumberScrollViewParametersViewControllerDelegate {

    var numberScrollViewContainer:NumberScrollViewContainerViewController!
    var parametersViewController:NumberScrollViewParametersViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberScrollViewContainer = splitViewItems[0].viewController as? NumberScrollViewContainerViewController
        parametersViewController = splitViewItems[1].viewController as? NumberScrollViewParametersViewController
        parametersViewController.delegate = self
        let numberScrollView = numberScrollViewContainer.numberScrollView
        numberScrollView.text = parametersViewController.text
        numberScrollView.animationDuration = parametersViewController.animationDuration
        numberScrollView.animationCurve = parametersViewController.animationCurve
        numberScrollView.setFont(parametersViewController.font, textColor: parametersViewController.textColor)
    }
    
    func parametersViewControllerDidCommit(sender: NumberScrollViewParametersViewController) {
        numberScrollViewContainer.numberScrollView.setText(parametersViewController.text, animated: parametersViewController.animationEnabled, direction: parametersViewController.animationDirection)
    }
    
    func parametersViewController(sender: NumberScrollViewParametersViewController, didChangeAnimationCurve animationCurve: CAMediaTimingFunction) {
        numberScrollViewContainer.numberScrollView.animationCurve = animationCurve
    }

    func parametersViewController(sender: NumberScrollViewParametersViewController, didChangeAnimationDuration animationDuration: NSTimeInterval) {
        numberScrollViewContainer.numberScrollView.animationDuration = animationDuration
    }
    
    func parametersViewController(sender: NumberScrollViewParametersViewController, didChangeFont font: NSFont) {
        numberScrollViewContainer.numberScrollView.font = font
    }
        
    func parametersViewController(sender: NumberScrollViewParametersViewController, didChangeTextColor textColor: NSColor) {
        numberScrollViewContainer.numberScrollView.textColor = textColor
    }
}


class NumberScrollViewContainerViewController: NSViewController {
    @IBOutlet weak var numberScrollView: NumberScrollView!
    @IBOutlet var backgroundColorView: BackgroundColorView!
    
    override func viewDidLoad() {
        backgroundColorView.backgroundColor = NSColor.whiteColor()
    }
}

class BackgroundColorView: NSView {
    var backgroundColor:NSColor? {
        didSet {
            needsDisplay = true
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        backgroundColor?.setFill()
        NSRectFill(bounds)
    }
}
