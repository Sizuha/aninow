//
//  SettingsViewController.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2019/04/25.
//  Copyright © 2019 Sizuha's Atelier. All rights reserved.
//

import UIKit
import SizUI
import SizUtil
import SQuery

class SettingsViewController: CommonUIViewController {
    
    static func presentSheet(from: UIViewController, onDismiss: @escaping ()->Void) {
        let vc = SettingsViewController()
        //vc.setDisablePullDownDismiss()
        vc.onDismiss = onDismiss
        
        let naviController = UINavigationController()
        naviController.pushViewController(vc, animated: false)
        
        from.present(naviController, animated: true, completion: nil)
    }
	
	private var menuTable: SizPropertyTableView!
	private var menus = [SizPropertyTableSection]()
	
	private var dispLastBackup: UILabel?
	private var dateTimeFmt: DateFormatter!
	
	private var backupSateText: String = ""
    
    private var onDismiss: (()->Void)? = nil

	override func viewDidLoad() {
		super.viewDidLoad()
		backupSateText = Strings.MSG_NOW_LOADING
		
		dateTimeFmt = SQuery.newDateTimeFormat()
		dateTimeFmt.timeZone = TimeZone.current

		initNavigationBar()
		initTableView()
	}
	
	override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
		self.menuTable.setMatchTo(parent: self.view)
	}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDismiss?()
    }
	
	private func initNavigationBar() {
		navigationItem.title = Strings.SETTING
        
        let bbiClose = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeThis))
        navigationItem.leftBarButtonItems = [bbiClose]
        
	}
    
    @objc
    func closeThis() {
        self.dismiss(animated: true, completion: nil)
    }
	
	private func initTableView() {
		menuTable = SizPropertyTableView(frame: .zero, style: .grouped)
		menuTable.translatesAutoresizingMaskIntoConstraints = false
        
		// MARK: Info
		menus.append(TableSection(
			title: Strings.INFO,
			rows: [
				// Version
				TextCell(label: "Version", attrs: [
                    .read { "\(getAppShortVer()).\(getAppBuildVer())" }
                ])
			]
		))
		
		// MARK: Edit Media
		menus.append(TableSection(
			title: Strings.EDIT,
			rows: [
				// Media
                TextCell(label: "Media", attrs: [
                    .selected { i in
                        self.menuTable.deselectRow(at: i, animated: true)
                        self.navigationController?.pushViewController(EditMediaViewController(), animated: true)
                    }
                ])
			]
		))

		// MARK: Backup (iCloud)
        let secBackup = TableSection(
            title: "\(Strings.BACKUP) (iCloud)",
            rows: [
                // Last Backup
                TextCell(label: Strings.BACKUP, attrs: [
                    .read { self.backupSateText },
                    .created { c, _ in
                        let cell = TextCell.cellView(c)
                        cell.valueViewWidth = 220
                        cell.accessoryType = .none
                        self.dispLastBackup = cell.detailTextLabel
                        cell.textLabel?.textColor = self.view.tintColor
                    },
                    .selected { i in
                        self.menuTable.deselectRow(at: i, animated: true)
                        self.confirmBackup()
                    }
                ]),
                
                // Restore
                ButtonCell(label: Strings.RESTORE, attrs: [
                    .selected { i in
                        self.menuTable.deselectRow(at: i, animated: true)
                        self.confirmImportFromBackup()
                    }
                ])
            ]
        )
        let oldDbUrl = getOldDBDir().appendingPathComponent(USER_DB_FILENAME, isDirectory: false)
        if FileManager.default.fileExists(atPath: oldDbUrl.path) {
            secBackup.rows.append(
                // Restore from OldVer(1.4.x)
                ButtonCell(label: Strings.BACKUP_FROM_OLDVER, attrs: [
                    .selected { i in
                        self.menuTable.deselectRow(at: i, animated: true)
                        self.confirmImportFromOldAppData()
                    },
                    .tintColor(.red)
                ])
            )
        }
		menus.append(secBackup)
		
		// MARK: import/export CSV
		menus.append(TableSection(
			title: "\(Strings.BACKUP) (CSV)",
			rows: [
				// Export
                ButtonCell(label: Strings.EXPORT, attrs: [
                    .selected { i in
                        self.menuTable.deselectRow(at: i, animated: true)
                        self.confirmExport()
                    }
                ]),
				
				// Import
                TextCell(label: Strings.IMPORT, attrs: [
                    .selected { i in
                        self.menuTable.deselectRow(at: i, animated: true)
                        self.moveToImportUI()
                    }
                ])
			]
		))
		
		// MARK: etc
		menus.append(TableSection(
			rows: [
				// Clear
                ButtonCell(label: Strings.DELETE_ALL, attrs: [
                    .tintColor(.red),
                    .selected { i in
                        self.menuTable.deselectRow(at: i, animated: true)
                        self.tryClearAll()
                    },
                    .created { c, _ in
                        let cell = ButtonCell.cellView(c)
                        cell.textLabel?.textAlignment = .center
                    }
                ])
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
		
        let dlg = createAlertDialog(title: "\(Strings.BACKUP) (CSV)", message: Strings.MSG_END_EXPORT)
		present(dlg, animated: true)
	}
    
    func confirmBackup() {
        SizAlertBuilder(style: .actionSheet)
            .setMessage(Strings.MSG_CONFIRM_BACKUP)
            .addAction(title: Strings.OK) { _ in
                DispatchQueue.main.async {
                    self.backup()
                }
            }
            .addAction(title: Strings.CANCEL, style: .cancel)
            .show(parent: self)
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
							self.restoreFromBackup(false)
						}
					}
				}
			}
			.addAction(title: Strings.CANCEL, style: .cancel)
			.show(parent: self)
	}
    
    func confirmImportFromOldAppData() {
        SizAlertBuilder(style: .actionSheet)
            .setMessage(Strings.MSG_BACKUP_FROM_OLDVER)
            .addAction(title: Strings.RESTORE, style: .destructive) { _ in
                self.fadeOut { fin in
                    if fin {
                        self.startNowLoading()
                        DispatchQueue.main.async {
                            self.restoreFromBackup(true)
                        }
                    }
                }
            }
            .addAction(title: Strings.CANCEL, style: .cancel)
            .show(parent: self)
    }

    func restoreFromBackup(_ fromOldDB: Bool) {
		let result = AnimeDataManager.shared.restore(fromOldDB: fromOldDB)
		
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
            .addAction(title: Strings.OK) { _ in
                self.closeThis()
            }
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
