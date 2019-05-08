//
//  AnimeViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/13.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SizUtil

class AnimeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	private var tableView: SizPropertyTableView!
	private var sections = [SizPropertyTableSection]()
	
	private let itemID: Int
	private var item: Anime? = nil
	
	private var headerView: UIView!
	private var txtTitle: UILabel!
	private var txtSubTitle: UILabel!
	private var dispMemo: UITextView?
	
	private let HEADER_HEIGHT = CGFloat(140)
	
	private let medias = AnimeDataManager.shared.loadMedias()
	
	convenience init(item: Anime) {
		self.init(id: item.id)
	}
	
	init(id: Int) {
		self.itemID = id
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
		//super.init(coder: aDecoder)
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = Colors.WIN_BG
		initStatusBar()
		initNaviItems()
		
		let _ = loadItem()

		initTableView()
    }
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		setMatchToParent(parent: view, child: self.tableView)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		refresh()
	}
	
	private func initNaviItems() {
		self.navigationItem.title = ""
		
		let btnEdit = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(showEdit))
		self.navigationItem.rightBarButtonItems = [btnEdit]
	}
	
	private func createHeaderCell() -> UIView {
		self.headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: HEADER_HEIGHT))
		self.headerView.backgroundColor = Colors.WIN_BG
		
		// Title
		self.txtTitle = UILabel()
		self.txtTitle.textAlignment = .center
		self.txtTitle.adjustsFontSizeToFitWidth = true
		self.txtTitle.lineBreakMode = .byTruncatingTail
		self.txtTitle.numberOfLines = 2
		self.txtTitle.font = UIFont.preferredFont(forTextStyle: .title2)
		
		let tapGes = UITapGestureRecognizer(target: self, action: #selector(openLink))
		self.txtTitle.addGestureRecognizer(tapGes)
		self.txtTitle.isUserInteractionEnabled = false
		
		// Sub Title
		self.txtSubTitle = UILabel()
		self.txtSubTitle.textAlignment = .center
		self.txtSubTitle.adjustsFontSizeToFitWidth = true
		self.txtSubTitle.lineBreakMode = .byTruncatingTail
		self.txtSubTitle.numberOfLines = 1
		self.txtSubTitle.font = UIFont.systemFont(ofSize: 11)
		self.txtSubTitle.textColor = .darkGray
		
		self.headerView.addSubview(self.txtSubTitle)
		self.headerView.addSubview(self.txtTitle)
		
		updateHeaderInfo()
		return self.headerView
	}
	
	private func updateHeaderInfo() {
		guard let item = self.item else {
			popSelf()
			return
		}
		
		let maxWidth = view.frame.width - 40
		
		if self.txtSubTitle != nil {
			self.txtSubTitle.text = item.titleOther
			
			self.txtSubTitle.frame = CGRect(x: 20, y: 40, width: maxWidth, height: 20)
			//self.txtSubTitle.sizeToFit()
			//self.txtSubTitle.backgroundColor = .yellow
			
//			if self.txtSubTitle.frame.width < maxWidth {
//				let diffW = view.frame.width - self.txtSubTitle.frame.width
//				self.txtSubTitle.frame = CGRect(
//					x: diffW/2, y: 40,
//					width: self.txtSubTitle.frame.width,
//					height: self.txtSubTitle.frame.height
//				)
//			}
		}
		
		if self.txtTitle != nil {
			if item.link.isEmpty {
				self.txtTitle.attributedText = nil
				self.txtTitle.text = item.title
				self.txtTitle.isUserInteractionEnabled = false
			}
			else {
				self.txtTitle.text = nil
				self.txtTitle.attributedText = item.title.asLinkText()
				self.txtTitle.isUserInteractionEnabled = true
			}
			
			let y = self.txtSubTitle?.frame.maxY ?? 40
			self.txtTitle.frame = CGRect(x: 20, y: y, width: maxWidth, height: 40)
			//self.txtTitle.sizeToFit()
			//self.txtTitle.backgroundColor = .brown
			
//			if self.txtTitle.frame.width < maxWidth {
//				let diffW = view.frame.width - self.txtTitle.frame.width
//				self.txtTitle.frame = CGRect(
//					x: diffW/2, y: y,
//					width: self.txtTitle.frame.width,
//					height: self.txtTitle.frame.height
//				)
//			}
		}
	}
	
	private func initTableView() {
		self.tableView = SizPropertyTableView(frame: view.frame, style: .plain)
		self.tableView.translatesAutoresizingMaskIntoConstraints = false
		self.tableView.backgroundColor = Colors.WIN_BG
		self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: HEADER_HEIGHT))
		
		let section = SizPropertyTableSection(onCreateHeader: createHeaderCell, headerHeight: HEADER_HEIGHT)
		
		// Published Date
		section.rows.append(SizPropertyTableRow(label: Strings.PUB_DATE).bindData {
			self.item?.startDate?.toString()
		})
		
		// Final Ep.
		section.rows.append(SizPropertyTableRow(label: Strings.FINAL_EP).bindData {
			let finalEp: Int = (self.item?.total ?? 0) > 0 ? self.item!.total : 0
			return finalEp > 0 ? "\(finalEp)" : Strings.NONE_VALUE
		})
		
		// Current Ep.
		if self.item?.finished != true {
			section.rows.append(SizPropertyTableRow(type: .stepper, label: Strings.LABEL_CURR_EP)
				.bindData {
					let currEp: Float = (self.item?.progress ?? 0) > 0 ? self.item!.progress : 0
					return Double(currEp)
				}
				.onCreate { c, _ in
					if let cell = c as? SizCellForStepper {
						cell.enableConvertIntWhenChanged = true
						cell.minValue = 0
						cell.maxValue = 9999
					}
				}
				.onChanged { value in
					if let value = value as? Double {
						let _ = AnimeDataManager.shared.updateProgress(id: self.itemID, progress: Float(value))
					}
				}
			)
		}
		
		// Media
		section.rows.append(SizPropertyTableRow(label: Strings.MEDIA).bindData {
			self.medias[self.item?.media ?? 0]
		})
		
		// Rating
		section.rows.append(SizPropertyTableRow(type: .rating, label: Strings.RATING)
			.bindData { Double(self.item?.rating ?? 0) }
			.onCreate { c, _ in
				if let cell = c as? SizCellForRating {
					cell.ratingBar.emptyImage = Icons.STAR5_EMPTY
					cell.ratingBar.fullImage = Icons.STAR5_FILL
					cell.ratingBar.isUserInteractionEnabled = false
				}
			}
		)
		
		// Memo
		section.rows.append(SizPropertyTableRow(type: .multiLine)
			.onHeight {
				if let memoView = self.dispMemo {
					if memoView.text.isEmpty { return DEFAULT_HEIGHT }
					memoView.sizeToFit()
					return memoView.frame.height + SizCellForMultiLine.paddingVertical*2
				}
				return DEFAULT_HEIGHT
			}
			.bindData { self.item?.memo }
			.hint(Strings.EMPTY_MEMO)
			.onCreate { c, _ in
				if let cell = c as? SizCellForMultiLine {
					self.dispMemo = cell.textView
				}
		})
		
		self.sections.append(section)
		self.tableView.setDataSource(self.sections)
		view.addSubview(self.tableView)
	}
	
	@objc func showEdit() {
		let editNaviController = UINavigationController()
		
		let editView = EditAnimeViewController()
		if let item = item {
			editView.setItem(item)
		}
		editNaviController.pushViewController(editView, animated: false)
		
		present(editNaviController, animated: true, completion: nil)
		//self.navigationController?.pushViewController(editView, animated: true)
	}
	
	@objc func openLink() {
		guard let url = URL(string: self.item?.link ?? "") else { return }
		UIApplication.shared.open(url)
	}
	
	private func loadItem() -> Bool {
		guard let item = AnimeDataManager.shared.loadDetail(id: itemID) else {
			popSelf()
			return false
		}
		self.item = item
		return true
	}
	
	func refresh() {
		if loadItem() {
			self.tableView.reloadData()
		}
	}
	
	//------ TableView Delegate

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return UITableViewCell()
	}

}
