#if os(OSX)
    import AppKit
    
    public typealias TRZImage = NSImage
    public typealias TRZFont = NSFont
    public typealias TRZColor = NSColor
    public typealias TRZView = NSView
#elseif os(iOS) || os(tvOS)
    import UIKit
    
    public typealias TRZImage = UIImage
    public typealias TRZFont = UIFont
    public typealias TRZColor = UIColor
    public typealias TRZView = UIView
#endif

public class NumberScrollView: TRZView {
    public typealias AnimationDirection = NumberScrollLayer.AnimationDirection
    
    public enum ImageCachePolicy {
        case Never
        case Global
        case Custom(NumberScrollLayerImageCache)
    }
    
    public var text:String {
        get { return numberScrollLayer.text }
        set {
            let oldSize = numberScrollLayer.boundingSize
            numberScrollLayer.text = newValue
            if (numberScrollLayer.boundingSize != oldSize) {
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    public func setText(text:String, animated:Bool, direction:AnimationDirection, completion:(()->Void)? = nil) {
        self.text = text
        if animated {
            self.numberScrollLayer.playScrollAnimation(direction, completion: completion)
        } else {
            completion?()
        }
    }
    
    public func setFont(font: TRZFont, textColor:TRZColor) {
        let oldSize = numberScrollLayer.boundingSize
        numberScrollLayer.setFont(font, textColor: textColor)
        if (numberScrollLayer.boundingSize != oldSize) {
            invalidateIntrinsicContentSize()
        }
    }
    
    public var textColor:TRZColor {
        get { return numberScrollLayer.textColor }
        set { numberScrollLayer.textColor = newValue }
    }
    
    public var font:TRZFont {
        get { return numberScrollLayer.font }
        set {
            let oldSize = numberScrollLayer.boundingSize
            numberScrollLayer.font = newValue
            if (numberScrollLayer.boundingSize != oldSize) {
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    public var animationDuration:NSTimeInterval {
        get { return numberScrollLayer.animationDuration }
        set { numberScrollLayer.animationDuration = newValue }
    }
    
    public var animationCurve:CAMediaTimingFunction {
        get { return numberScrollLayer.animationCurve }
        set { numberScrollLayer.animationCurve = newValue }
    }
    
    public var imageCachePolicy:ImageCachePolicy = {
        #if os(OSX)
            return .Never
        #elseif os(iOS) || os(tvOS)
            return .Global
        #endif
        }() {
        didSet {
            configureImageCache()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        #if os(OSX)
            let layer = CALayer()
            self.layer = layer
            self.wantsLayer = true
            layer.delegate = self
        #elseif os(iOS) || os(tvOS)
            let layer = self.layer
        #endif
        layer.addSublayer(numberScrollLayer)
        configureImageCache()
    }
    
    private var numberScrollLayer = NumberScrollLayer()
    
    private func configureImageCache() {
        switch imageCachePolicy {
        case .Never: numberScrollLayer.imageCache = nil
        case .Global: numberScrollLayer.imageCache = NumberScrollLayer.globalImageCache
        case let .Custom(imageCache): numberScrollLayer.imageCache = imageCache
        }
    }
    
    public override func layoutSublayersOfLayer(layer: CALayer) {
        let innerSize = numberScrollLayer.boundingSize
        let outerRect = layer.bounds
        let centerOrigin = CGPoint(x: outerRect.origin.x + (outerRect.size.width - innerSize.width) / 2, y: outerRect.origin.y + (outerRect.size.height - innerSize.height) / 2)
        
        numberScrollLayer.frame = CGRectIntegral(CGRect(origin: centerOrigin, size: innerSize))
    }
    
    #if os(OSX)
    override public var intrinsicContentSize:CGSize {
        return numberScrollLayer.boundingSize
    }
    override public var flipped:Bool {
        return true
    }
    #elseif os(iOS) || os(tvOS)
    override public func intrinsicContentSize() -> CGSize {
    return numberScrollLayer.boundingSize
    }
    
    override public func sizeThatFits(size: CGSize) -> CGSize {
    return intrinsicContentSize()
    }
    #endif
}

public protocol AcquireRelinquishProtocol {
    typealias T
    func acquire() -> T
    func relinquish()
    var acquireCount:Int { get }
}

public class AcquireRelinquishBox<V>:AcquireRelinquishProtocol {
    public typealias T = V
    
    public init(value:V) {
        self.value = value
    }
    public func acquire() -> V {
        OSAtomicIncrement32(&_acquireCount)
        return value
    }
    public func relinquish() {
        OSAtomicDecrement32(&_acquireCount)
    }
    
    private var _acquireCount:Int32 = 1
    
    public var acquireCount:Int {
        return Int(_acquireCount)
    }
    private let value:V
}

public protocol NumberScrollLayerImageCache {
    func cachedImageBoxForKey(key: String, font:TRZFont, color:TRZColor) -> AcquireRelinquishBox<TRZImage>?
    func setImage(image:TRZImage, key:String, font:TRZFont, color:TRZColor) -> AcquireRelinquishBox<TRZImage>
    func evict()
}

private func ==(lhs:NumberScrollLayer.DefaultImageCache.CacheKey, rhs:NumberScrollLayer.DefaultImageCache.CacheKey) -> Bool {
    return lhs.key == rhs.key && lhs.font == rhs.font && lhs.color == rhs.color
}

public class NumberScrollLayer: CALayer {
    public init(imageCache:NumberScrollLayerImageCache?) {
        super.init()
        self.imageCache = imageCache
    }
    
    public override init() {
        super.init()
        self.imageCache = NumberScrollLayer.globalImageCache
    }
    
    public override init(layer: AnyObject) {
        super.init(layer: layer)
        if let layer = layer as? NumberScrollLayer {
            self.imageCache = layer.imageCache
            self.setFont(layer.font, textColor: layer.textColor)
            self.animationCurve = layer.animationCurve
            self.animationDuration = layer.animationDuration
            self.text = layer.text
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.imageCache = NumberScrollLayer.globalImageCache
        let selfName = String(NumberScrollLayer.self)
        let font = aDecoder.decodeObjectForKey(selfName + ".font") as! TRZFont
        let textColor = aDecoder.decodeObjectForKey(selfName + ".textColor") as! TRZColor
        self.setFont(font, textColor: textColor)
        
        self.text = aDecoder.decodeObjectForKey(selfName + ".text") as! String
        self.animationCurve = aDecoder.decodeObjectForKey(selfName + ".animationCurve")! as! CAMediaTimingFunction
        self.animationDuration = aDecoder.decodeDoubleForKey(selfName + ".animationDuration")
    }
    
    public override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        let selfName = String(NumberScrollLayer.self)
        aCoder.encodeObject(self.font, forKey: selfName + ".font")
        aCoder.encodeObject(self.textColor, forKey: selfName + ".textColor")
        aCoder.encodeObject(self.text, forKey: selfName + ".text")
        aCoder.encodeObject(self.animationCurve, forKey: selfName + ".animationCurve")
        aCoder.encodeDouble(self.animationDuration, forKey: selfName + ".animationDuration")
    }
    
    public class DefaultImageCache: NSObject, NumberScrollLayerImageCache {
        private lazy var queue:dispatch_queue_t = {
            let queueAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0)
            let queue = dispatch_queue_create(String(DefaultImageCache.self) + ".queue", queueAttr)
            return queue
        }()
        
        public override init() {
            super.init()
            
            #if !os(OSX)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "evict", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "evict", name: UIApplicationDidEnterBackgroundNotification, object: nil)
                if #available(iOSApplicationExtension 8.2, *) {
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: "evict", name: NSExtensionHostDidEnterBackgroundNotification, object: nil)
                }
            #endif
        }
        
        deinit {
            #if !os(OSX)
                NSNotificationCenter.defaultCenter().removeObserver(self)
            #endif
        }
        
        private lazy var cachedImages = [CacheKey: AcquireRelinquishBox<TRZImage>]()
        
        private struct CacheKey: Equatable, Hashable {
            var key:String
            var font:TRZFont
            var color:TRZColor
            var hashValue:Int {
                return key.hashValue ^ font.hashValue ^ color.hashValue
            }
        }
        
        @objc public func evict() {
            dispatch_async(queue) {
                for (key, value) in self.cachedImages {
                    if value.acquireCount <= 0 {
                        self.cachedImages.removeValueForKey(key)
                    }
                }
            }
        }
        
        public func cachedImageBoxForKey(key: String, font:TRZFont, color:TRZColor) -> AcquireRelinquishBox<TRZImage>? {
            var box:AcquireRelinquishBox<TRZImage>?
            let cacheKey = CacheKey(key: key, font: font, color: color)
            dispatch_sync(queue) {
                box = self.cachedImages[cacheKey]
            }
            return box
        }
        
        
        public func setImage(image:TRZImage, key:String, font:TRZFont, color:TRZColor) -> AcquireRelinquishBox<TRZImage> {
            let cacheKey = CacheKey(key: key, font: font, color: color)
            let newVal = AcquireRelinquishBox<TRZImage>(value: image)
            dispatch_sync(queue) {
                self.cachedImages[cacheKey] = newVal
            }
            return newVal
        }
        
    }
    
    static private let globalImageCache = DefaultImageCache()
    
    public var imageCache:NumberScrollLayerImageCache? {
        willSet {
            self.releaseCachedImages()
        }
    }
    
    public func setFont(font:TRZFont, textColor:TRZColor) {
        _textColor = textColor
        self.font = font
    }
    
    public var text:String = "" {
        didSet {
            if text != oldValue {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                relayoutScrollLayers()
                setScrollLayerContents()
                CATransaction.commit()
            }
        }
    }
    
    private func releaseCachedCharacterImages() {
        for box in _cachedCharacterImageBoxes {
            box.relinquish()
        }
        _cachedCharacterImageBoxes.removeAll()
    }
    
    private func releaseCachedDigitsImage() {
        _cachedDigitsImageBox?.relinquish()
        _cachedDigitsImageBox = nil
        _digitsImage = nil
    }
    
    private var _cachedDigitsImageBox:AcquireRelinquishBox<TRZImage>?
    private lazy var _cachedCharacterImageBoxes = [AcquireRelinquishBox<TRZImage>]()
    
    private var _textColor:TRZColor = TRZColor.blackColor()
    public var textColor:TRZColor {
        get { return _textColor }
        set {
            if _textColor != newValue {
                releaseCachedImages()
                _textColor = newValue
                if (!text.isEmpty) {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    recolorScrollLayers()
                    CATransaction.commit()
                }
            }
        }
    }
    
    func releaseCachedImages() {
        releaseCachedCharacterImages()
        releaseCachedDigitsImage()
    }
    
    private var _font:TRZFont = TRZFont.systemFontOfSize(12).monospacedDigitsFont
    public var font:TRZFont {
        get { return _font }
        set {
            let newFont = newValue.monospacedDigitsFont
            if _font != newFont {
                releaseCachedImages()
                _font = newFont
                if (!text.isEmpty) {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    contentLayers.forEach({ $0.removeFromSuperlayer() })
                    contentLayers.removeAll()
                    relayoutScrollLayers()
                    setScrollLayerContents()
                    CATransaction.commit()
                }
            }
        }
    }
    
    public var animationDuration:NSTimeInterval = 1.0
    lazy public var animationCurve:CAMediaTimingFunction = CAMediaTimingFunction(controlPoints: 0, 0, 0.1, 1)
    
    private var _digitsImage:TRZImage?
    public var digitsImage:TRZImage! {
        if (_digitsImage == nil) {
            _digitsImage = createDigitsImage(self.font)
        }
        return _digitsImage
    }
    
    private var digitsImageIndividualDigitSize:CGSize {
        return CGSize(width: digitsImage.size.width, height: digitsImage.size.height / CGFloat(10) / CGFloat(repetitions))
    }
    
    private func fontAttributesForFont(font:TRZFont) -> [String: AnyObject] {
        let style = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        style.alignment = .Center
        style.lineBreakMode = .ByClipping
        style.lineSpacing = 0
        return [NSFontAttributeName: font, NSParagraphStyleAttributeName: style, NSForegroundColorAttributeName: textColor]
    }
    
    private let repetitions = 2
    
    private func createImageForNonDigit(character:Character, font:TRZFont) -> TRZImage {
        let cacheKey = String(self.dynamicType) + ".characters." + String(character)
        if let box = imageCache?.cachedImageBoxForKey(cacheKey, font: font, color: self.textColor) {
            _cachedCharacterImageBoxes.append(box)
            return box.acquire()
        }
        
        let str = String(character) as NSString
        let fontAttributes = fontAttributesForFont(font)
        let size = str.sizeWithAttributes(fontAttributes)
        
        var imageSize = digitsImageIndividualDigitSize
        imageSize.width = ceil(size.width)
        
        let drawingHandler = { (rect:CGRect) -> Bool in
            #if os(OSX)
                let ctx = NSGraphicsContext.currentContext()?.CGContext
            #elseif os(iOS) || os(tvOS)
                let ctx = UIGraphicsGetCurrentContext()
            #endif
            CGContextSetShouldSmoothFonts(ctx, false)
            str.drawInRect(CGRect(x: rect.origin.x, y: rect.origin.y + (imageSize.height - size.height) / 2, width: imageSize.width, height: size.height), withAttributes: fontAttributes)
            return true
        }
        
        #if os(OSX)
            let image = TRZImage(size: imageSize, flipped: true, drawingHandler: drawingHandler)
        #elseif os(iOS) || os(tvOS)
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            drawingHandler(CGRect(origin: CGPointZero, size: imageSize))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        #endif
        
        
        if let box = imageCache?.setImage(image, key: cacheKey, font: font, color: self.textColor) {
            _cachedCharacterImageBoxes.append(box)
        }
        
        return image
    }
    
    private func createDigitsImage(font:TRZFont) -> TRZImage {
        let cacheKey = String(self.dynamicType) + ".digits"
        if let box = imageCache?.cachedImageBoxForKey(cacheKey, font: font, color: self.textColor) {
            _cachedDigitsImageBox = box
            return box.acquire()
        }
        
        let fontAttributes = fontAttributesForFont(font)
        let repetitions = self.repetitions
        var maxSize = CGSizeZero
        
        let digits = (0...9).map({String($0)})
        
        for digit in digits {
            maxSize = maxSize.union((digit as NSString).sizeWithAttributes(fontAttributes))
        }
        
        maxSize = CGSize(width: ceil(maxSize.width), height: ceil(maxSize.height))
        
        let imageSize = CGSize(width: maxSize.width, height: maxSize.height * CGFloat(digits.count) * CGFloat(repetitions))
        
        let drawingHandler = { (rect:CGRect) -> Bool in
            #if os(OSX)
                let ctx = NSGraphicsContext.currentContext()?.CGContext
            #elseif os(iOS) || os(tvOS)
                let ctx = UIGraphicsGetCurrentContext()
            #endif
            CGContextSetShouldSmoothFonts(ctx, false)
            let individualHeight = maxSize.height
            var currentRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: imageSize.width, height: individualHeight))
            for _ in 0..<repetitions {
                for digit in digits {
                    (digit as NSString).drawInRect(currentRect, withAttributes: fontAttributes)
                    currentRect.origin.y += individualHeight
                }
            }
            return true
        }
        
        #if os(OSX)
            let image = TRZImage(size: imageSize, flipped: true, drawingHandler: drawingHandler)
        #elseif os(iOS) || os(tvOS)
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            drawingHandler(CGRect(origin: CGPointZero, size: imageSize))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        #endif
        
        if let box = imageCache?.setImage(image, key: cacheKey, font: font, color: self.textColor) {
            _cachedDigitsImageBox = box
        }
        
        return image
    }
    
    private var contentLayers = [CALayer]()
    
    public private(set) var boundingSize:CGSize = CGSizeZero
    
    private func recolorScrollLayers() {
        if contentLayers.count != text.characters.count {
            relayoutScrollLayers()
            setScrollLayerContents()
            return
        }
        
        var contentLayersIndex = contentLayers.startIndex
        var charactersIndex = text.characters.startIndex
        
        while charactersIndex < text.characters.endIndex {
            let char = text.characters[charactersIndex]
            if let _ = Int(String(char)) {
                let scrollLayer = contentLayers[contentLayersIndex]
                let contentsLayer = scrollLayer.sublayers![0]
                
                #if os(OSX)
                    contentsLayer.contents = digitsImage
                #elseif os(iOS) || os(tvOS)
                    contentsLayer.contents = digitsImage.CGImage
                #endif
            } else {
                let contentsLayer = contentLayers[contentLayersIndex]
                
                let needsVerticallyCenteredColon = needsVerticallyCenteredColonForCharacterAtIndex(charactersIndex, characters: text.characters)
                let font = needsVerticallyCenteredColon ? self.font.verticallyCenteredColonFont : self.font
                
                let image = createImageForNonDigit(char, font: font)
                
                #if os(OSX)
                    contentsLayer.contents = image
                #elseif os(iOS) || os(tvOS)
                    contentsLayer.contents = image.CGImage
                #endif
            }
            
            contentLayersIndex = contentLayersIndex.successor()
            charactersIndex = charactersIndex.successor()
        }
    }
    
    private func needsVerticallyCenteredColonForCharacterAtIndex(index:String.CharacterView.Index, characters:String.CharacterView) -> Bool {
        guard characters[index] == ":" else { return false }
        
        if index != characters.startIndex {
            let nextIndex = index.successor()
            let prevIndex = index.predecessor()
            if nextIndex != characters.endIndex {
                let prevChar = String(characters[prevIndex])
                let nextChar = String(characters[nextIndex])
                
                let prevCharIsDigit = Int(prevChar) != nil
                let nextCharIsDigit = Int(nextChar) != nil
                
                let isUpperCase = { (str:String) in str.uppercaseString == str && str.lowercaseString != str }
                
                if (prevCharIsDigit && nextCharIsDigit) ||
                    (prevCharIsDigit && isUpperCase(nextChar)) ||
                    (nextCharIsDigit && isUpperCase(prevChar)) {
                        return true
                }
            }
        }
        
        return false
    }
    
    private func relayoutScrollLayers() {
        let individualSize = digitsImageIndividualDigitSize
        
        var currentOrigin = CGPointZero
        var boundingSize = CGSizeZero
        
        
        let contentLayers = self.contentLayers
        var newLayers = [CALayer]()
        
        var contentLayersIndex = contentLayers.startIndex
        var charactersIndex = text.characters.startIndex
        
        while charactersIndex < text.characters.endIndex {
            let char = text.characters[charactersIndex]
            let currentLayer:CALayer? = (contentLayersIndex < contentLayers.endIndex) ? contentLayers[contentLayersIndex] : nil
            if let _ = Int(String(char)) {
                let scrollLayer:CALayer
                if currentLayer?.valueForKey("myContents") as? String == "digits" {
                    scrollLayer = currentLayer!
                    scrollLayer.removeAllAnimations()
                    scrollLayer.frame.origin = currentOrigin
                } else {
                    currentLayer?.removeFromSuperlayer()
                    
                    let contentsLayer = CALayer()
                    
                    #if os(OSX)
                        contentsLayer.contents = digitsImage
                    #elseif os(iOS) || os(tvOS)
                        contentsLayer.contents = digitsImage.CGImage
                    #endif
                    
                    contentsLayer.frame = CGRect(origin: CGPointZero, size: digitsImage.size)
                    contentsLayer.masksToBounds = true
                    
                    scrollLayer = CALayer()
                    scrollLayer.masksToBounds = true
                    scrollLayer.frame = CGRect(origin: currentOrigin, size: individualSize)
                    scrollLayer.addSublayer(contentsLayer)
                    scrollLayer.setValue("digits", forKey: "myContents")
                    
                    self.addSublayer(scrollLayer)
                }
                
                newLayers.append(scrollLayer)
                
                currentOrigin.x += scrollLayer.bounds.width
                boundingSize.width += scrollLayer.bounds.width
                boundingSize.height = max(boundingSize.height, scrollLayer.bounds.height)
            } else {
                let charLayer:CALayer
                
                let needsVerticallyCenteredColon = needsVerticallyCenteredColonForCharacterAtIndex(charactersIndex, characters: text.characters)
                let currentLayerMatches =
                currentLayer?.valueForKey("myContents") as? String == String(char) &&
                    currentLayer?.valueForKey("verticallyCenteredColon") as? Bool == needsVerticallyCenteredColon
                
                if currentLayerMatches {
                    charLayer = currentLayer!
                    charLayer.removeAllAnimations()
                    charLayer.frame.origin = currentOrigin
                } else {
                    currentLayer?.removeFromSuperlayer()
                    
                    charLayer = CALayer()
                    
                    let font = needsVerticallyCenteredColon ? self.font.verticallyCenteredColonFont : self.font
                    let image = createImageForNonDigit(char, font: font)
                    let imageSize = image.size
                    charLayer.setValue(String(char), forKey: "myContents")
                    charLayer.setValue(needsVerticallyCenteredColon, forKey: "verticallyCenteredColon")
                    
                    #if os(OSX)
                        charLayer.contents = image
                    #elseif os(iOS) || os(tvOS)
                        charLayer.contents = image.CGImage
                    #endif
                    
                    charLayer.frame = CGRect(origin: currentOrigin, size: imageSize)
                    
                    self.addSublayer(charLayer)
                }
                newLayers.append(charLayer)
                
                currentOrigin.x += charLayer.bounds.width
                boundingSize.width += charLayer.bounds.width
                boundingSize.height = max(boundingSize.height, charLayer.bounds.height)
            }
            
            contentLayersIndex = contentLayersIndex.successor()
            charactersIndex = charactersIndex.successor()
        }
        
        while contentLayersIndex < contentLayers.endIndex {
            contentLayers[contentLayersIndex].removeFromSuperlayer()
            contentLayersIndex = contentLayersIndex.successor()
        }
        
        self.contentLayers = newLayers
        self.boundingSize = boundingSize
    }
    
    private func setScrollLayerContents() {
        for (i, char) in text.characters.enumerate() {
            if let digit = Int(String(char)) {
                contentLayers[i].bounds.origin = upperRectForDigit(digit).origin
            }
        }
    }
    
    private func lowerRectForDigit(digit:Int) -> CGRect {
        let imageSize = digitsImage.size
        
        var rect = upperRectForDigit(digit)
        rect.origin.y += imageSize.height / 2
        return rect
    }
    
    private func upperRectForDigit(digit:Int) -> CGRect {
        let imageSize = digitsImage.size
        
        let individualHeight = digitsImageIndividualDigitSize.height
        let point = CGPointMake(0, CGFloat(digit) * individualHeight)
        return CGRect(origin: point, size: CGSize(width: imageSize.width, height: individualHeight))
    }
    
    @objc public enum AnimationDirection: Int {
        case Up
        case Down
    }
    
    public func playScrollAnimation(direction:AnimationDirection, completion:(()->Void)? = nil) {
        if animationDuration == 0 { return }
        
        let durationOffset = self.animationDuration/Double(contentLayers.count + 1)
        
        var offset = durationOffset * 2
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock(completion)
        for (i, char) in text.characters.enumerate() {
            if let digit = Int(String(char)) {
                let scrollLayer = contentLayers[i]
                let animation = CABasicAnimation(keyPath: "bounds.origin.y")
                let upOrigin = upperRectForDigit(digit).origin.y
                let downOrigin = lowerRectForDigit(digit).origin.y
                scrollLayer.bounds.origin.y =  (direction == .Up) ? downOrigin : upOrigin
                animation.fromValue = (direction == .Up) ? upOrigin : downOrigin
                animation.timingFunction = self.animationCurve
                animation.duration = offset
                scrollLayer.addAnimation(animation, forKey: "scroll")
            }
            offset += durationOffset
        }
        CATransaction.commit()
    }
    
    public static func evictGlobalImageCache() {
        globalImageCache.evict()
    }
}

private extension CGSize {
    func union(size:CGSize) -> CGSize {
        return CGSize(width: max(self.width, size.width), height: max(self.height, size.height))
    }
}

private extension TRZFont {
    var monospacedDigitsFont:TRZFont {
        #if os(OSX)
            let descriptor = self.fontDescriptor
            let TRZFontFeatureSettingsAttribute = NSFontFeatureSettingsAttribute
            let TRZFontFeatureTypeIdentifierKey = NSFontFeatureTypeIdentifierKey
            let TRZFontFeatureSelectorIdentifierKey = NSFontFeatureSelectorIdentifierKey
        #elseif os(iOS) || os(tvOS)
            let descriptor = self.fontDescriptor()
            let TRZFontFeatureSettingsAttribute = UIFontDescriptorFeatureSettingsAttribute
            let TRZFontFeatureTypeIdentifierKey = UIFontFeatureTypeIdentifierKey
            let TRZFontFeatureSelectorIdentifierKey = UIFontFeatureSelectorIdentifierKey
        #endif
        
        let attributes = [
            TRZFontFeatureSettingsAttribute: [
                [
                    TRZFontFeatureTypeIdentifierKey: kNumberSpacingType,
                    TRZFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector
                ]
            ]
        ]
        let newDescriptor = descriptor.fontDescriptorByAddingAttributes(attributes)
        #if os(OSX)
            return TRZFont(descriptor: newDescriptor, size: 0)!
        #elseif os(iOS) || os(tvOS)
            return TRZFont(descriptor: newDescriptor, size: 0)
        #endif
    }
    
    var verticallyCenteredColonFont:TRZFont {
        guard #available(iOS 9.0, OSX 10.11, *) else { return self }
        
        #if os(OSX)
            guard self.familyName?.hasPrefix(".") == true else { return self }
            let descriptor = self.fontDescriptor
            let TRZFontFeatureSettingsAttribute = NSFontFeatureSettingsAttribute
            let TRZFontFeatureTypeIdentifierKey = NSFontFeatureTypeIdentifierKey
            let TRZFontFeatureSelectorIdentifierKey = NSFontFeatureSelectorIdentifierKey
        #elseif os(iOS) || os(tvOS)
            guard self.familyName.hasPrefix(".") == true else { return self }
            let descriptor = self.fontDescriptor()
            let TRZFontFeatureSettingsAttribute = UIFontDescriptorFeatureSettingsAttribute
            let TRZFontFeatureTypeIdentifierKey = UIFontFeatureTypeIdentifierKey
            let TRZFontFeatureSelectorIdentifierKey = UIFontFeatureSelectorIdentifierKey
        #endif
        
        let attributes = [
            TRZFontFeatureSettingsAttribute: [
                [
                    TRZFontFeatureTypeIdentifierKey: kStylisticAlternativesType,
                    TRZFontFeatureSelectorIdentifierKey: kStylisticAltThreeOnSelector
                ]
            ]
        ]
        
        let newDescriptor = descriptor.fontDescriptorByAddingAttributes(attributes)
        #if os(OSX)
            return TRZFont(descriptor: newDescriptor, size: 0)!
        #elseif os(iOS) || os(tvOS)
            return TRZFont(descriptor: newDescriptor, size: 0)
        #endif
    }
}