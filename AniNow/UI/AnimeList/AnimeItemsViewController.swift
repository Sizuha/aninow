//
//  FirstViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/11/30.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SQuery
import SizUtil

class AnimeItemsViewController:
	UIViewController,
	UINavigationControllerDelegate,
	UISearchBarDelegate,
	AnimeListFilter
{
	private var searchText: String? = nil
	
	private var navigationBar: UINavigationBar!
	private var btnNew: UIBarButtonItem!
	private var btnSort: UIBarButtonItem!
	private var btnBeginEditMode: UIBarButtonItem!
	private var btnEndEditMode: UIBarButtonItem!
	private var btnSearch: UIBarButtonItem!
	
	private var searchBar: UISearchBar!
	private var animeTableView: AnimeTableView!
	private var emptyView: UILabel!
	private var editMode = false

	func getTitle() -> String {
		fatalError("Subclasses need to implement the `getTitle()` method.")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if DEBUG_MODE { NSLog("called: viewDidLoad()") }
		
		self.view.backgroundColor = Colors.WIN_BG

		initStatusBar()
		initNavigationBar()
		initTableView()
		initSearchBar()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		self.animeTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
		self.animeTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
		self.animeTableView.topAnchor.constraint(equalTo: self.searchBar.bottomAnchor).isActive = true
		self.animeTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
		//setMatchToParent(parent: self.view, child: self.animeTableView)
		
		self.emptyView.centerXAnchor.constraint(equalTo: self.animeTableView.centerXAnchor).isActive = true
		self.emptyView.centerYAnchor.constraint(equalTo: self.animeTableView.centerYAnchor).isActive = true
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if DEBUG_MODE { NSLog("called: viewWillAppear()") }
		
		reloadItems()
	}
	
	private func initNavigationBar() {
		self.navigationBar = self.navigationController?.navigationBar
		guard self.navigationBar != nil else { return }
		
		self.navigationController?.delegate = self
		initNavigationBarStyle(self.navigationBar)
		
		self.btnNew = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewItem))
		self.btnSort = UIBarButtonItem(title: Strings.SORT, style: .plain, target: self, action: #selector(showSortOptions))
		self.btnBeginEditMode = UIBarButtonItem(title: Strings.SELECT, style: .plain, target: self, action: #selector(beginEditMode))
		self.btnEndEditMode = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(endEditMode))
		self.btnSearch = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(toggleSearchUI))
		
		let naviItem = self.navigationItem
		naviItem.title = getTitle()
		naviItem.leftItemsSupplementBackButton = true
		naviItem.leftBarButtonItems = [self.btnSort]
		naviItem.rightBarButtonItems = [self.btnNew, self.btnSearch]
	}
	
	private func initSearchBar() {
		self.searchBar = UISearchBar(frame: CGRect(x: 0, y: -50, width: self.view.frame.width, height: 50))
		self.searchBar.barTintColor = Colors.NAVI_BG
		self.view.addSubview(self.searchBar)
	}

	private func initTableView() {
		let table = AnimeTableView(frame: .zero, style: .plain, owner: self)
		table.tableFooterView = UIView()
		table.translatesAutoresizingMaskIntoConstraints = false
		table.allowsMultipleSelection = false
		self.animeTableView = table
		view.addSubview(self.animeTableView)
		
		self.emptyView = createEmptyView()
		self.emptyView.center = self.animeTableView.center
		view.addSubview(self.emptyView)
		
		self.animeTableView.emptyView = self.emptyView
	}
	
	open func applyFilter(to target: TableQuery) {
		guard let searchKey = self.searchText else {
			return
		}
		
		let key = searchKey.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		if !key.isEmpty {
			let likeKey = "%%\(key)%%"
			let _ = target.whereAnd("\(Anime.F_TITLE) LIKE ? OR \(Anime.F_TITLE_OTHER) LIKE ?", likeKey, likeKey)
		}
	}
	
	func reloadItems() {
		self.animeTableView.sections.removeAll()
		let rows = AnimeDataManager.shared.loadItems(
			filter: self,
			sortBy: Settings.shared.sortType,
			sortAsc: !Settings.shared.sortDesc
		)

		var lastSection: AnimeTableView.Section? = nil
		for row in rows {
			let secTitle: String
			switch Settings.shared.sortType {
			case .byDate:
				secTitle = row.startDate?.toString() ?? Strings.UNKNOWN
			case .byMedia:
				secTitle = row.media.toString()
			case .byRating:
				secTitle = row.rating > 0 ? row.getStarRating() : Strings.NONE_VALUE2
			default:
				secTitle = ""
			}
			
			if lastSection?.title != secTitle {
				lastSection = AnimeTableView.Section(title: secTitle, items: [row] )
				self.animeTableView.sections.append(lastSection!)
			}
			else {
				lastSection!.items.append(row)
			}
		}
		
		self.animeTableView?.reloadData()
		self.emptyView?.isHidden = !self.animeTableView.sections.isEmpty
	}
	
	open func createNewItem() -> Anime {
		let calendar = Calendar(identifier: .gregorian)
		let today = Date()
		
		let item = Anime()
		item.startDate = YearMonth(
			year: calendar.component(.year, from: today),
			month: calendar.component(.month, from: today)
		)
		return item
	}

	@objc func addNewItem() {
		let item = createNewItem()
		openEditAnimePage(self, item: item)
	}
	
	@objc func showSortOptions() {
		let currSort = Settings.shared.sortType
		let currIsDesc = Settings.shared.sortDesc
		
		SizAlertBuilder(title: Strings.SORT, style: .actionSheet)
			.addAction(title: Strings.SORT_BY_DATE,
					   style: (currSort == .byDate && !currIsDesc) ? .destructive : .default)
			{ _ in self.sortByDate(asc: true) }
			
			.addAction(title: Strings.SORT_BY_DATE_DESC,
					   style: (currSort == .byDate && currIsDesc) ? .destructive : .default)
			{ _ in self.sortByDate(asc: false) }
			
			.addAction(title: Strings.SORT_BY_RATING,
					   style: (currSort == .byRating && !currIsDesc) ? .destructive : .default)
			{ _ in self.sortByRating(asc: true) }
			
			.addAction(title: Strings.SORT_BY_RATING_DESC,
					   style: (currSort == .byRating && currIsDesc) ? .destructive : .default)
			{ _ in self.sortByRating(asc: false) }
			
			.addAction(title: Strings.SORT_BY_TITLE,
					   style: (currSort == .byTitle && !currIsDesc) ? .destructive : .default)
			{ _ in self.sortByTitle(asc: true) }
			
			.addAction(title: Strings.SORT_BY_TITLE_DESC,
					   style: (currSort == .byTitle && currIsDesc) ? .destructive : .default)
			{ _ in self.sortByTitle(asc: false) }
			
			.addAction(title: Strings.SORT_BY_MEDIA, handler: sortByMedia)
			.addAction(title: Strings.CANCEL, style: .cancel)
			.show(parent: self)
	}
	
	func sortByTitle(asc: Bool) {
		Settings.shared.sortType = .byTitle
		Settings.shared.sortDesc = !asc
		reloadItems()
	}
	
	func sortByDate(asc: Bool) {
		Settings.shared.sortType = .byDate
		Settings.shared.sortDesc = !asc
		reloadItems()
	}
	
	func sortByRating(asc: Bool) {
		Settings.shared.sortType = .byRating
		Settings.shared.sortDesc = !asc
		reloadItems()
	}
	
	func sortByMedia(_ action: UIAlertAction) {
		Settings.shared.sortType = .byMedia
		reloadItems()
	}

	@objc func beginEditMode() {
		if let naviItem = self.navigationBar.topItem {
			naviItem.leftBarButtonItems = []
			naviItem.rightBarButtonItems = [self.btnEndEditMode]
		}
		self.editMode = true
	}
	
	@objc func endEditMode() {
		if let naviItem = self.navigationBar.topItem {
			naviItem.leftBarButtonItems = [self.btnSort]
			naviItem.rightBarButtonItems = [self.btnBeginEditMode,self.btnNew]
		}
		self.editMode = false
	}
	
	@objc func toggleSearchUI() {
		let isHidden = self.searchBar.frame.minY < 0
		if isHidden {
			showSearchBar()
		}
		else {
			hideSearchBar()
		}
	}
	
	private func showSearchBar() {
		UIView.animate(withDuration: 0.3, animations: {
			self.searchBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
		}, completion: { fin in
			if fin {
				self.searchBar.text = nil
				self.searchBar.delegate = self
				self.searchBar.becomeFirstResponder()
				self.animeTableView.tableFooterView?.frame =
					CGRect(x: 0, y: 0, width: 0, height: self.view.frame.height/2.0)
			}
		})
	}
	
	private func hideSearchBar() {
		dismissKeyboard()
		UIView.animate(withDuration: 0.3, animations: {
			self.searchBar.frame = CGRect(x: 0, y: -50, width: self.view.frame.width, height: 50)
		}, completion: { fin in
			if fin {
				self.searchBar.delegate = nil
				self.searchBar.text = nil
				self.searchText = nil
				self.animeTableView.tableFooterView?.frame = .zero
				self.reloadItems()
			}
		})
	}

	
	//------ MARK: SearchBar Delegate
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		self.searchText = searchText
		reloadItems()
	}
	
//	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
//		self.searchText = searchBar.text
//		reloadItems()
//	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		//self.searchText = searchBar.text
		//reloadItems()
		dismissKeyboard()
	}
	
}
