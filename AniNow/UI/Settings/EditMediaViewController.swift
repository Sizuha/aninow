//
//  MediaEditViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2019/05/08.
//  Copyright © 2019 Sizuha's Atelier. All rights reserved.
//

import UIKit
import SizUI
import SizUtil

class EditMediaViewController: UIViewController, UITextFieldDelegate {

	private var menuTable: ActionPropertyTableView!
	private var menus = [SizPropertyTableSection]()
	
	private var editItems = [Int:String]()
	
    override func viewDidLoad() {
        super.viewDidLoad()

		title = "\(Strings.EDIT): Media"
		initTableView()
    }
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
        menuTable.setMatchTo(parent: view)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		apply()
	}
	
	private func initTableView() {
		menuTable = ActionPropertyTableView(frame: .zero, style: .grouped)
		menuTable.autoEndEditing = false
		menuTable.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 400))
		menuTable.translatesAutoresizingMaskIntoConstraints = false
		
		AnimeDataManager.shared.loadMedias().forEach { code, label in
			guard code > 0 else { return }
			
			editItems[code] = label
		}
		
		var rows = [SizPropertyTableRow]()
		for i in 1...10 {
			let row = EditTextCell(label: "\(i)", attrs: [
                .hint(Strings.NOT_USED),
                .read { self.editItems[i] ?? "" },
                .created { c, i in
                    let cell = EditTextCell.cellView(c)
                    cell.maxLength = 10
                    cell.delegate = self
                    cell.textField.tag = i.row
                    cell.textField.clearButtonMode = .always
                },
                .valueChanged { value in
                    self.editItems[i] = (value as? String) ?? ""
                }
            ])
			rows.append(row)
		}
		menus.append(TableSection(rows: rows))
		
		menuTable.setDataSource(menus)
		menuTable.onDeleteItem = { i in
			let mediaCode = i.row+1
			self.editItems[mediaCode] = ""
			self.menuTable.reloadRows(at: [i], with: .automatic)
			return false
		}

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
	
	
	// MARK: --- UITextFieldDelegate ---
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		let row = textField.tag
		if row >= 7 {
			menuTable.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle, animated: true)
		}

	}
	
}
