//
//  MediaEditViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2019/05/08.
//  Copyright © 2019 Sizuha's Atelier. All rights reserved.
//

import UIKit
import SizUtil

class EditMediaViewController: UIViewController, UITextFieldDelegate {

	private var menuTable: SizPropertyTableView!
	private var menus = [SizPropertyTableSection]()
	
	private var editItems = [Int:String]()
	
    override func viewDidLoad() {
        super.viewDidLoad()

		title = "\(Strings.EDIT): Media"
		initTableView()
    }
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		setMatchToParent(parent: view, child: menuTable)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		apply()
	}
	
	private func initTableView() {
		menuTable = SizPropertyTableView(frame: .zero, style: .grouped)
		menuTable.autoEndEditing = false
		menuTable.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 400))
		menuTable.translatesAutoresizingMaskIntoConstraints = false
		
		AnimeDataManager.shared.loadMedias().forEach { code, label in
			guard code > 0 else { return }
			
			editItems[code] = label
		}
		
		var rows = [SizPropertyTableRow]()
//		rows.append(SizPropertyTableRow().label("TEST").bindData({
//			return "AAAA"
//		}))
		for i in 1...10 {
			let row = SizPropertyTableRow(type: .editText, label: "\(i)")
				.hint(Strings.NOT_USED)
				.bindData {
					return self.editItems[i] ?? ""
				}
				.onCreate { c, i in
					if let cell = c as? SizCellForEditText {
						cell.maxLength = 10
						cell.delegate = self
						cell.textField.tag = i.row
						//cell.textField.clearButtonMode = .whileEditing
					}
				}
//				.onSelect{ i in
//					if i.row >= 7 {
//						self.menuTable.scrollToRow(at: i, at: .bottom, animated: true)
//					}
//				}
				.onChanged { value in
					self.editItems[i] = (value as? String) ?? ""
				}
			rows.append(row)
		}
		menus.append(SizPropertyTableSection(rows: rows))
		
		menuTable.setDataSource(menus)
		view.addSubview(menuTable)
	}
	
	private func apply() {
		menuTable.endEditing(true)
		editItems.forEach { (code, label) in
			guard code > 0 else { return }
			if label.isEmpty {
				AnimeDataManager.shared.deleteMedia(code)
			}
			else {
				AnimeDataManager.shared.updateMedia(code, label)
			}
		}
	}
	
	
	//--- UITextFieldDelegate ---
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		let row = textField.tag
		if row >= 7 {
			self.menuTable.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle, animated: true)
		}

	}
	
}