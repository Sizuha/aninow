//
//  SettingsViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2019/04/25.
//  Copyright © 2019 Sizuha's Atelier. All rights reserved.
//

import UIKit
import SizUtil
import SQuery

class SettingsViewController: CommonUIViewController, UINavigationControllerDelegate {
	
	private var menuTable: SizPropertyTableView!
	private var menus = [SizPropertyTableSection]()
	
	private var dispLastBackup: UILabel?
	private var dateTimeFmt: DateFormatter!


	override func viewDidLoad() {
		super.viewDidLoad()
		dateTimeFmt = SQuery.newDateTimeFormat()
		dateTimeFmt.timeZone = TimeZone.current

		initStatusBar()
		initNavigationBar()
		initTableView()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		setMatchToParent(parent: view, child: menuTable)
	}
	
	private func initNavigationBar() {
		if let navigationBar = navigationController?.navigationBar {
			navigationController?.delegate = self
			initNavigationBarStyle(navigationBar)
		}
		
		let btnDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
		
		navigationItem.title = Strings.SETTING
		navigationItem.rightBarButtonItems = [btnDone]
	}
	
	private func initTableView() {
		self.menuTable = SizPropertyTableView(frame: .zero, style: .grouped)
		self.menuTable.translatesAutoresizingMaskIntoConstraints = false
		
		// Info
		self.menus.append(SizPropertyTableSection(
			title: Strings.INFO,
			rows: [
				// Version
				SizPropertyTableRow(label: "Version")
					.bindData { getAppShortVer() + "." + getAppBuildVer() }
			]
		))
		
		// Backup
		self.menus.append(SizPropertyTableSection(
			title: Strings.BACKUP,
			rows: [
				// Last Backup
				SizPropertyTableRow(label: Strings.BACKUP)
					.textColor(self.menuTable.tintColor)
					.bindData {
						if let date = Settings.shared.lastBackupDate {
							return self.dateTimeFmt.string(from: date)
						}
						return Strings.NONE_VALUE2
					}
					.onCreate { c in
						c.accessoryType = .none
						self.dispLastBackup = c.detailTextLabel
					}
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.backup()
					}
				
//				// Backup
//				,SizPropertyTableRow(type: .button, label: Strings.BACKUP)
//					.onSelect { i in
//						self.menuTable.deselectRow(at: i, animated: true)
//						self.backup()
//					}
				
				// Restore
				,SizPropertyTableRow(type: .button, label: Strings.RESTORE)
					.textColor(self.menuTable.tintColor)
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.confirmImportFromBackup()
					}
			]
		))
		
		// import/export CSV
		self.menus.append(SizPropertyTableSection(
			title: "CSV",
			rows: [
				// Export
				SizPropertyTableRow(type: .button, label: Strings.EXPORT)
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.confirmExport()
				}
				
				// Import
				,SizPropertyTableRow(label: Strings.IMPORT)
					.textColor(self.menuTable.tintColor)
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.moveToImportUI()
				}
			]
		))
		
		// etc
		self.menus.append(SizPropertyTableSection(
			rows: [
				// Clear
				SizPropertyTableRow(type: .button, label: Strings.DELETE_ALL)
					.tintColor(.red)
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.tryClearAll()
					}
					.onCreate { c in
						if let cell = c as? SizCellForButton {
							cell.textLabel?.textAlignment = .center
						}
				}
			]
		))
		
		self.menuTable.setDataSource(self.menus)
		self.view.addSubview(self.menuTable)
	}
	
	@objc func close() {
		popSelf()
	}
	
	func confirmExport() {
		SizAlertBuilder(style: .actionSheet)
			.setMessage(Strings.MSG_CONFIRM_EXPORT)
			.addAction(title: Strings.OK) { _ in
				self.fadeOut { fin in
					self.startNowLoading()
					DispatchQueue.main.async {
						self.exportToCSV()
					}
				}
			}
			.addAction(title: Strings.CANCEL, style: .cancel)
			.show(parent: self)
	}
	
	func exportToCSV() {
		let now = Date()
		
		let fmt = DateFormatter()
		fmt.locale = SQuery.standardLocal
		fmt.dateFormat = "yyyy-MM-dd_HHmmss"
		fmt.timeZone = TimeZone.current
		
		let fileName = "aninow_\(fmt.string(from: now)).csv"
		let outFilePath = "\(SizPath.appDocument)/\(fileName)"
		
		AnimeDataManager.shared.exportTo(file: outFilePath)
		
		stopNowLoading()
		fadeIn()
		
		let dlg = createAlertDialog(message: Strings.MSG_END_BACKUP)
		present(dlg, animated: true)
	}
	
	func backup() {
		let now = Date()
		AnimeDataManager.shared.backup()
		
		Settings.shared.lastBackupDate = now
		self.dispLastBackup?.text = self.dateTimeFmt.string(from: now)
		
		stopNowLoading()
		fadeIn()
		
		let dlg = createAlertDialog(message: Strings.MSG_END_BACKUP)
		present(dlg, animated: true)
	}
	
	func confirmImportFromBackup() {
		SizAlertBuilder(style: .alert)
			.setMessage(Strings.MSG_CONFIRM_IMPORT)
			.addAction(title: Strings.OK) { _ in
				self.fadeOut { fin in
					if fin {
						self.startNowLoading()
						DispatchQueue.main.async {
							self.importFromCsv()
						}
					}
				}
			}
			.addAction(title: Strings.CANCEL, style: .cancel)
			.show(parent: self)
	}
	
	func importFromCsv() {
		let insertCount = AnimeDataManager.shared.restore()
		
		stopNowLoading()
		fadeIn()
		
		SizAlertBuilder()
			.setMessage(String(format: Strings.FMT_END_IMPORT, insertCount))
			.addAction(title: Strings.OK)
			.show(parent: self)
	}
	
	func moveToImportUI() {
		let nextView = ImportCsvViewController()
		self.navigationController?.pushViewController(nextView, animated: true)
	}
	
	func tryClearAll() {
		SizAlertBuilder()
			.setMessage(Strings.MSG_CONFIRM_REMOVE_ALL)
			.addAction(title: Strings.CANCEL)
			.addAction(title: Strings.REMOVE, style: .destructive) { _ in
				AnimeDataManager.shared.removeAll()
			}
			.show(parent: self)
	}

	
}
