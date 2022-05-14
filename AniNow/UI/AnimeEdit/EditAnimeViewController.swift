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
    
    static func push(to navi: UINavigationController, item: Anime? = nil) {
        let editView = EditAnimeViewController()
        if let item = item { editView.setItem(item) }
        
        navi.pushViewController(editView, animated: true)
    }
	
    static func presentSheet(from: UIViewController, item: Anime? = nil, onDismiss: @escaping ()->Void) {
        let editView = EditAnimeViewController()
        editView.onDismiss = onDismiss
        if let item = item { editView.setItem(item) }
        
        let editNaviController = UINavigationController()
        editNaviController.setDisablePullDownDismiss()
        editNaviController.pushViewController(editView, animated: false)
        from.present(editNaviController, animated: true, completion: nil)
    }
    
	private var navigationBar: UINavigationBar!
    private var onDismiss: (()->Void)? = nil
    var isFirst: Bool {
        self.navigationController?.viewControllers.first == self
    }
	
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
	private var dispRating: UILabel?
	
	private var editUrl: UITextField?
    private var dispMemo = UILabel(frame: .zero) // 計算用
	private var cellMemo: SizCellForText?
	
	private var pickerPubDate: DatePickerView!
	private var pickerMedia: MediaPickerView!
	
	private let medias = AnimeDataManager.shared.loadMedias()
	
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
        
        let text = self.editItem.memo.isEmpty ? Strings.EMPTY_MEMO : self.editItem.memo
        self.dispMemo.text = text
        self.dispMemo.textAlignment = .left
        self.dispMemo.font = .systemFont(ofSize: 16)
        self.dispMemo.numberOfLines = 0
        self.dispMemo.lineBreakMode = .byWordWrapping

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
		
        if self.isFirst {
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
                .value { self.editItem.title },
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
                .value { self.editItem.titleOther },
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
				.value { self.editItem.link },
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
                .valueBoolean { self.editItem.finished },
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
                .value { self.editItem.total > 0 ? String(self.editItem.total) : "" },
                .hint("00"),
                .created { c, _ in
                    let cell = EditTextCell.cellView(c)
                    self.editTotal = cell.textField
                    self.editTotal?.keyboardType = .numberPad
                    self.editTotal?.clearButtonMode = .always
                    cell.maxLength = 4
                    cell.delegate = self
                },
                .valueChanged { value in
                    self.editItem.total = Int(value as? String ?? "0") ?? 0
                }
            ]),
			
			// MARK: Current Episode
            EditTextCell(label: Strings.LABEL_CURR_EP, attrs: [
                .value {
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
                    cell.delegate = self
                },
                .valueChanged { value in
                    self.editItem.progress = Float(value as? String ?? "0") ?? 0
                }
            ]),
			
			// MARK: Published Date
            TextCell(label: Strings.PUB_DATE, attrs: [
                .value { self.editItem.startDate?.toString() ?? Strings.UNKNOWN },
                .selected { i in
                    self.showPubDatePicker()
                    self.editTableView.deselectRow(at: i, animated: false)
                },
                .created { c, _ in self.dispPubDate = c.detailTextLabel }
            ]),
			
			// MARK: Media
            TextCell(label: Strings.MEDIA, attrs: [
                .value { self.medias[self.editItem.media] },
                .selected { i in
                    self.showChoiceMedia()
                    self.editTableView.deselectRow(at: i, animated: false)
                },
                .created { c, _ in self.dispMedia = c.detailTextLabel }
            ]),
			
			// MARK: Rating
			TextCell(label: Strings.RATING, attrs: [
                .value { getRatingToStarText(Int(self.editItem.rating), fillEmpty: true) },
                .created { c, _ in
                    let cell = TextCell.cellView(c)
                    cell.valueLabel?.font = .systemFont(ofSize: 30)
                    cell.valueLabel?.textColor = cell.valueLabel?.tintColor
                    self.dispRating = cell.valueLabel
                },
                .selected { i in
                    self.editTableView.deselectRow(at: i, animated: true)
                    self.showRatingSelection()
                },
            ])
		]))
		
		self.sections.append(TableSection(rows: [
			// MARK: Memo
            TextCell(label: "", attrs: [
                .labelColor(.inputText),
                .created { c, i in
                    let cell = TextCell.cellView(c)
                    cell.valueViewWidth = FILL_WIDTH
                    
                    self.cellMemo = cell
                    cell.valueLabel.textAlignment = .left
                    cell.valueLabel.font = .systemFont(ofSize: 16)
                    cell.valueLabel.numberOfLines = 0
                    cell.valueLabel.lineBreakMode = .byWordWrapping
                    //cell.valueLabel.backgroundColor = .yellow
                },
                .height {
                    self.dispMemo.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 60, height: 0)
                    self.dispMemo.sizeToFit()
                    let height = self.dispMemo.frame.height + SizCellForMultiLine.paddingVertical*2
                    return height //max(height, 45)
                },
                .value {
                    let text = self.editItem.memo.isEmpty ? Strings.EMPTY_MEMO : self.editItem.memo
                    self.dispMemo.text = text
                    return text
                },
                .willDisplay { c, i in
                    let cell = TextCell.cellView(c)
                    cell.valueLabel.frame = CGRect(x: 20, y: 10, width: self.view.frame.width - 60, height: 0)
                    cell.valueLabel.sizeToFit()
                },
                .selected { i in
                    self.editTableView.deselectRow(at: i, animated: true)
                    self.showEditMemo()
                },
            ])
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
                        if #available(iOS 14, *) {
                            var content = cell.contentConfiguration as! UIListContentConfiguration
                            content.textProperties.alignment = .center
                            cell.contentConfiguration = content
                        }
                        else {
                            cell.textLabel?.textAlignment = .center
                        }
                    }
                ])
			]))
		}
		
		self.editTableView = SizPropertyTableView(frame: .zero, style: .grouped)
		self.editTableView.translatesAutoresizingMaskIntoConstraints = false
		self.editTableView.setDataSource(sections)
        self.editTableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 300))
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
    
    func changeRating(_ rating: Int) {
        self.dispRating?.text = getRatingToStarText(rating, fillEmpty: true)
        self.editItem.rating = Float(rating)
    }
	
	// MARK: - UITextFieldDelegate
    
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        let btnEndEdit = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(endEdit))
//        self.navigationItem.rightBarButtonItems = [btnEndEdit]
//    }
//
//    @objc
//    func endEdit() {
//        dismissKeyboard()
//    }
    
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        let btnSave = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(trySave))
//        self.navigationItem.rightBarButtonItems = [btnSave]
//    }
	
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
        
        if self.isFirst {
            dismiss(animated: true, completion: nil)
        }
        else {
            popSelf()
        }
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
                returnBack()
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
                returnBack()
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
	
    private func applyEditData(numberFieldOnly: Bool = false) {
        editItem.total = Int(editTotal?.text ?? "") ?? 0
        if editItem.total < 0 { editItem.total = 0 }
        
        editItem.progress = Float(editProgress?.text ?? "") ?? 0.0
        if editItem.progress < 0 { editItem.progress = 0.0 }
        
        guard !numberFieldOnly else { return }
        
		editItem.title = (editTitle?.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		editItem.titleOther = (editTitleOther?.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		
		editItem.finished = editFinished?.isOn == true
		
		editItem.link = (editUrl?.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		if !editItem.link.isEmpty && !editItem.link.starts(with: "http") {
			editItem.link = "http://\(editItem.link)"
		}
	}
	
	private func checkValidateData() -> Bool {
		var valid = true
		
		if editItem.title.isEmpty {
			valid = false
			
			let dlg = createAlertDialog(
                title: Strings.ERR_WHEN_SAVE,
                message: Strings.ERR_EMPTY_TITLE,
				buttonText: Strings.OK) { _ in self.editTitle?.becomeFirstResponder() }
			present(dlg, animated: true)
		}

		return valid
	}
    
    @objc
    override func onFadeViewTap() {
        self.pickerMedia.onCancel()
        self.pickerPubDate.onCancel()
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
        self.dispMemo.text = text.isEmpty ? Strings.EMPTY_MEMO : text
		self.editItem.memo = text
        self.editTableView.reloadData()
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // nothing
	}
	
}
