// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

import UIKit

/// Preheat controller for `UITableView`.
public class PreheatControllerForTableView: PreheatController {
    /// The table view that the receiver was initialized with.
    public var tableView: UITableView {
        return scrollView as! UITableView
    }

    /// The proportion of the collection view size (either width or height depending on the scroll axis) used as a preheat window.
    public var preheatRectRatio: CGFloat = 1.0

    /// Determines how far the user needs to refresh preheat window.
    public var preheatRectUpdateRatio: CGFloat = 0.33

    private var previousContentOffset = CGPoint.zero

    /// Initializes the receiver with a given table view.
    public init(tableView: UITableView) {
        super.init(scrollView: tableView)
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
        let updateMargin = tableView.bounds.height * preheatRectUpdateRatio
        let contentOffset = tableView.contentOffset
        guard distanceBetweenPoints(contentOffset, previousContentOffset) > updateMargin || previousContentOffset == CGPoint.zero else {
            return
        }
        let scrollDirection: ScrollDirection = (contentOffset.y >= previousContentOffset.y || previousContentOffset == CGPoint.zero) ? .forward : .backward

        previousContentOffset = contentOffset
        let preheatRect = preheatRectInScrollDirection(scrollDirection)
        let preheatIndexPaths = Set(tableView.indexPathsForRows(in: preheatRect) ?? []).subtracting(tableView.indexPathsForVisibleRows ?? [])
        updatePreheatIndexPaths(sortIndexPaths(preheatIndexPaths, inScrollDirection: scrollDirection))
    }

    private func preheatRectInScrollDirection(_ direction: ScrollDirection) -> CGRect {
        let viewport = CGRect(origin: tableView.contentOffset, size: tableView.bounds.size)
        let height = viewport.height * preheatRectRatio
        let y = (direction == .forward) ? viewport.maxY : viewport.minY - height
        return CGRect(x: 0, y: y, width: viewport.width, height: height).integral
    }
}
