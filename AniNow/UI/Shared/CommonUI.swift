//
//  CommonUI.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/04.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SizUI
import SizUtil

class CommonUIViewController: UIViewController {
	
	var indicator: UIActivityIndicatorView? = nil
	var fadeView: UIView? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
    
	func addFadeView() {
        guard let window = getKeyWindow() else { assert(false); return }
        
		if self.fadeView == nil {
            self.fadeView = UIView(frame: window.frame)
        }
        
        if self.fadeView?.superview != nil {
            self.fadeView?.removeFromSuperview()
        }
        window.addSubview(self.fadeView!)
		
		self.fadeView!.backgroundColor = .black
		self.fadeView!.isHidden = true
        
        let onFadeViewTap = UITapGestureRecognizer(target: self, action: #selector(self.onFadeViewTap))
        self.fadeView?.addGestureRecognizer(onFadeViewTap)
	}
    
    @objc func onFadeViewTap() {}
	
	private func addIndicator() {
        if self.indicator == nil {
            self.indicator = UIActivityIndicatorView()
        }
		
		self.indicator!.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
		self.indicator!.center = view.center
        self.indicator!.style = UIActivityIndicatorView.Style.large
		self.indicator!.hidesWhenStopped = true
        getKeyWindow()?.addSubview(self.indicator!)
	}
	
	func startNowLoading() {
		self.addIndicator()
        self.indicator?.superview?.bringSubviewToFront(self.indicator!)
		self.indicator?.startAnimating()
	}
	
	func stopNowLoading() {
		self.indicator?.stopAnimating()
        self.indicator?.removeFromSuperview()
	}
	
	func fadeOutWindow(
		start: CGFloat = 0.0,
		end: CGFloat = 0.5,
		duration: TimeInterval = 0.3,
		completion: ((Bool)->Void)? = nil)
	{
		addFadeView()
        guard let fadeView = self.fadeView else { assert(false); return }
        
        fadeView.alpha = start
        fadeView.isHidden = false
        UIView.animate(
            withDuration: duration,
            delay: 0,
            animations: { fadeView.alpha = end },
            completion: completion
        )
	}
	
	func fadeInWindow(completion: ((Bool)->Void)? = nil) {
		guard let fadeView = self.fadeView else { return }
		
		UIView.animate(withDuration: 0.15, delay: 0, animations: { fadeView.alpha = 0.0 }) { finished in
			if finished {
				fadeView.isHidden = true
                fadeView.removeFromSuperview()
			}
			
			completion?(finished)
		}
	}
	
}

func createEmptyView() -> UILabel {
	let emptyView = UILabel()
	emptyView.text = Strings.EMPTY_ITEMS
	emptyView.textAlignment = .center
	emptyView.textColor = .secondaryLabel
	emptyView.font = UIFont.systemFont(ofSize: 24.0)
	emptyView.isHidden = true
	//emptyView.backgroundColor = .blue
	emptyView.translatesAutoresizingMaskIntoConstraints = false
	
	return emptyView
}

func getRatingToStarText(_ rating: Int, fillEmpty: Bool = false) -> String {
	var star = ""
    star.reserveCapacity(5)
    
	for _ in stride(from: 0, to: rating, by: 1) {
		star.append(Strings.STAR_FILL)
	}
    if fillEmpty {
        for _ in 0..<(5-rating) {
            star.append(Strings.STAR_EMPTY)
        }
    }

    if star.isEmpty && !fillEmpty {
        return Strings.NO_RATING
    }
	return star
}

class ActionPropertyTableView: SizPropertyTableView {
	
	var onDeleteItem: ((IndexPath)->Bool)? = nil
	
	override func trailingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration? {
		return SizSwipeActionBuilder()
			.addAction(title: Strings.REMOVE, style: .destructive, handler: { action, view, handler in
				handler(self.onDeleteItem?(rowAt) == true)
			})
			.createConfig()
	}
	
}
