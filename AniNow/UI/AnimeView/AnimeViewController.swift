//
//  AnimeViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/13.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SizUI
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
	
	private var ratingBar: FloatRatingView!
	private func applyRatingBarImages(_ ratingBar: FloatRatingView) {
		let empty = Icons.STAR5_EMPTY
		let full = Icons.STAR5_FILL
        ratingBar.emptyImage = empty.withTintColor(.defaultText)
		ratingBar.fullImage = full.withTintColor(.defaultText)
	}
    
    private var stepperEp: UIStepper! = nil
	
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
		initNaviItems()
		
		let _ = loadItem()

		initTableView()
    }
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.tableView.setMatchTo(parent: self.view)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		refresh()
	}
	
	private func initNaviItems() {
		let btnEdit = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(showEdit))
		self.navigationItem.rightBarButtonItems = [btnEdit]
	}
	
	private func createHeaderCell() -> UIView {
		self.headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: HEADER_HEIGHT))
		
		// Title
		self.txtTitle = UILabel()
		self.txtTitle.textAlignment = .center
		self.txtTitle.adjustsFontSizeToFitWidth = true
		self.txtTitle.lineBreakMode = .byTruncatingTail
		self.txtTitle.numberOfLines = 2
		self.txtTitle.font = UIFont.preferredFont(forTextStyle: .title2)
		
//		let tapGes = UITapGestureRecognizer(target: self, action: #selector(openLink))
//		self.txtTitle.addGestureRecognizer(tapGes)
//		self.txtTitle.isUserInteractionEnabled = false
		
		// Sub Title
		self.txtSubTitle = UILabel()
		self.txtSubTitle.textAlignment = .center
		self.txtSubTitle.adjustsFontSizeToFitWidth = true
		self.txtSubTitle.lineBreakMode = .byTruncatingTail
		self.txtSubTitle.numberOfLines = 1
		self.txtSubTitle.font = UIFont.systemFont(ofSize: 11)
		self.txtSubTitle.textColor = .inputText
		
		self.headerView.addSubview(self.txtSubTitle)
		self.headerView.addSubview(self.txtTitle)
		
		updateHeaderInfo()
		return self.headerView
	}
	
	private func updateHeaderInfo() {
		guard let item = self.item else {
			fatalError()
		}
		//title = item.title
        
		let maxWidth = view.frame.width - 40
		
		if self.txtSubTitle != nil {
			self.txtSubTitle.text = item.titleOther
			
			self.txtSubTitle.frame = CGRect(x: 20, y: 40, width: maxWidth, height: 20)
		}
		
		if self.txtTitle != nil {
			//if item.link.isEmpty {
				self.txtTitle.attributedText = nil
				self.txtTitle.text = item.title
				self.txtTitle.isUserInteractionEnabled = false
			/*}
			else {
				self.txtTitle.text = nil
				self.txtTitle.attributedText = item.title.asLinkText()
				self.txtTitle.isUserInteractionEnabled = true
			}*/
			
			let y = self.txtSubTitle?.frame.maxY ?? 40
			self.txtTitle.frame = CGRect(x: 20, y: y, width: maxWidth, height: 40)
		}
	}
	
	private func initTableView() {
		self.tableView = SizPropertyTableView(frame: view.frame, style: .plain)
		self.tableView.translatesAutoresizingMaskIntoConstraints = false
		self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: HEADER_HEIGHT))
        
		let section = createSections()
		self.sections.append(section)
		self.tableView.setDataSource(self.sections)
        
		view.addSubview(self.tableView)
	}
    
    private func recreateSection() {
        let section = createSections()
        self.sections.removeAll()
        self.sections.append(section)
        self.tableView.setDataSource(self.sections)
    }
    
    private func createSections() -> TableSection {
        let section = TableSection(onCreateHeader: createHeaderCell, headerHeight: HEADER_HEIGHT)
        
        // Published Date
        section.rows.append(TextCell(label: Strings.PUB_DATE, attrs: [
            .read { self.item?.startDate?.toString() }
        ]))
        
        // MARK: Final Ep.
        section.rows.append(TextCell(label: Strings.FINAL_EP, attrs: [
            .read {
                let finalEp: Int = (self.item?.total ?? 0) > 0 ? self.item!.total : 0
                return finalEp > 0 ? "\(finalEp)" : Strings.NONE_VALUE
            }
        ]))
        
        // MARK: Current Ep.
        section.rows.append(StepperCell(label: Strings.LABEL_CURR_EP, attrs: [
            .read {
                let currEp: Float = (self.item?.progress ?? 0) > 0 ? self.item!.progress : 0
                return Double(currEp)
            },
            .created { c, _ in
                let cell = StepperCell.cellView(c)
                cell.enableConvertIntWhenChanged = true
                cell.minValue = 0
                cell.maxValue = 9999
                cell.stepper.isHidden = self.item?.finished == true
                self.stepperEp = cell.stepper
            },
            .valueChanged { value in
                if let value = value as? Double {
                    let _ = AnimeDataManager.shared.updateProgress(id: self.itemID, progress: Float(value))
                }
            }
        ]))

        // MARK: Media
        section.rows.append(TextCell(label: Strings.MEDIA, attrs: [
            .read { self.medias[self.item?.media ?? 0] }
        ]))
        
        // MARK: URL
        if let url = item?.link, !url.isEmpty {
            section.rows.append(TextCell(label: "URL", attrs: [
                .read { self.item?.link },
                .created { c, _ in
                    let cell = TextCell.cellView(c)
                    cell.detailTextLabel?.textColor = .link
                    cell.accessoryType = .detailButton
                },
                .selected { i in
                    self.tableView.deselectRow(at: i, animated: true)
                    self.openLink()
                }
            ]))
        }
        
        // MARK: Rating
        section.rows.append(RatingCell(label: Strings.RATING, attrs: [
            .read { Double(self.item?.rating ?? 0) },
            .created { c, _ in
                let cell = RatingCell.cellView(c)
                self.applyRatingBarImages(cell.ratingBar)
                cell.ratingBar.isUserInteractionEnabled = false
                self.ratingBar = cell.ratingBar
            }
        ]))
        
        // MARK: Memo
        section.rows.append(SizPropertyTableRow(type: .multiLine)
            .onHeight {
                if let memoView = self.dispMemo {
                    if memoView.text.isEmpty { return DEFAULT_HEIGHT }
                    memoView.sizeToFit()
                    return memoView.frame.height + SizCellForMultiLine.paddingVertical*2
                }
                return DEFAULT_HEIGHT
            }
            .dataSource { self.item?.memo }
            .hint(Strings.EMPTY_MEMO)
            .onCreate { c, _ in
                if let cell = c as? SizCellForMultiLine {
                    self.dispMemo = cell.textView
                }
        })
        
        return section
    }
	
	@objc func showEdit() {
        EditAnimeViewController.presentSheet(from: self, item: self.item) {
            self.refresh()
        }
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
        updateHeaderInfo()
		if loadItem() {
            recreateSection()
			tableView.reloadData()
		}
        
        stepperEp?.isHidden = item?.finished == true
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		guard let ratingBar = self.ratingBar else { return }
		applyRatingBarImages(ratingBar)
	}
	
	//------ TableView Delegate

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return UITableViewCell()
	}

}
