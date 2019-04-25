//
//  HomeViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/25.
//  Copyright © 2018 Sizuha's Atelier. All rights reserved.
//

import UIKit
import SQuery
import SizUtil

class HomeViewController: CommonUIViewController, UINavigationControllerDelegate {
	
	private var menuTable: SizPropertyTableView!
	private var menus = [SizPropertyTableSection]()
	
	private var btnSettings: UIBarButtonItem!
	private var btnNew: UIBarButtonItem!
	
	// item Count
	private var countOfAll: Int = 0
	private var countOfNow: Int = 0
	private var countOfFinished: Int = 0
	private var countByMedia = [Int:Int]()
	private var countByRating = [Int:Int]()
	
	override func viewDidLoad() {
		super.viewDidLoad()

		initStatusBar()
		initNavigationBar()
		initTableView()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		setMatchToParent(parent: self.view, child: self.menuTable)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		refresh()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	private func initNavigationBar() {
		if let navigationBar = navigationController?.navigationBar {
			navigationController?.delegate = self
			initNavigationBarStyle(navigationBar)
		}
		
		btnSettings = UIBarButtonItem(image: Icons.SETTINGS, style: .plain, target: self, action: #selector(showSettings))
		btnNew = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewItem))
		
		navigationItem.title = "AniNow"
		navigationItem.leftBarButtonItems = [btnSettings]
		navigationItem.rightBarButtonItems = [self.btnNew]
	}
	
	private func initTableView() {
		self.menuTable = SizPropertyTableView(frame: .zero, style: .grouped)
		self.menuTable.translatesAutoresizingMaskIntoConstraints = false
		
		// Categories
		self.menus.append(SizPropertyTableSection(
			title: Strings.LABEL_ANIME_LIST,
			rows: [
				SizPropertyTableRow(label: Strings.ALL_VIEWING)
					.bindData { String(self.countOfAll) }
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						let nextView = AllViewController()
						self.navigationController?.pushViewController(nextView, animated: true)
					}

				,SizPropertyTableRow(label: Strings.NOW_VIEWING)
					.bindData { String(self.countOfNow) }
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						let nextView = NowViewController()
						self.navigationController?.pushViewController(nextView, animated: true)
					}
				
				,SizPropertyTableRow(label: Strings.END_VIEWING)
					.bindData { String(self.countOfFinished) }
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						let nextView = FinishedViewController()
						self.navigationController?.pushViewController(nextView, animated: true)
					}
			]
		))

		// filter: Media
		let medias = AnimeDataManager.shared.loadMedias().sorted(by: <)
		
		var mediaRows = [SizPropertyTableRow]()
		for (code, label) in medias {
			mediaRows.append(createMediaFilterMenu(code, label: label))
		}
		
		self.menus.append(SizPropertyTableSection(
			title: Strings.FILTER_MEDIA,
			rows: mediaRows
		))

		
		// filter: Rating
		self.menus.append(SizPropertyTableSection(
			title: Strings.FILTER_RATING,
			rows: [
				createRatingFilterMenu(5),
				createRatingFilterMenu(4),
				createRatingFilterMenu(3),
				createRatingFilterMenu(2),
				createRatingFilterMenu(1),
				createRatingFilterMenu(0),
			]
		))
		
		self.menuTable.setDataSource(self.menus)
		self.view.addSubview(self.menuTable)
	}
	
	private func createMediaFilterMenu(_ media: Int, label: String) -> SizPropertyTableRow{
		return SizPropertyTableRow(label: label)
			.bindData { String(self.countByMedia[media] ?? 0) }
			.onSelect { i in
				self.menuTable.deselectRow(at: i, animated: true)
				let nextView = MediaFilteredViewController()
				nextView.mediaFilter = media
				self.navigationController?.pushViewController(nextView, animated: true)
			}
			.onCreate { c in c.textLabel?.textColor = UIColor.darkText }
	}
	
	private func createRatingFilterMenu(_ rating: Int) -> SizPropertyTableRow{
		return SizPropertyTableRow(label: getRatingToStarText(rating))
			.bindData { String(self.countByRating[rating] ?? 0) }
			.onSelect { i in
				self.menuTable.deselectRow(at: i, animated: true)
				let nextView = RatingFilteredViewController()
				nextView.rating = rating
				self.navigationController?.pushViewController(nextView, animated: true)
			}
	}

	@objc func addNewItem() {
		openEditAnimePage(self, item: Anime())
	}
	
	func refresh() {
		fadeOut(start: 0.0, end: 0.0) { fin in
			guard fin else { return }
			
			self.startNowLoading()
			DispatchQueue.main.async {
				let dm = AnimeDataManager.shared
				
				self.countOfNow = dm.count(finished: false)
				self.countOfFinished = dm.count(finished: true)
				//self.countOfAll = dm.count()
				self.countOfAll = self.countOfNow + self.countOfFinished
				
				let medias = AnimeDataManager.shared.loadMedias()
				for (code, _) in medias {
					self.countByMedia[code] = dm.countWithFilter { f in
						let _ = f.whereAnd("media=?", code)
					}
				}
				
				for rating in 0...5 {
					self.countByRating[rating] = dm.countWithFilter { f in
						let _ = f.whereAnd("rating >= ? AND rating < ?", rating, rating+1)
					}
				}
				
				self.menuTable.reloadData()
				self.stopNowLoading()
				self.fadeIn()
			}
		}
	}
	
	@objc func showSettings() {
		let naviController = UINavigationController()
		let vc = SettingsViewController()
		naviController.pushViewController(vc, animated: false)
		present(naviController, animated: true, completion: nil)
	}
	
}
