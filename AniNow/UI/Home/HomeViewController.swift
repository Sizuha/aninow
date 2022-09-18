//
//  HomeViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/25.
//  Copyright © 2018 Sizuha's Atelier. All rights reserved.
//

import UIKit
import SQuery
import SizUI
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
    private var countByYear = [Int:Int]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
        initNavigationBar()
		initTableView()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.menuTable.setMatchTo(parent: self.view)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		refresh()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	private func initNavigationBar() {
		navigationController?.delegate = self
		
		btnSettings = UIBarButtonItem(image: Icons.SETTINGS, style: .plain, target: self, action: #selector(showSettings))
		btnNew = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewItem))
		
		navigationItem.title = "AniNow"
		navigationItem.leftBarButtonItems = [btnSettings]
		navigationItem.rightBarButtonItems = [self.btnNew]
	}
	
	private func initTableView() {
		menuTable = SizPropertyTableView(frame: .zero, style: .grouped)
		menuTable.translatesAutoresizingMaskIntoConstraints = false
		
		// MARK: Categories
		menus.append(TableSection(
			title: Strings.LABEL_ANIME_LIST,
			rows: [
                TextCell(label: Strings.ALL_VIEWING, attrs: [
                    .value { "\(self.countOfAll)" },
                    .selected { i in
                        self.menuTable.deselectRow(at: i, animated: true)
                        let nextView = AllViewController()
                        self.navigationController?.pushViewController(nextView, animated: true)
                    }
                ]),
                
                TextCell(label: Strings.NOW_VIEWING, attrs: [
                    .value { "\(self.countOfNow)" },
                    .selected { i in
                        self.menuTable.deselectRow(at: i, animated: true)
                        let nextView = NowViewController()
                        self.navigationController?.pushViewController(nextView, animated: true)
                    }
                ]),
                
                TextCell(label: Strings.END_VIEWING, attrs: [
                    .value { "\(self.countOfFinished)" },
                    .selected { i in
                        self.menuTable.deselectRow(at: i, animated: true)
                        let nextView = FinishedViewController()
                        self.navigationController?.pushViewController(nextView, animated: true)
                    }
                ]),
			]
		))

		menus.append(TableSection(
			title: Strings.FILTER_MEDIA,
			rows: [] //mediaRows
		))

		// MARK: filter: Rating
		menus.append(TableSection(
			title: Strings.FILTER_RATING,
			rows: (0...5).reversed().map { createRatingFilterMenu($0) }
		))
        
        // MARK: filter: Year
        menus.append(TableSection(
            title: Strings.FILTER_YEAR,
            rows: []
        ))

		menuTable.setDataSource(menus)
		view.addSubview(menuTable)
	}
	
    func updateMediaFilters() -> [Int:String] {
        let medias: [Int:String] = AnimeDataManager.shared.loadMedias()
		var mediaRows = [SizPropertyTableRow]()
        mediaRows.reserveCapacity(medias.count)
        
        let sorted = medias.sorted(by: <)
		for (code, label) in sorted {
            guard code > 0 else { continue }
			mediaRows.append(createMediaFilterMenu(code, label: label))
		}
        // Add: 未分類
        mediaRows.append(createMediaFilterMenu(0, label: Strings.NO_CATEGORY))
        
		menus[1].rows = mediaRows
        return medias
	}
    
    func updateYearFilters() -> [Int] {
        let years = AnimeDataManager.shared.getYears()
        var rows = [SizPropertyTableRow]()
        rows.reserveCapacity(years.count + 1)
        
        for year in years {
            rows.append(createYearFilterMenu(year))
        }
        
        menus[3].rows = rows
        return years
    }
	
	private func createMediaFilterMenu(_ media: Int, label: String) -> SizPropertyTableRow{
		SizPropertyTableRow(label: label)
			.value { "\(self.countByMedia[media] ?? 0)" }
			.onSelect { i in
				self.menuTable.deselectRow(at: i, animated: true)
				let nextView = MediaFilteredViewController()
				nextView.mediaFilter = media
				self.navigationController?.pushViewController(nextView, animated: true)
			}
			.onCreate { c, _ in c.textLabel?.textColor = UIColor.defaultText }
	}
	
	private func createRatingFilterMenu(_ rating: Int) -> SizPropertyTableRow{
		SizPropertyTableRow(label: getRatingToStarText(rating))
			.value { "\(self.countByRating[rating] ?? 0)" }
			.onSelect { i in
				self.menuTable.deselectRow(at: i, animated: true)
				let nextView = RatingFilteredViewController()
				nextView.rating = rating
				self.navigationController?.pushViewController(nextView, animated: true)
			}
	}
    
    private func createYearFilterMenu(_ year: Int) -> SizPropertyTableRow{
        let label = year == 0 ? Strings.UNKNOWN : String(format: Strings.FMT_YEAR, year)
        return SizPropertyTableRow(label: label)
            .value { "\(self.countByYear[year] ?? 0)" }
            .onSelect { i in
                self.menuTable.deselectRow(at: i, animated: true)
                let nextView = YearFilteredViewController()
                nextView.year = year
                self.navigationController?.pushViewController(nextView, animated: true)
            }
    }

	@objc func addNewItem() {
        let newItem = Anime()
        newItem.startDate = YearMonth(from: Date())
        
        EditAnimeViewController.presentSheet(from: self, item: newItem) {
            self.refresh()
        }
	}
	
	func refresh() {
		fadeOutWindow(start: 0.0, end: 0.0) { fin in
			guard fin else { return }
			
			self.startNowLoading()
			DispatchQueue.main.async {
				let dm = AnimeDataManager.shared
                let medias = self.updateMediaFilters()
                let years = self.updateYearFilters()

				self.countOfNow = dm.count(finished: false)
				self.countOfFinished = dm.count(finished: true)
				//self.countOfAll = dm.count()
				self.countOfAll = self.countOfNow + self.countOfFinished
				
                // Count: Media別
				for (code, _) in medias {
					self.countByMedia[code] = dm.countWithFilter { f in
                        let _ = f.andWhere("\(Anime.F_MEDIA)=?", code)
					}
				}
                
                // Count: 年度別
                for year in years {
                    self.countByYear[year] = dm.countWithFilter { f in
                        let _ = f.andWhere("\(Anime.F_START_DATE) BETWEEN ? AND ?", year*100, year*100 + 99)
                    }
                }
				
				for rating in 0...5 {
					self.countByRating[rating] = dm.countWithFilter { f in
						let _ = f.andWhere("rating >= ? AND rating < ?", rating, rating+1)
					}
				}
				
				self.menuTable.reloadData()
                
                excuteAutoBackup_ifNeed()
                
				self.stopNowLoading()
				self.fadeInWindow()
			}
		}
	}
	
	@objc func showSettings() {
        SettingsViewController.presentSheet(from: self) {
            print("Settings onDismiss")
            self.refresh()
        }
	}
	
}
