//
//  HistoryCell.swift
//  bio
//
//  Created by Иван Алексеев on 27.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit

class HistoryCell: UITableViewCell {
	
	var data: HistoryItem!
	
	@IBOutlet var imgOp: UIImageView!
	@IBOutlet var lblDate: UILabel!
	@IBOutlet var lblAmount: UILabel!
	@IBOutlet var lblAddress: UILabel!
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.roundCorners()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.roundCorners()
	}
	
	private func roundCorners() -> Void {
		for v in self.subviews {
			if v is UIButton {
				(v as! UIButton).layer.cornerRadius = 4.0
			} else {
				for vv in (v as UIView).subviews {
					if vv is UIButton {
						(vv as! UIButton).layer.cornerRadius = 4.0
					}
				}
			}
		}
	}
	
	func loadData(_ item: HistoryItem) -> Void {
		data = item
		self.imgOp.image = UIImage(named: ((item.type == .Incoming ? "GreenArrowUp" : "RedArrowDown")))
		self.lblAmount.text = (item.type == .Incoming ? "+ " : "- ") + item.getAmount((UIApplication.shared.delegate as! AppDelegate).model!.Dimension)
		self.lblDate.text = item.getDate()
		self.lblAddress.text = item.outAddress
		self.roundCorners()
	}
}
