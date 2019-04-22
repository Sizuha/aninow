//
//  AnimeEdit.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/04.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit
import SizUtil

class EditAnimeViewController:
	CommonUIViewController,
	UITextFieldDelegate,
	SizPopupPickerViewDelegate,
	UIPickerViewDataSource
{
	
	private var navigationBar: UINavigationBar!
	
	private var modeNewItem = false
	
	private var editItem: Anime!
	
	private var editTableView: SizPropertyTableView!
	private var sections: [SizPropertyTableSection] = []
	
	//--- Edit Items ---
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
	
	private var pickerPubDate: SizPopupPickerView!
	
	private var yearList = [(Int,String)]()
	private var monthList = [(Int,String)]()
	private let calendar = Calendar(identifier: .gregorian)
	private let today = Date()
	
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
		initTableView()
		//setupKeyboardDismissRecognizer(view: editTableView)
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		initTableViewPositions()
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

		initNavigationBarStyle(self.navigationBar)
	}
	
	private func initPubDatePicker() {
		self.yearList.append( (0, Strings.UNKNOWN) )
		let todayYear = self.calendar.component(.year, from: self.today)
		for y in stride(from: todayYear, to: BEGIN_OF_YEAR-1, by: -1) {
			self.yearList.append( (y, String(format: Strings.FMT_YEAR, y)) )
		}
		
		self.monthList.append( (0, Strings.UNKNOWN) )
		for m in 1...12 {
			self.monthList.append( (m, String(format: Strings.FMT_MONTH, m)) )
		}
		
		self.pickerPubDate = SizPopupPickerView()
		self.pickerPubDate.setDataSource(self)
		self.pickerPubDate.delegate = self
		if let window = UIApplication.shared.keyWindow {
			window.addSubview(self.pickerPubDate)
		}
		else {
			self.view.addSubview(self.pickerPubDate)
		}
	}
	
	private func initTableView() {
		self.sections.append(SizPropertyTableSection(rows: [
			// Title
			SizPropertyTableRow(type: .editText)
				.bindData { self.editItem.title }
				.hint(Strings.ANIME_TITLE)
				.onCreate { c in
					if let cell = c as? SizCellForEditText {
						self.editTitle = cell.textField
						self.editTitle?.clearButtonMode = .whileEditing
						cell.maxLength = 200
						cell.delegate = self
					}
				}
				.onChanged { value in self.editItem.title = value as? String ?? "" }
			
			// Title Other
			,SizPropertyTableRow(type: .editText)
				.bindData { self.editItem.titleOther }
				.hint(Strings.ANIME_TITLE_2ND)
				.onCreate { c in
					if let cell = c as? SizCellForEditText {
						self.editTitleOther = cell.textField
						self.editTitleOther?.clearButtonMode = .whileEditing
						cell.maxLength = 200
						cell.delegate = self
					}
				}
				.onChanged { value in self.editItem.titleOther = value as? String ?? "" }
			
			// URL
			,SizPropertyTableRow(type: .editText)
				.bindData { self.editItem.link }
				.hint("URL")
				.onCreate { c in
					if let cell = c as? SizCellForEditText {
						self.editUrl = cell.textField
						self.editUrl?.keyboardType = .URL
						self.editUrl?.returnKeyType = .done
						self.editUrl?.clearButtonMode = .whileEditing
						
						cell.maxLength = 250
						cell.delegate = self
					}
				}
				.onChanged { value in self.editItem.link = value as? String ?? "" }
		]))
		
		let progressFmt = NumberFormatter()
		progressFmt.minimumFractionDigits = 0
		progressFmt.maximumFractionDigits = 1
		
		if self.editItem.total <= 0 { self.editItem.total = 0 }
		if self.editItem.progress <= 0 { self.editItem.progress = 0 }
		
		self.sections.append(SizPropertyTableSection(rows: [
			// Finished
			SizPropertyTableRow(type: .onOff, label: Strings.LABEL_FIN)
				.bindData { self.editItem.finished }
				.tintColor(Colors.ACTION)
				.onCreate { c in
					if let cell = c as? SizCellForOnOff {
						self.editFinished = cell.switchCtrl
						cell.switchCtrl.thumbTintColor = Colors.NAVI_BG
						cell.switchCtrl.onTintColor = Colors.ACTION
					}
				}
				.onChanged { value in self.editItem.finished = value as? Bool == true }
			
			// Final Episode
			,SizPropertyTableRow(type: .editText, label: Strings.FINAL_EP)
				.bindData { self.editItem.total > 0 ? String(self.editItem.total) : "" }
				.hint("00")
				.onCreate { c in
					if let cell = c as? SizCellForEditText {
						self.editTotal = cell.textField
						self.editTotal?.keyboardType = .numberPad
						cell.maxLength = 4
					}
				}
				.onChanged { value in
					self.editItem.total = Int(value as? String ?? "0") ?? 0
				}
			
			// Current Episode
			,SizPropertyTableRow(type: .editText, label: Strings.LABEL_CURR_EP)
				.bindData {
					self.editItem.progress > 0
						? progressFmt.string(for: self.editItem.progress)
						: ""
				}
				.hint("00")
				.onCreate { c in
					if let cell = c as? SizCellForEditText {
						self.editProgress = cell.textField
						self.editProgress?.keyboardType = .decimalPad
						cell.maxLength = 5
					}
				}
				.onChanged { value in
					self.editItem.progress = Float(value as? String ?? "0") ?? 0
				}
			
			// Published Date
			,SizPropertyTableRow(label: Strings.PUB_DATE)
				.bindData { self.editItem.startDate?.toString() ?? Strings.UNKNOWN }
				.onSelect { i in
					self.showPubDatePicker()
					self.editTableView.deselectRow(at: i, animated: false)
				}
				.onCreate { c in self.dispPubDate = c.detailTextLabel }
			
			// Media
			,SizPropertyTableRow(label: Strings.MEDIA)
				.bindData { self.editItem.media.toString() }
				.onSelect { i in
					self.showChoiceMedia()
					self.editTableView.deselectRow(at: i, animated: false)
				}
				.onCreate { c in self.dispMedia = c.detailTextLabel }
			
			// Rating
			,SizPropertyTableRow(type: .rating, label: Strings.RATING)
				.bindData { Double(self.editItem.rating) }
				.onCreate { c in
					self.editRating = (c as? SizCellForRating)?.ratingBar
					self.editRating?.emptyImage = Icons.STAR5_EMPTY
					self.editRating?.fullImage = Icons.STAR5_FILL
				}
				.onChanged { value in
					self.editItem.rating = Float(value as? Double ?? 0)
				}
		]))
		
		self.sections.append(SizPropertyTableSection(rows: [
			// Memo
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
				.bindData { self.editItem.memo }
				.hint(Strings.MEMO)
				.onSelect { i in
					self.showEditMemo()
					self.editTableView.deselectRow(at: i, animated: true)
				}
				.onCreate { c in
					if let cell = c as? SizCellForMultiLine {
						self.cellMemo = cell
						self.dispMemo = cell.textView
						self.dispMemoHint = cell.placeholderView						
					}
				}
		]))
		
		if !modeNewItem { // Delete
			self.sections.append(SizPropertyTableSection(rows: [
				SizPropertyTableRow(type: .button, label: Strings.REMOVE)
					.tintColor(.red)
					.onSelect { i in
						self.editTableView.deselectRow(at: i, animated: false)
						self.tryRemove()
					}
					.onCreate { c in
						if let cell = c as? SizCellForButton {
							cell.textLabel?.textAlignment = .center
						}
					}
			]))
		}
		
		self.editTableView = SizPropertyTableView(frame: .zero, style: .grouped)
		self.editTableView.translatesAutoresizingMaskIntoConstraints = false
		self.editTableView.setDataSource(sections)
		self.view.addSubview(self.editTableView)
	}
	
	private func initTableViewPositions() {
		setMatchToParent(parent: self.view, child: self.editTableView)
	}
	
	//------ UITextFieldDelegate
	
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
	
	//------ SizPopupPickerViewDelegate
	
	func pickerView(pickerView: UIPickerView, didSelect numbers: [Int]) {
		if self.editItem.startDate == nil {
			self.editItem.startDate = YearMonth()
		}
		
		if let pubDate = self.editItem.startDate {
			pubDate.year = self.yearList[numbers[0]].0
			pubDate.month = numbers[1]
			self.dispPubDate?.text = pubDate.toString()
		}
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 2
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		switch component {
		case 0: return self.yearList.count
		case 1: fallthrough
		default: return self.monthList.count
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		switch component {
		case 0: return yearList[row].1
		case 1: fallthrough
		default: return monthList[row].1
		}
	}
	
	//------ Body
	
	@objc func returnBack() {
		dismissKeyboard()
		popSelf()
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
				popSelf()
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
		SizAlertBuilder(title: Strings.MEDIA, style: .actionSheet)
			.addAction(title: Strings.NONE_VALUE) { _ in
				self.editItem.media = .none
				self.dispMedia?.text = self.editItem.media.toString()
			}
			.addAction(title: "TV") { _ in
				self.editItem.media = .tv
				self.dispMedia?.text = self.editItem.media.toString()
			}
			.addAction(title: "OVA") { _ in
				self.editItem.media = .ova
				self.dispMedia?.text = self.editItem.media.toString()
			}
			.addAction(title: "Movie") { _ in
				self.editItem.media = .movie
				self.dispMedia?.text = self.editItem.media.toString()
			}
			.addAction(title: Strings.CANCEL, style: .cancel)
			.show(parent: self)
	}
	
	private func showPubDatePicker() {
		let selYear: Int = self.editItem.startDate?.year ?? 0
		let selMonth: Int = self.editItem.startDate?.month ?? 0
		
		var idx = 0
		var idxY = 0
		for y in self.yearList {
			if y.0 == selYear {
				idxY = idx
				break
			}
			idx += 1
		}
		
		idx = 0
		var idxM = 0
		for m in self.monthList {
			if m.0 == selMonth {
				idxM = idx
				break
			}
			idx += 1
		}
		
		fadeOut()
		
		self.pickerPubDate.selectedRows = [idxY, idxM]
		self.pickerPubDate.onHidden = { self.fadeIn() }
		self.pickerPubDate.show()
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
	
}
