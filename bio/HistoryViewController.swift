//
//  HistoryViewController.swift
//  bio
//
//  Created by Иван Алексеев on 27.04.2018.
//  Copyright © 2018 NETTRASH. All rights reserved.
//

import Foundation
import UIKit

class HistoryViewController : BaseViewController, ModelRootDelegate, UITableViewDelegate, UITableViewDataSource {
	
	let app = UIApplication.shared.delegate as! AppDelegate
	var selectedIndex: IndexPath? = nil
	
	@IBOutlet var tblHistory: UITableView!
	@IBOutlet var lblNoOps: UILabel!
	var refreshControl: UIRefreshControl!
	
	var data: [Any] = []
	var today: [HistoryItem] = []
	var yesterday: [HistoryItem] = []
	var month: [HistoryItem] = []
	var other: [HistoryItem] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.app.model!.HistoryItems.Items = []
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
		refreshControl.tintColor = UIColor.white
		tblHistory.addSubview(refreshControl)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.tblHistory.setContentOffset(CGPoint(x: 0, y: -self.refreshControl!.frame.size.height - self.view.safeAreaInsets.bottom), animated: true)
		refreshHistory()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func closeClick(_ sender: Any?) -> Void {
		performSegue(withIdentifier: unwindIdentifiers["history-bio"]!, sender: self)
	}
	
	@objc func refresh(sender:AnyObject) {
		refreshHistory()
	}
	
	func refreshHistory() -> Void {
		data = []
		today = []
		yesterday = []
		month = []
		other = []
		self.app.model!.delegate = self
		self.app.model!.refreshHistory()
	}
	
	func prepareHistoryData() {
		today = self.app.model!.HistoryItems.Items.filter { $0.date.isToday() }
		yesterday = self.app.model!.HistoryItems.Items.filter { $0.date.isYesterday() }
		month = self.app.model!.HistoryItems.Items.filter { !$0.date.isToday() && !$0.date.isYesterday() && $0.date.isCurrentMonth() }
		other = self.app.model!.HistoryItems.Items.filter { !$0.date.isToday() && !$0.date.isYesterday() && !$0.date.isCurrentMonth() }
		if today.count > 0 { data.append(today) }
		if yesterday.count > 0 { data.append(yesterday) }
		if month.count > 0 { data.append(month) }
		if other.count > 0 { data.append(other) }
	}
	
	//UITaleViewDataSourceDelegate
	func numberOfSections(in tableView: UITableView) -> Int {
		return data.count;
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (data[section] as? [HistoryItem])!.count
	}
	
	private func _historyCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
		let item = (data[indexPath.section] as? [HistoryItem])!.sorted(by: { (_ a: HistoryItem, _ b: HistoryItem) -> Bool in
			a.date > b.date
		})[indexPath.row]
		if selectedIndex != nil && selectedIndex == indexPath {
			let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCellSelected", for: indexPath) as! HistoryCellSelected
			cell.loadData(item, self)
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryCell
			cell.loadData(item)
			return cell
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if tableView == tblHistory {
			return _historyCell(tableView, indexPath)
		}
		return UITableViewCell()
	}
	
	func headerTitle(_ section: Int) -> String? {
		if data[section] as! [HistoryItem] == today { return NSLocalizedString("Today", comment: "Today") }
		if data[section] as! [HistoryItem] == yesterday { return NSLocalizedString("Yesterday", comment: "Yesterday") }
		if data[section] as! [HistoryItem] == month { return NSLocalizedString("Month", comment: "Month") }
		if data[section] as! [HistoryItem] == other { return NSLocalizedString("Other", comment: "Other") }
		return nil
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return headerTitle(section)
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 48
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView()
		headerView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.4)
		let lblTitle = UILabel()
		headerView.addSubview(lblTitle)
		lblTitle.frame.origin.x = 20
		lblTitle.frame.origin.y = 0
		lblTitle.frame.size.height = 48
		lblTitle.frame.size.width = self.tblHistory.frame.size.width - 40
		lblTitle.text = headerTitle(section)
		lblTitle.font = UIFont.boldSystemFont(ofSize: 18)
		lblTitle.textColor = UIColor.white
		return headerView
	}
	
	//UITableViewDelegate
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if selectedIndex != nil && selectedIndex == indexPath { return 96 }
		return 48
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if selectedIndex != indexPath {
			selectedIndex = indexPath
		} else {
			selectedIndex = nil
		}
		tableView.deselectRow(at: indexPath, animated: true)
		tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
	}
	
	//ModelRootDelegate
	func startBalanceUpdate() {
		
	}
	
	func stopBalanceUpdate(error: String?) {
		
	}
	
	func startHistoryUpdate() {
		DispatchQueue.main.async {
			self.app.model!.HistoryItems.Items = []
			self.tblHistory.reloadData()
			self.refreshControl.beginRefreshing()
		}
	}
	
	func stopHistoryUpdate() {
		DispatchQueue.main.async {
			self.refreshControl.endRefreshing()
			self.prepareHistoryData()
			self.tblHistory.reloadData()
			self.lblNoOps.isHidden = self.app.model!.HistoryItems.Items.count > 0
		}
	}
	
	func startCurrentRatesUpdate() {
		
	}
	
	func stopCurrentRatesUpdate() {
		
	}
	
	func unspetData(_ data: Unspent) {
		
	}
	
	func broadcastTransactionResult(_ result: Bool, _ txid: String?, _ message: String?) {
		
	}
	
	func sellStart() {
	}
	
	func sellComplete() {
	}
	
	func updateSellRate() {
	}
	
	func buyStart() {
		
	}
	
	func buyComplete() {
		
	}
	
	func updateBuyRate() {
		
	}
	
	func checkOpComplete(_ process: String) {
		
	}
	
	func newBitPayAddressComplete(_ address: String?) {
		
	}
	
	func payInvoiceError(_ error: String?) {
		
	}
	
	func payInvoiceComplete(_ txid: String?, _ btctxid: String?, _ message: String?) {
		
	}
}
