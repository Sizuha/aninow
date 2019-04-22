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
	
	private var btnNew: UIBarButtonItem!
	
	// item Count
	private var countOfAll: Int = 0
	private var countOfNow: Int = 0
	private var countOfFinished: Int = 0
	private var countByMedia = [Anime.MediaType:Int]()
	private var countByRating = [Int:Int]()
	
	// for Settings
	private var dispLastBackup: UILabel?
	private var dateTimeFmt: DateFormatter!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.dateTimeFmt = SQuery.newDateTimeFormat()
		self.dateTimeFmt.timeZone = TimeZone.current

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
		if let navigationBar = self.navigationController?.navigationBar {
			self.navigationController?.delegate = self
			initNavigationBarStyle(navigationBar)
		}
		
		self.btnNew = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewItem))
		
		self.navigationItem.title = "AniNow"
		self.navigationItem.rightBarButtonItems = []
		self.navigationItem.rightBarButtonItems!.append(self.btnNew)
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
		self.menus.append(SizPropertyTableSection(
			title: Strings.FILTER_MEDIA,
			rows: [
				createMediaFilterMenu(.tv),
				createMediaFilterMenu(.ova),
				createMediaFilterMenu(.movie),
				createMediaFilterMenu(.none),
			]
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
		
		// Info
		self.menus.append(SizPropertyTableSection(
			title: Strings.INFO,
			rows: [
				// Version
				SizPropertyTableRow(label: "Version")
					.bindData { getAppShortVer() + "." + getAppBuildVer() }
			]
		))
		
		// Backup
		self.menus.append(SizPropertyTableSection(
			title: Strings.BACKUP,
			rows: [
				// Last Backup
				SizPropertyTableRow(label: Strings.LAST_BACKUP)
					.bindData {
						if let date = Settings.shared.lastBackupDate {
							return self.dateTimeFmt.string(from: date)
						}
						return Strings.NONE_VALUE2
					}
					.onCreate { c in
						self.dispLastBackup = c.detailTextLabel
					}
				
				// Export
				,SizPropertyTableRow(type: .button, label: Strings.EXPORT)
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.confirmExport()
					}
				
				// Import
				,SizPropertyTableRow(label: Strings.IMPORT)
					.textColor(self.menuTable.tintColor)
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.moveToImportUI()
					}
			]
		))
		
		// etc
		self.menus.append(SizPropertyTableSection(
			rows: [
				// Clear
				SizPropertyTableRow(type: .button, label: Strings.DELETE_ALL)
					.tintColor(.red)
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.tryClearAll()
					}
					.onCreate { c in
						if let cell = c as? SizCellForButton {
							cell.textLabel?.textAlignment = .center
						}
					}
			]
		))
		
		self.menuTable.setDataSource(self.menus)
		self.view.addSubview(self.menuTable)
	}
	
	private func createMediaFilterMenu(_ media: Anime.MediaType) -> SizPropertyTableRow{
		return SizPropertyTableRow(label: media.toString())
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
	
	func confirmExport() {
		SizAlertBuilder(style: .actionSheet)
			.setMessage(Strings.MSG_CONFIRM_EXPORT)
			.addAction(title: Strings.OK) { _ in
				self.fadeOut { fin in
					self.startNowLoading()
					DispatchQueue.main.async {
						self.exportToCSV()
					}
				}
			}
			.addAction(title: Strings.CANCEL, style: .cancel)
			.show(parent: self)
	}
	
	func exportToCSV() {
		let now = Date()
		
		let fmt = DateFormatter()
		fmt.locale = SQuery.standardLocal
		fmt.dateFormat = "yyyy-MM-dd_HHmmss"
		fmt.timeZone = TimeZone.current
		
		let fileName = "aninow_\(fmt.string(from: now)).csv"
		let outFilePath = "\(SizPath.appDocument)/\(fileName)"
		
		AnimeDataManager.shared.exportTo(file: outFilePath)
		
		Settings.shared.lastBackupDate = now
		self.dispLastBackup?.text = self.dateTimeFmt.string(from: now)
		
		stopNowLoading()
		fadeIn()
		
		let dlg = createAlertDialog(message: Strings.MSG_END_BACKUP)
		present(dlg, animated: true)
	}
	
	func moveToImportUI() {
		let nextView = ImportCsvViewController()
		self.navigationController?.pushViewController(nextView, animated: true)
	}
	
	func tryClearAll() {
		SizAlertBuilder()
			.setMessage(Strings.MSG_CONFIRM_REMOVE_ALL)
			.addAction(title: Strings.CANCEL)
			.addAction(title: Strings.REMOVE, style: .destructive) { _ in
				AnimeDataManager.shared.removeAll()
				self.refresh()
			}
			.show(parent: self)
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
				
				for media in Anime.MediaType.allCases {
					self.countByMedia[media] = dm.countWithFilter { f in
						let _ = f.whereAnd("media=?", media.rawValue)
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
	
}
