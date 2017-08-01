TRZNumberScrollView
===
An efficient animated number scrolling view for iOS and OS X.

![Demo](demo.gif)

Why?
---
I had been using [JTNumberScrollAnimatedView](https://github.com/jonathantribouharet/JTNumberScrollAnimatedView) for my app [2STP](https://geo.itunes.apple.com/us/app/2stp-authenticator/id954311670?ls=1&mt=8), but there are some significant performance issues with that implementation (specifically, the allocation of a `UILabel` for each digit, causing pauses when they get released). This is an entirely separate implementation of approximately the same effect.

This implementation uses `CALayer`s that share their image contents, making it suitable for extremely memory-constrained scenarios, such as in Notification Center widgets. It also plays better with Auto Layout. Finally, it's cross-platform, thanks to most of the code being implemented at the Core Animation level.

Setup
---

1. Drag and drop NumberScrollView.swift into your iOS or OS X project.

Usage
---
```swift
let numberView = NumberScrollView()
//Add to superview, configure constraints etc.
numberView.setText(123456", animated: true)
```

You can set any text, including non-numeric characters; however, only numeric digits will be animated.

In addition, the view's behavior can be customized via the following properties:

- `font`
- `textColor`
- `animationDuration`
- `animationCurve`
- `animationDirection`

If you intend to set both `font` and `textColor` at the same time, it is recommended that you do so either before setting `text`, or by calling the `setFont(_:textColor:)` method, to avoid generating unnecessary images.

The included demo project for OS X lets you play with these parameters so you can tweak the behavior to your liking. 

Caching
---
By default, generated images are cached in a global, thread-safe cache on iOS (images are not cached by default on OS X). However, you can override this behavior by setting the `imageCachePolicy` property on the `NumberScrollView`, or by setting the `imageCache` property on a `NumberScrollLayer` to an appropriate value.

The default cache implementation on iOS automatically evicts its unused contents when the app is backgrounded or when the app receives a memory warning. The default cache on OS X does not automatically evict its unused contents, but you can do so manually by calling `NumberScrollLayer.evictGlobalImageCache()`.

Subpixel Antialiasing
---
This library supports subpixel antialiasing on OS X. This feature can be enabled via one of two different ways:

1. By setting an opaque (alpha == 1) color as the `backgroundColor` of the `NumberScrollView` (or if using the layer directly, the `NumberScrollLayer`).
2. Through the use of __private API__, which enables subpixel antialiasing on non-opaque backgrounds. This method is not perfect, due to the nature of subpixel antialiasing, but can produce "good enough" results.

To enable subpixel antialiasing on non-opaque backgrounds, follow these steps:

1. Add the `TRZNUMBERSCROLL_ENABLE_PRIVATE_API` preprocessor symbol. You can do this by adding the string `-DTRZNUMBERSCROLL_ENABLE_PRIVATE_API` under "Other Swift Flags" in the "Build Settings" tab of your project configuration.
2. Specify the background color to use for subpixel antialiasing by setting the `fontSmoothingBackgroundColor` on either `NumberScrollView` or `NumberScrollLayer`. You should specify a background color that is close to what the final composited background color will be.

Depending on your design, you may or may not want to enable this feature. Subpixel antialiased fonts look slightly bolder, so you might want to consider enabling this if you need the `NumberScrollView`'s visual weight to be consistent with other labels throughout your app. Another good use of this feature is when this view is displayed above a vibrant view that usually remains the same color, such as in a Notification Center widget.

You should not have any trouble passing App Review if the `TRZNUMBERSCROLL_ENABLE_PRIVATE_API` symbol is not added, since any references to private APIs get compiled away. It also appears that the validator does not catch this particular private API, but violating App Store guidelines is done at your own peril.

Enabling private API usage has no effect on iOS, since iOS does not support subpixel antialiasing anyway. However, setting the `backgroundColor` property can still improve performance, due to reduced blending.