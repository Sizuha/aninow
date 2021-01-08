//
//  AnimeEdit.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/04.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SizUtil
import SizUI

class EditAnimeViewController: CommonUIViewController, UITextFieldDelegate {
	
    static func presentSheet(from: UIViewController, item: Anime? = nil, onDismiss: @escaping ()->Void) {
        let editNaviController = UINavigationController()
        editNaviController.setDisablePullDownDismiss()
        
        let editView = EditAnimeViewController()
        editView.onDismiss = onDismiss
        if let item = item { editView.setItem(item) }
        
        editNaviController.pushViewController(editView, animated: false)
        from.present(editNaviController, animated: true, completion: nil)
    }
    
	private var navigationBar: UINavigationBar!
    private var onDismiss: (()->Void)? = nil
	
	private var modeNewItem = false
	
	private var editItem: Anime!
	
	private var editTableView: SizPropertyTableView!
	private var sections: [SizPropertyTableSection] = []
	
	// MARK: --- Edit Items ---
	private var editTitle: UITextField?
	private var editTitleOther: UITextField?
	
	private var editFinished: UISwitch?
	private var editTotal: UITextField?
	private var editProgress: UITextField?
	private var dispPubDate: UILabel?
	private var dispMedia: UILabel?
	private var editRating: FloatRatingView?
	
	private var editUrl: UITextField?
	private var dispMemo: UITextView?
	private var dispMemoHint: UILabel?
	private var cellMemo: SizCellForMultiLine?
	
	private var pickerPubDate: DatePickerView!
	private var pickerMedia: MediaPickerView!
	
	private let medias = AnimeDataManager.shared.loadMedias()
	
