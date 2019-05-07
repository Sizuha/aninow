//
//  resources.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/04.
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit

public class Colors {
	static let WIN_BG: UIColor = .white
	static let ACTION: UIColor = .red
	static let NAVI_ACTION: UIColor = .white
	static let NAVI_BG: UIColor = .black
}

public class Icons {
	static let STAR5_EMPTY = UIImage(named: "star5_empty")
	static let STAR5_FILL = UIImage(named: "star5_fill")
	static let SETTINGS = UIImage(named: "setting")
}

public class Strings {
	static let STAR = "★"
	
	static let OK = "ok".localized()
	static let CANCEL = "cancel".localized()
	static let REMOVE = "remove".localized()
	static let ADD_NEW = "add_new".localized()
	static let EDIT = "edit".localized()
	
	static let LABEL_ANIME_LIST = "anime_list".localized()
	static let FILTER_MEDIA = "filter_media".localized()
	static let FILTER_RATING = "filter_rating".localized()
	
	static let SORT = "sort".localized()
	static let SORT_BY_TITLE = "sort_f_title".localized()
	static let SORT_BY_TITLE_DESC = "sort_f_title_desc".localized()
	static let SORT_BY_DATE = "sort_f_date".localized()
	static let SORT_BY_DATE_DESC = "sort_f_date_desc".localized()
	static let SORT_BY_RATING = "sort_f_rating".localized()
	static let SORT_BY_RATING_DESC = "sort_f_rating_desc".localized()
	static let SORT_BY_MEDIA = "sort_f_media".localized()

	static let ALL_VIEWING = "all_view".localized()
	static let NOW_VIEWING = "now_view".localized()
	static let END_VIEWING = "finished".localized()
	static let SETTING = "setting".localized()
	static let SELECT = "select".localized()
	
	static let ANIME_TITLE = "anime_title".localized()
	static let ANIME_TITLE_2ND = "anime_title_2nd".localized()
	static let MEDIA = "media".localized()
	static let MEMO = "memo".localized()
	static let EMPTY_MEMO = "empty_memo".localized()
	static let NONE_VALUE = "none_value".localized()
	static let NONE_VALUE2 = "none_value2".localized()
	static let UNKNOWN = "unknown".localized()
	static let EMPTY_ITEMS = "empty_items".localized()
	static let NO_RATING = "no_rating".localized()
	
	static let LABEL_FIN = "label_fin".localized()
	static let FINAL_EP = "final_ep".localized()
	static let LABEL_CURR_EP = "label_progress".localized()
	static let PUB_DATE = "pub_date".localized()
	static let RATING = "rating".localized()
	
	static let INFO = "info".localized()
	static let COUNT_NOW = "count_now".localized()
	static let COUNT_FINISHED = "count_finished".localized()
	static let BACKUP = "backup".localized()
	static let RESTORE = "restore".localized()
	static let IMPORT = "import".localized()
	static let EXPORT = "export".localized()
	static let LAST_BACKUP = "last_backup".localized()

	static let ERR_FAIL_REMOVE = "err_fail_remove".localized()
	static let ERR_FAIL_SAVE = "err_fail_save".localized()
	
	static let DELETE_ALL = "delete_all".localized()
	static let CLEAR_AND_IMPORT = "clear_and_import".localized()
	static let APPEND_IMPORT = "append_import".localized()
	static let MSG_CONFIRM_REMOVE = "msg_confirm_remove".localized()
	static let MSG_CONFIRM_REMOVE_ALL = "msg_confirm_remove_all".localized()
	static let MSG_CONFIRM_EXPORT = "msg_confirm_export".localized()
	static let MSG_END_BACKUP = "msg_end_backup".localized()
	static let MSG_CONFIRM_IMPORT = "msg_confirm_import".localized()
	static let FMT_END_IMPORT = "fmt_end_import".localized()

	static let FMT_YEAR = "fmt_year".localized()
	static let FMT_MONTH = "fmt_month".localized()
	static let FMT_YEAR_MONTH = "fmt_year_month".localized()
}
