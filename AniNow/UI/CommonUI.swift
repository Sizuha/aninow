//
//  CommonUI.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/04.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SizUtil

extension UIViewController {
	
	func initStatusBar() {
		if #available(iOS 13, *) { return }
		
		UIApplication.shared.statusBarView?.backgroundColor = getThemeColor(.navigationBackground)
	}
	
	func createNavigationBar() -> UINavigationBar {
		let naviBar = UINavigationBar(frame: CGRect.init(
			x: 0,
			y: UIApplication.shared.statusBarFrame.size.height,
			width: view.frame.size.width,
			height: 45
		))
		
		initNavigationBarStyle(naviBar)
		return naviBar
	}
	
	func initNavigationBarStyle(_ naviBar: UINavigationBar) {
		naviBar.tintColor = getThemeColor(.navigationAction)
		naviBar.barTintColor = getThemeColor(.navigationBackground)
		naviBar.barStyle = .blackOpaque
		naviBar.isTranslucent = false
	}
	
	enum ColorCategory {
		case action
		case navigationAction
		case navigationBackground
		case background
		case touchHandle
	}
	
	func getThemeColor(_ category: ColorCategory) -> UIColor {
		switch category {
		case .action: return UIColor.red
		case .navigationAction: return UIColor.white
		case .navigationBackground: return UIColor.black
		case .background:
			if #available(iOS 13, *) {
				return UIColor.systemBackground
			}
			else {
				return UIColor.white
			}
		case .touchHandle:
			if #available(iOS 13, *) {
				return isDarkMode ? UIColor.white : UIColor.black
			}
			else {
				return UIColor.black
			}
//		default:
//			return UIColor.defaultText
		}
	}

	func applyThemeTintColor(image: UIImage) -> UIImage {
		if #available(iOS 13.0, *) {
			return image.withTintColor(getThemeColor(.touchHandle))
		}
		else {
			return image
		}
	}

}

class CommonUIViewController: UIViewController {
	
	var indicator: UIActivityIndicatorView? = nil
	var fadeView: UIView? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColor = getThemeColor(.background)
		
		initStatusBar()
	}

	func addFadeView() {
		guard self.fadeView == nil else { return }
		
		if let window = UIApplication.shared.keyWindow {
			self.fadeView = UIView(frame: window.frame)
			window.addSubview(self.fadeView!)
		}
		else {
			self.fadeView = UIView(frame: self.view.frame)
			self.view.addSubview(self.fadeView!)
		}
		self.fadeView!.backgroundColor = .black
		self.fadeView!.isHidden = true
	}
	
	private func addIndicator() {
		guard self.indicator == nil else { return }
		
		self.indicator = UIActivityIndicatorView()
		self.indicator!.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
		self.indicator!.center = view.center
		self.indicator!.style = .whiteLarge
		self.indicator!.hidesWhenStopped = true
		
		if let window = UIApplication.shared.keyWindow {
			window.addSubview(self.indicator!)
		}
		else {
			view.addSubview(self.indicator!)
		}
	}
	
	func startNowLoading() {
		self.addIndicator()
		self.indicator?.startAnimating()
	}
	
	func stopNowLoading() {
		self.indicator?.stopAnimating()
	}
	
	func fadeOut(
		start: CGFloat = 0.0,
		end: CGFloat = 0.5,
		duration: TimeInterval = 0.3,
		completion: ((Bool)->Void)? = nil)
	{
		if self.fadeView == nil { addFadeView() }
		if let fadeView = self.fadeView {
			fadeView.alpha = start
			fadeView.isHidden = false
			UIView.animate(
				withDuration: duration,
				delay: 0,
				animations: { fadeView.alpha = end },
				completion: completion
			)
		}
	}
	
	func fadeIn(completion: ((Bool)->Void)? = nil) {
		guard let fadeView = self.fadeView else { return }
		
		UIView.animate(withDuration: 0.15, delay: 0, animations: { fadeView.alpha = 0.0 }) { finished in
			if finished {
				fadeView.isHidden = true
			}
			
			completion?(finished)
		}
	}
	
}

func createEmptyView() -> UILabel {
	let emptyView = UILabel()
	emptyView.text = Strings.EMPTY_ITEMS
	emptyView.textAlignment = .center
	emptyView.textColor = .placeholderGray
	emptyView.font = UIFont.systemFont(ofSize: 24.0)
	emptyView.isHidden = true
	//emptyView.backgroundColor = .blue
	emptyView.translatesAutoresizingMaskIntoConstraints = false
	
	return emptyView
}

func openEditAnimePage(_ viewController: UIViewController, item: Anime? = nil) {
	let editNaviController = UINavigationController()
	let editView = EditAnimeViewController()
	if let item = item {
		editView.setItem(item)
	}
	editNaviController.pushViewController(editView, animated: false)
	
	viewController.present(editNaviController, animated: true, completion: nil)
}

func getRatingToStarText(_ rating: Int) -> String {
	var star = ""
	for _ in stride(from: 0, to: rating, by: 1) {
		star.append(Strings.STAR)
	}
	return star.isEmpty ? Strings.NO_RATING : star
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