	private func applyRatingBarImages(_ ratingBar: FloatRatingView) {
        ratingBar.emptyImage = Icons.STAR5_EMPTY.withTintColor(view.tintColor)
		ratingBar.fullImage = Icons.STAR5_FILL.withTintColor(view.tintColor)
	}

	
	func setItem(_ item: Anime) {
		self.editItem = item
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()		
		initNavigationBar()
		initNaviItems()
		addFadeView()
		
		self.modeNewItem = (self.editItem?.id ?? -1) < 0
		if self.modeNewItem {
			title = Strings.ADD_NEW
			if self.editItem == nil { self.editItem = Anime() }
		}
		else {
			title = Strings.EDIT
			self.editItem = AnimeDataManager.shared.loadDetail(id: self.editItem!.id)!
		}
		
		initPubDatePicker()
		initMedaiPicker()
		
		initTableView()
		//setupKeyboardDismissRecognizer(view: editTableView)
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		initTableViewPositions()
	}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDismiss?()
    }
	
	private func initNaviItems() {
		self.navigationItem.title = title
		
		let btnSave = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(trySave))
		self.navigationItem.rightBarButtonItems = [btnSave]
		
		if self.navigationController?.viewControllers.first == self {
			let backBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(returnBack))
			self.navigationItem.leftBarButtonItems = [backBtn]
		}
	}
	
	private func initNavigationBar() {
		self.navigationBar = self.navigationController?.navigationBar
		guard self.navigationBar != nil else { return }
	}
	
	private func initPubDatePicker() {
		pickerPubDate = DatePickerView()
		pickerPubDate.onHidden = { self.fadeIn() }
		pickerPubDate.onSelected = { numbers in
			if self.editItem.startDate == nil {
				self.editItem.startDate = YearMonth()
			}
			
			if let pubDate = self.editItem.startDate {
				pubDate.year = self.pickerPubDate.years[numbers[0]].0
				pubDate.month = numbers[1]
				self.dispPubDate?.text = pubDate.toString()
			}
		}
		
		if let window = getKeyWindow() {
			window.addSubview(pickerPubDate)
		}
		else {
			view.addSubview(pickerPubDate)
		}
	}
	
	private func initMedaiPicker() {
		pickerMedia = MediaPickerView()
		pickerMedia.onHidden = { self.fadeIn() }
		pickerMedia.onSelected = { number in
			let (code, label) = self.pickerMedia.medias[number]
			self.editItem.media = code
			self.dispMedia?.text = label
		}
		
		if let window = getKeyWindow() {
			window.addSubview(pickerMedia)
		}
		else {
			view.addSubview(pickerMedia)
		}
	}
	
	private func initTableView() {
		self.sections.append(TableSection(rows: [
			// MARK: Title
			EditTextCell(attrs: [
                .read { self.editItem.title },
                .hint(Strings.ANIME_TITLE),
                .created { c, _ in
                    let cell = EditTextCell.cellView(c)
                    self.editTitle = cell.textField
                    self.editTitle?.clearButtonMode = .always
                    cell.maxLength = 200
                    cell.delegate = self
                },
                .valueChanged { value in self.editItem.title = value as? String ?? "" }
            ]),
			
			// MARK: Title Other
            EditTextCell(attrs: [
                .read { self.editItem.titleOther },
                .hint(Strings.ANIME_TITLE_2ND),
                .created { c, _ in
                    let cell = EditTextCell.cellView(c)
                    self.editTitleOther = cell.textField
                    self.editTitleOther?.clearButtonMode = .always
                    cell.maxLength = 200
                    cell.delegate = self
                },
                .valueChanged { value in self.editItem.titleOther = value as? String ?? "" }
            ]),
			
			// MARK: URL
			EditTextCell(attrs: [
				.read { self.editItem.link },
				.hint("URL"),
				.created { c, _ in
					let cell = EditTextCell.cellView(c)
                    self.editUrl = cell.textField
                    self.editUrl?.autocapitalizationType = .none
                    self.editUrl?.keyboardType = .URL
                    self.editUrl?.returnKeyType = .done
                    self.editUrl?.clearButtonMode = .always
                    
                    cell.maxLength = 250
                    cell.delegate = self
				},
				.valueChanged { value in self.editItem.link = value as? String ?? "" }
            ])
		]))
		
		let progressFmt = NumberFormatter()
		progressFmt.minimumFractionDigits = 0
		progressFmt.maximumFractionDigits = 1
		
		if self.editItem.total <= 0 { self.editItem.total = 0 }
		if self.editItem.progress <= 0 { self.editItem.progress = 0 }
		
		self.sections.append(TableSection(rows: [
			// MARK: Finished
            OnOffCell(label: Strings.LABEL_FIN, attrs: [
                .read { self.editItem.finished },
                .created { c, _ in
                    let cell = OnOffCell.cellView(c)
                    cell.switchCtrl.isUserInteractionEnabled = false
                    self.editFinished = cell.switchCtrl
                    //cell.switchCtrl.thumbTintColor = self.isDarkMode ? .white : .black
                },
                .selected { i in
                    self.editTableView.deselectRow(at: i, animated: true)
                    self.editItem.finished.toggle()
                    self.editFinished?.setOn(self.editItem.finished, animated: true)
                },
                .valueChanged { value in self.editItem.finished = value as? Bool == true }
            ]),
			
			// MARK: Final Episode
            EditTextCell(label: Strings.FINAL_EP, attrs: [
                .read { self.editItem.total > 0 ? String(self.editItem.total) : "" },
                .hint("00"),
                .created { c, _ in
                    let cell = EditTextCell.cellView(c)
                    self.editTotal = cell.textField
                    self.editTotal?.keyboardType = .numberPad
                    self.editTotal?.clearButtonMode = .always
                    cell.maxLength = 4
                },
                .valueChanged { value in
                    self.editItem.total = Int(value as? String ?? "0") ?? 0
                }
            ]),
			
			// MARK: Current Episode
            EditTextCell(label: Strings.LABEL_CURR_EP, attrs: [
                .read {
                    self.editItem.progress > 0
                        ? progressFmt.string(for: self.editItem.progress)
                        : ""
                },
                .hint("00"),
                .created { c, _ in
                    let cell = EditTextCell.cellView(c)
                    self.editProgress = cell.textField
                    self.editProgress?.keyboardType = .decimalPad
                    self.editProgress?.clearButtonMode = .always
                    cell.maxLength = 5
                },
                .valueChanged { value in
                    self.editItem.progress = Float(value as? String ?? "0") ?? 0
                }
            ]),
			
			// MARK: Published Date
            TextCell(label: Strings.PUB_DATE, attrs: [
                .read { self.editItem.startDate?.toString() ?? Strings.UNKNOWN },
                .selected { i in
                    self.showPubDatePicker()
                    self.editTableView.deselectRow(at: i, animated: false)
                },
                .created { c, _ in self.dispPubDate = c.detailTextLabel }
            ]),
			
			// MARK: Media
            TextCell(label: Strings.MEDIA, attrs: [
                .read { self.medias[self.editItem.media] },
                .selected { i in
                    self.showChoiceMedia()
                    self.editTableView.deselectRow(at: i, animated: false)
                },
                .created { c, _ in self.dispMedia = c.detailTextLabel }
            ]),
			
			// MARK: Rating
			RatingCell(label: Strings.RATING, attrs: [
                .read { Double(self.editItem.rating) },
                .created { c, _ in
                    self.editRating = RatingCell.cellView(c).ratingBar
                    self.editRating?.editable = false
                    self.applyRatingBarImages(self.editRating!)
                },
                .selected { i in
                    self.editTableView.deselectRow(at: i, animated: true)
                    self.showRatingSelection()
                },
                /*.valueChanged { value in
                    self.editItem.rating = Float(value as? Double ?? 0)
                }*/
            ])
		]))
		
		self.sections.append(TableSection(rows: [
			// MARK: Memo
			SizPropertyTableRow(type: .multiLine)
				.onHeight {
					if let memoView = self.dispMemo {
						if memoView.text.isEmpty {
							return DEFAULT_HEIGHT
						}
						memoView.sizeToFit()
						return memoView.frame.height + SizCellForMultiLine.paddingVertical*2
					}
					return DEFAULT_HEIGHT
				}
				.dataSource { self.editItem.memo }
				.hint(Strings.MEMO)
				.onSelect { i in
					self.showEditMemo()
					self.editTableView.deselectRow(at: i, animated: true)
				}
				.onCreate { c, _ in
					if let cell = c as? SizCellForMultiLine {
						self.cellMemo = cell
						self.dispMemo = cell.textView
						self.dispMemoHint = cell.placeholderView						
					}
				}
		]))
		
		if !modeNewItem { // MARK: Delete
			self.sections.append(TableSection(rows: [
				ButtonCell(label: Strings.REMOVE, attrs: [
                    .tintColor(.red),
                    .selected { i in
                        self.editTableView.deselectRow(at: i, animated: false)
                        self.tryRemove()
                    },
                    .created { c, _ in
                        let cell = ButtonCell.cellView(c)
                        cell.textLabel?.textAlignment = .center
                    }
                ])
			]))
		}
		
		self.editTableView = SizPropertyTableView(frame: .zero, style: .grouped)
		self.editTableView.translatesAutoresizingMaskIntoConstraints = false
		self.editTableView.setDataSource(sections)
		self.view.addSubview(self.editTableView)
	}
	
	private func initTableViewPositions() {
		self.editTableView.setMatchTo(parent: self.view)
	}
    
    func showRatingSelection() {
        SizAlertBuilder(title: Strings.RATING, style: .actionSheet)
            .addAction(title: "☆☆☆☆☆", style: .default) { _ in self.changeRating(0) }
            .addAction(title: "★☆☆☆☆", style: .default) { _ in self.changeRating(1) }
            .addAction(title: "★★☆☆☆", style: .default) { _ in self.changeRating(2) }
            .addAction(title: "★★★☆☆", style: .default) { _ in self.changeRating(3) }
            .addAction(title: "★★★★☆", style: .default) { _ in self.changeRating(4) }
            .addAction(title: "★★★★★", style: .default) { _ in self.changeRating(5) }
            .addAction(title: Strings.CANCEL, style: .cancel)
            .show(parent: self)
    }
    
    func changeRating(_ rating: Float) {
        self.editRating?.rating = Double(rating)
        self.editItem.rating = rating
    }
	
	// MARK: - UITextFieldDelegate
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField.returnKeyType == .done {
			textField.resignFirstResponder()
		}
		else {
			switch textField {
			case self.editTitle:
				self.editTitleOther?.becomeFirstResponder()
			case self.editTitleOther:
				self.editUrl?.becomeFirstResponder()
			default:
				textField.resignFirstResponder()
			}
		}
		
		return true
	}
	
	// MARK: - Body
	
	@objc func returnBack() {
		dismissKeyboard()
        dismiss(animated: true, completion: nil)
	}
	
	@objc func trySave() {
		applyEditData()
		
		if checkValidateData() {
			save()
		}
	}
	
	func save() {
		dismissKeyboard()
		if let item = self.editItem {
			let result = self.modeNewItem
				? AnimeDataManager.shared.addItem(item)
				: AnimeDataManager.shared.updateItem(item)
			
			if result {
				dismiss(animated: true, completion: nil)
			}
			else {
				let dlg = createAlertDialog(title: Strings.ADD_NEW, message: Strings.ERR_FAIL_SAVE, buttonText: Strings.OK)
				present(dlg, animated: true, completion: nil)
			}
		}
		else {
			assertionFailure("editItem is nil")
		}
	}
	
	func tryRemove() {
		SizAlertBuilder(message: Strings.MSG_CONFIRM_REMOVE)
			.addAction(title: Strings.CANCEL)
			.addAction(title: Strings.REMOVE, style: .destructive) { _ in self.remove() }
			.show(parent: self)
	}
	
	func remove() {
		if let item = editItem {
			if AnimeDataManager.shared.removeItem(id: item.id) {
				popSelf()
			}
			else {
				let dlg = createAlertDialog(title: Strings.REMOVE, message: Strings.ERR_FAIL_REMOVE, buttonText: Strings.OK)
				present(dlg, animated: true, completion: nil)
			}
		}
		else {
			assertionFailure("editItem is nil")
		}
	}
	
	private func applyEditData() {
		self.editItem.title = (self.editTitle?.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		self.editItem.titleOther = (self.editTitleOther?.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		
		self.editItem.total = Int(self.editTotal?.text ?? "") ?? 0
		if self.editItem.total < 0 { self.editItem.total = 0 }
		
		self.editItem.progress = Float(self.editProgress?.text ?? "") ?? 0.0
		if self.editItem.progress < 0 { self.editItem.progress = 0.0 }
		
		self.editItem.finished = self.editFinished?.isOn == true
		
		self.editItem.link = (editUrl?.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		if !self.editItem.link.isEmpty && !self.editItem.link.starts(with: "http") {
			self.editItem.link = "http://\(self.editItem.link)"
		}
		
		self.editItem.rating = Float(self.editRating?.rating ?? 0)
	}
	
	private func checkValidateData() -> Bool {
		var valid = true
		
		if self.editItem.title.isEmpty {
			valid = false
			
			let dlg = createAlertDialog(
				title: "登録エラー",
				message: "タイトルが空です",
				buttonText: Strings.OK) { _ in self.editTitle?.becomeFirstResponder() }
			present(dlg, animated: true)
		}

		return valid
	}
	
	private func showChoiceMedia() {
		var selIdx = 0
		for (code, _) in pickerMedia.medias {
			if code == editItem.media { break }
			selIdx += 1
		}
		
		fadeOut()
		
		pickerMedia.selectedRows = [selIdx]
		pickerMedia.show()
	}
	
	private func showPubDatePicker() {
		let selYear: Int = self.editItem.startDate?.year ?? 0
		let selMonth: Int = self.editItem.startDate?.month ?? 0
		
		var idx = 0
		var idxY = 0
		for y in pickerPubDate.years {
			if y.0 == selYear {
				idxY = idx
				break
			}
			idx += 1
		}
		
		idx = 0
		var idxM = 0
		for m in pickerPubDate.months {
			if m.0 == selMonth {
				idxM = idx
				break
			}
			idx += 1
		}
		
		fadeOut()
		
		pickerPubDate.selectedRows = [idxY, idxM]
		pickerPubDate.show()
	}

	private func showEditMemo() {
		let editMemoCtrl = EditAnimeMemoController()
		editMemoCtrl.value = self.editItem.memo
		editMemoCtrl.onChanged = onMemoChanged
		self.navigationController?.pushViewController(editMemoCtrl, animated: true)
	}
	
	private func onMemoChanged(_ text: String) {
		self.editTableView.beginUpdates()
		
		self.dispMemo?.text = text
		self.editItem.memo = text
		self.dispMemoHint?.isHidden = !text.isEmpty
		
		self.editTableView.endUpdates()
		self.cellMemo?.refreshViews()
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		guard let ratingBar = self.editRating else { return }
		applyRatingBarImages(ratingBar)
	}
	
}
