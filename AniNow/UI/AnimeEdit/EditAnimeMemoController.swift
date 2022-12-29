//
//  EditAnimeMemoController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/11.
//  Copyright © 2018 Sizuha's Atelier. All rights reserved.
//

import UIKit
import SizUI
import SizUtil

class EditAnimeMemoController: UIViewController {
	
	private var navigationBar: UINavigationBar!
	private var editText: UITextView? = nil
	
	private var editTableView: SizPropertyTableView!
	private var sections: [SizPropertyTableSection] = []

	override func viewDidLoad() {
		super.viewDidLoad()
		initNavigationBar()
		initTableView()
	}
	
	public var value: String = ""
	public var onChanged: ((_ text: String)->Void)? = nil
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.editTableView.setMatchTo(parent: self.view)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.editText?.becomeFirstResponder()
	}
	
	private func initNavigationBar() {
		self.navigationBar = self.navigationController?.navigationBar
		guard self.navigationBar != nil else { return }
		
		self.navigationItem.title = Strings.MEMO
		
		let btnSave = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(save))
		self.navigationItem.rightBarButtonItems = [btnSave]
	}
	
	private func initTableView() {
		self.sections.append(SizPropertyTableSection(rows: [
			// Memo
			SizPropertyTableRow(type: .multiLine)
				.onHeight { self.view.frame.height * 0.45 }
				.value { self.value }
				.onCreate { c, _ in
					if let cell = c as? SizCellForMultiLine {
						cell.setEnableEdit()
						self.editText = cell.textView
					}
				}
		]))
		
		editTableView = SizPropertyTableView(frame: .zero, style: .grouped)
		editTableView.translatesAutoresizingMaskIntoConstraints = false
		editTableView.setDataSource(sections)
		view.addSubview(editTableView)
	}
	
	@objc func save() {
		onChanged?(editText?.text ?? "")
		popSelf()
	}

}
