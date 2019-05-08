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

class SettingsViewController: CommonUIViewController {
	
	private var menuTable: SizPropertyTableView!
	private var menus = [SizPropertyTableSection]()
	
	private var dispLastBackup: UILabel?
	private var dateTimeFmt: DateFormatter!
	
	private var backupSateText: String = ""

	override func viewDidLoad() {
		super.viewDidLoad()
		backupSateText = Strings.MSG_NOW_LOADING
		
		dateTimeFmt = SQuery.newDateTimeFormat()
		dateTimeFmt.timeZone = TimeZone.current

		initStatusBar()
		initNavigationBar()
		initTableView()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		dispLastBackup?.text = backupSateText
		Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
			var result = AnimeDataManager.shared.syncBackupData()
			
			if result {
				if let modiDate = try? FileManager.default.attributesOfItem(atPath: iCloudBackupUrl!.path)[.modificationDate] as? Date {
					self.backupSateText = self.dateTimeFmt.string(from: modiDate)
				}
				else {
					result = false
				}
			}
			
			if (!result) {
				if let date = Settings.shared.lastBackupDate {
					self.backupSateText = self.dateTimeFmt.string(from: date)
				}
				else {
					self.backupSateText = Strings.NONE_VALUE2
				}
			}
			
			self.dispLastBackup?.text = self.backupSateText
		}
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		setMatchToParent(parent: view, child: menuTable)
	}
	
	private func initNavigationBar() {
		if let navigationBar = navigationController?.navigationBar {
			initNavigationBarStyle(navigationBar)
		}
		
		navigationItem.title = Strings.SETTING
	}
	
	private func initTableView() {
		menuTable = SizPropertyTableView(frame: .zero, style: .grouped)
		menuTable.translatesAutoresizingMaskIntoConstraints = false
		
		// Info
		menus.append(SizPropertyTableSection(
			title: Strings.INFO,
			rows: [
				// Version
				SizPropertyTableRow(label: "Version")
					.bindData { getAppShortVer() + "." + getAppBuildVer() }
			]
		))
		
		// Edit
		menus.append(SizPropertyTableSection(
			title: Strings.EDIT,
			rows: [
				// Media
				SizPropertyTableRow(label: "Media")
					.onSelect { i in
						self.navigationController?.pushViewController(EditMediaViewController(), animated: true)
						self.menuTable.deselectRow(at: i, animated: true)
					}
			]
		))
			
		// Backup
		menus.append(SizPropertyTableSection(
			title: "\(Strings.BACKUP) (iCloud)",
			rows: [
				// Last Backup
				SizPropertyTableRow(label: Strings.BACKUP)
					.textColor(self.menuTable.tintColor)
					.bindData {
						return self.backupSateText
					}
					.onCreate { c, _ in
						c.accessoryType = .none
						self.dispLastBackup = c.detailTextLabel
					}
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.backup()
					}
				
				// Restore
				,SizPropertyTableRow(type: .button, label: Strings.RESTORE)
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.confirmImportFromBackup()
					}
			]
		))
		
		// import/export CSV
		menus.append(SizPropertyTableSection(
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
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.moveToImportUI()
				}
			]
		))
		
		// etc
		menus.append(SizPropertyTableSection(
			rows: [
				// Clear
				SizPropertyTableRow(type: .button, label: Strings.DELETE_ALL)
					.tintColor(.red)
					.onSelect { i in
						self.menuTable.deselectRow(at: i, animated: true)
						self.tryClearAll()
					}
					.onCreate { c, _ in
						if let cell = c as? SizCellForButton {
							cell.textLabel?.textAlignment = .center
						}
				}
			]
		))
		
		menuTable.setDataSource(menus)
		view.addSubview(menuTable)
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
		fmt.locale = Locale.standard
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
		guard AnimeDataManager.shared.backup() else {
			stopNowLoading()
			fadeIn()
			
			let dlg = createAlertDialog(message: Strings.MSG_FAIL)
			present(dlg, animated: true)
			return
		}
		
		Settings.shared.lastBackupDate = now
		self.backupSateText = self.dateTimeFmt.string(from: now)
		self.dispLastBackup?.text = self.backupSateText
		
		stopNowLoading()
		fadeIn()
		
		let dlg = createAlertDialog(message: Strings.MSG_END_BACKUP)
		present(dlg, animated: true)
	}
	
	func confirmImportFromBackup() {
		SizAlertBuilder(style: .actionSheet)
			.setMessage(Strings.MSG_CONFIRM_RESTORE)
			.addAction(title: Strings.RESTORE, style: .destructive) { _ in
				self.fadeOut { fin in
					if fin {
						self.startNowLoading()
						DispatchQueue.main.async {
							self.restoreFromBackup()
						}
					}
				}
			}
			.addAction(title: Strings.CANCEL, style: .cancel)
			.show(parent: self)
	}
	
	func restoreFromBackup() {
		let result = AnimeDataManager.shared.restore()
		
		stopNowLoading()
		fadeIn()
		
		guard result else {
			SizAlertBuilder()
				.setMessage(Strings.MSG_NO_BACKUP)
				.addAction(title: Strings.OK)
				.show(parent: self)
			return
		}
		
		SizAlertBuilder()
			.setMessage(Strings.MSG_END_RESTORE)
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
