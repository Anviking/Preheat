// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

import UIKit

/// Preheat controller for `UICollectionView` with `UICollectionViewFlowLayout` layout.
public class PreheatControllerForCollectionView: PreheatController {
    /// The collection view that the receiver was initialized with.
    public var collectionView: UICollectionView {
        return scrollView as! UICollectionView
    }
    /// The layout of the collection view.
    public var collectionViewLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    /// The proportion of the collection view size (either width or height depending on the scroll axis) used as a preheat window.
    public var preheatRectRatio: CGFloat = 1.0
    
    /// Determines how far the user needs to refresh preheat window.
    public var preheatRectUpdateRatio: CGFloat = 0.33
    
    private var previousContentOffset = CGPoint.zero

    /// Initializes the receiver with a given collection view.
    public init(collectionView: UICollectionView) {
        assert(collectionView.collectionViewLayout is UICollectionViewFlowLayout)
        super.init(scrollView: collectionView)
    }

    /// Default value is false. See superclass for more info.
    public override var enabled: Bool {
        didSet {
            if enabled {
                updatePreheatRect()
            } else {
                previousContentOffset = CGPoint.zero
                updatePreheatIndexPaths([])
            }
        }
    }
    
    /**
     Removes all index paths without signalling the delegate. Then updates preheat rect (if enabled).
     
     This method is useful when your model changes completely in which case you would first stop preheating all images and then reset the preheat controller.
     */
    public override func reset() {
        super.reset()
        previousContentOffset = CGPoint.zero
        if enabled {
            updatePreheatRect()
        }
    }
    
    /// Updates preheat rect if enabled.
    public override func scrollViewDidScroll() {
        if enabled {
            updatePreheatRect()
        }
    }

    private func updatePreheatRect() {
        let scrollAxis = collectionViewLayout.scrollDirection
        let updateMargin = (scrollAxis == .vertical ? CGRectGetHeight : CGRectGetWidth)(collectionView.bounds) * preheatRectUpdateRatio
        let contentOffset = collectionView.contentOffset
        guard distanceBetweenPoints(contentOffset, previousContentOffset) > updateMargin || previousContentOffset == CGPoint.zero else {
            return
        }
        // Update preheat window
        let scrollDirection: ScrollDirection = ((scrollAxis == .vertical ? contentOffset.y >= previousContentOffset.y : contentOffset.x >= previousContentOffset.x) || previousContentOffset == CGPoint.zero) ? .forward : .backward
        
        previousContentOffset = contentOffset
        let preheatRect = preheatRectInScrollDirection(scrollDirection)
        let preheatIndexPaths = indexPathsForElementsInRect(preheatRect).subtracting(collectionView.indexPathsForVisibleItems())
        updatePreheatIndexPaths(sortIndexPaths(preheatIndexPaths, inScrollDirection: scrollDirection))
    }
    
    private func preheatRectInScrollDirection(_ direction: ScrollDirection) -> CGRect {
        let viewport = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        switch collectionViewLayout.scrollDirection {
        case .vertical:
            let height = viewport.height * preheatRectRatio
            let y = (direction == .forward) ? viewport.maxY : viewport.minY - height
            return CGRect(x: 0, y: y, width: viewport.width, height: height).integral
        case .horizontal:
            let width = viewport.width * preheatRectRatio
            let x = (direction == .forward) ? viewport.maxX : viewport.minX - width
            return CGRect(x: x, y: 0, width: width, height: viewport.height).integral
        }
    }
    
    private func indexPathsForElementsInRect(_ rect: CGRect) -> Set<IndexPath> {
        guard let layoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect) else {
            return []
        }
        return Set(layoutAttributes.filter{ return $0.representedElementCategory == .cell }.map{ return $0.indexPath })
    }
}
