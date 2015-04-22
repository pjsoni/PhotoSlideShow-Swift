//
//  ImageScrollView.swift
//  PhotoSlideShow-Swift
//
//  Created by VillyG on 4/21/15.
//  Copyright (c) 2015 VillyG. All rights reserved.
//

import UIKit


class ImageScrollView: UIScrollView, UIScrollViewDelegate {
    
    
    private var _imageView: UIImageView?
    
    private var _imageSize: CGSize!
    
    private var _pointToCenterAfterResize: CGPoint!
    
    private var _scaleToRestoreAfterResize: CGFloat!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.customInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.customInit()
    }
    
    func customInit() {
        
        self.showsVerticalScrollIndicator = false;
        self.showsHorizontalScrollIndicator = false
        self.bouncesZoom = true
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.delegate = self
        
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // center the zoom view as it becomes smaller than the size of the screen
        var boundsSize: CGSize = self.bounds.size
        var frameToCenter: CGRect = self._imageView!.frame
        
        // center horizontally
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        }
        else {
            frameToCenter.origin.x = 0
        }
        
        // center vertically
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        }
        else {
            frameToCenter.origin.y = 0
        }
        
        self._imageView!.frame = frameToCenter
    }
    
    
    
    
    override var frame: CGRect {
        willSet{
            // check to see if there is a resize coming. prepare if there is one
            var sizeChanging: Bool = !CGSizeEqualToSize(frame.size, newValue.size)
            if sizeChanging { self.prepareToResize()}
            
        }
        didSet {
            // check to see if there was a resize. recover if there was one
            var sizeChanged: Bool = !CGSizeEqualToSize(frame.size, oldValue.size)
            if sizeChanged { self.recoverFromResizing() }
        }
    }
    
    
    
    
    // ***********************************************
    // MARK: UIScrollViewDelegate
    // ***********************************************
    
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self._imageView
    }
    
    
    // ***********************************************
    // MARK: Configure scrollview to display image
    // ***********************************************
    
    
    
    func displayImage(image: UIImage) {
        
        if self._imageView != nil {
            self._imageView?.removeFromSuperview()
            self._imageView = nil
        }
        
        
        self.zoomScale = 1.0
        
        self._imageView = UIImageView(image: image)
        
        self.addSubview(self._imageView!)
        
        self.configureForImageSize(image.size)
    }
    
    
    func configureForImageSize(imageSize: CGSize) {
        
        _imageSize = imageSize
        self.contentSize = imageSize
        self.setMaxMinZoomScalesForCurrentBounds()
        self.zoomScale = self.minimumZoomScale
    }
    
    
    func setMaxMinZoomScalesForCurrentBounds() {
        
        var boundsSize: CGSize = self.bounds.size
        
        // calculate min/max zoom scale
        var xScale: CGFloat = boundsSize.width / _imageSize.width   // the scale needed to perfectly fit the image width-wise
        var yScale: CGFloat = boundsSize.height / _imageSize.height // the scale neede to perfectly fit the image height-wise
        
        // fill width if the image nad phone are both in prortrait or both landscape; otherwise take smaller scale
        var imagePortrait: Bool = _imageSize.height > _imageSize.width
        var phonePortrait: Bool = boundsSize.height > boundsSize.width
        var minScale: CGFloat = imagePortrait == phonePortrait ? xScale : min(xScale, yScale)
        
        // on high res screens we have double the pixel density, so we will be seeing every pixel if we limit the max zoom scale to 0.5
        var maxScale: CGFloat = 1.0 / UIScreen.mainScreen().scale
        
        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        
        if minScale > maxScale {
            minScale = maxScale
        }
        
        self.maximumZoomScale = maxScale
        self.minimumZoomScale = minScale
        
    }
    
    
    
    // ***********************************************
    // MARK: Configure scrollview to display image
    // ***********************************************
    
    
    func prepareToResize(){
        
        var boundsCenter: CGPoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        _pointToCenterAfterResize = self.convertPoint(boundsCenter, toView: self._imageView)
        
        _scaleToRestoreAfterResize = self.zoomScale
        
        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        
        if Float(_scaleToRestoreAfterResize) <= Float(self.minimumZoomScale) + FLT_EPSILON {
            _scaleToRestoreAfterResize = 0
        }
        
    }
    
    
    
    func recoverFromResizing() {
        
        self.setMaxMinZoomScalesForCurrentBounds()
        
        
        
        // Step 1: restore zoom scale, first making sure it is within the allowable range.
        var maxZoomScale: CGFloat = max(self.minimumZoomScale, _scaleToRestoreAfterResize)
        self.zoomScale = min(self.maximumZoomScale, maxZoomScale)
        
        // Step 2: restore center point, first making sure it is within the allowable range.
        
        // 2a: convert our desired center point back to our own coordinate space
        var boundsCenter: CGPoint = self.convertPoint(_pointToCenterAfterResize, fromView: self._imageView)
        
        // 2b: calculate the content offset that would yield that center point
        var offset: CGPoint = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0, boundsCenter.y - self.bounds.size.height / 2.0)
        
        // 2c: restore offset, adjusted to be within the allowable range
        var maxOffset: CGPoint = self.maximumContentOffset()
        var minOffset: CGPoint = self.minimumContentOffset()
        
        var realMaxOffset: CGFloat = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)
        
        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)
        
        self.contentOffset = offset
        
    }
    
    func maximumContentOffset() -> CGPoint {
        var contentSize: CGSize = self.contentSize
        var boundsSize: CGSize = self.bounds.size
        return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height)
    }
    
    func minimumContentOffset() -> CGPoint {
        return CGPointZero
    }
    
}


