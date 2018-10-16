import UIKit

protocol AssetFilterWindowDelegate: class {
    func assetFilterWindow(_ window: AssetFilterWindow, didApplySort: AssetFilterWindow.Sort, filter: Set<SnapshotType>)
}

class AssetFilterWindow: BottomSheetView {
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: AssetFilterWindowDelegate?

    var sort = Sort.time
    var filters = Set(SnapshotType.allCases)
    
    private var sortDraft = Sort.time
    private var filtersDraft = Set(SnapshotType.allCases)
    
    private let cellReuseId = "cell"
    private let headers = [
        Localized.TRANSACTIONS_FILTER_SORT_BY,
        Localized.TRANSACTIONS_FILTER_FILTER_BY
    ]
    private let titles = [
        [Localized.TRANSACTIONS_FILTER_SORT_BY_TIME,
         Localized.TRANSACTIONS_FILTER_SORT_BY_AMOUNT],
        [Localized.TRANSACTIONS_FILTER_FILTER_BY_ALL,
         Localized.TRANSACTION_TYPE_TRANSFER,
         Localized.TRANSACTION_TYPE_DEPOSIT,
         Localized.TRANSACTION_TYPE_WITHDRAWAL,
         Localized.TRANSACTION_TYPE_FEE,
         Localized.TRANSACTION_TYPE_REBATE]
    ]
    
    class func instance() -> AssetFilterWindow {
        let window = Bundle.main.loadNibNamed("AssetFilterWindow", owner: nil, options: nil)?.first as! AssetFilterWindow
        if let windowFrame = UIApplication.shared.keyWindow?.bounds {
            window.frame = windowFrame
        }
        return window
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dismissButton.addTarget(self, action: #selector(dismissPopupControllerAnimated), for: .touchUpInside)
        tableView.register(UINib(nibName: "TransactionsFilterConditionCell", bundle: .main), forCellReuseIdentifier: cellReuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
        reloadSelection()
        updateTableViewHeightAndScrollingEnabledIfNeeded()
    }
    
    @available(iOS 11.0, *)
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateTableViewHeightAndScrollingEnabledIfNeeded()
    }
    
    override func presentPopupControllerAnimated() {
        sortDraft = sort
        filtersDraft = filters
        reloadSelection()
        super.presentPopupControllerAnimated()
    }
    
    @IBAction func applyAction(_ sender: Any) {
        sort = sortDraft
        filters = filtersDraft
        delegate?.assetFilterWindow(self, didApplySort: sort, filter: filters)
        dismissPopupControllerAnimated()
    }
    
}

extension AssetFilterWindow: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath) as! TransactionsFilterConditionCell
        cell.titleLabel.text = titles[indexPath.section][indexPath.row]
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return headers.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headers[section]
    }

}

extension AssetFilterWindow: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let allFilterIsSelectedBeforeThisSelection: Bool
        if let indexPathsForSelectedRows = tableView.indexPathsForSelectedRows {
            let allIndexPath = IndexPath(row: 0, section: 1)
            allFilterIsSelectedBeforeThisSelection = indexPathsForSelectedRows.contains(allIndexPath)
        } else {
            allFilterIsSelectedBeforeThisSelection = false
        }
        if indexPath.section == 0 {
            let indexPathToDeselect = IndexPath(row: 1 - indexPath.row, section: indexPath.section)
            tableView.deselectRow(at: indexPathToDeselect, animated: true)
            sortDraft = indexPath.row == 0 ? .time : .amount
        } else {
            if indexPath.row == 0 {
                filtersDraft = Set(SnapshotType.allCases)
                for row in 1...5 {
                    let indexPath = IndexPath(row: row, section: indexPath.section)
                    tableView.deselectRow(at: indexPath, animated: true)
                }
            } else {
                let filter = self.filter(for: indexPath.row)
                if allFilterIsSelectedBeforeThisSelection {
                    tableView.deselectRow(at: IndexPath(row: 0, section: 1), animated: true)
                    filtersDraft = [filter]
                } else {
                    filtersDraft.insert(filter)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 {
            return nil
        } else {
            if indexPath == IndexPath(row: 0, section: 1) || filtersDraft.count == 1 {
                return nil
            } else {
                return indexPath
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == 1, (1...5).contains(indexPath.row) {
            filtersDraft.remove(filter(for: indexPath.row))
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
}

extension AssetFilterWindow {
    
    enum Sort {
        case time
        case amount
    }
    
    private func reloadSelection() {
        switch sort {
        case .time:
            tableView.deselectRow(at: IndexPath(row: 1, section: 0), animated: false)
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        case .amount:
            tableView.deselectRow(at: IndexPath(row: 0, section: 0), animated: false)
            tableView.selectRow(at: IndexPath(row: 1, section: 0), animated: false, scrollPosition: .none)
        }
        for row in 0...5 {
            let indexPath = IndexPath(row: row, section: 1)
            tableView.deselectRow(at: indexPath, animated: false)
        }
        if filters.count == SnapshotType.allCases.count {
            tableView.selectRow(at: IndexPath(row: 0, section: 1), animated: false, scrollPosition: .none)
        } else {
            if filters.contains(.transfer) {
                tableView.selectRow(at: IndexPath(row: 1, section: 1), animated: false, scrollPosition: .none)
            }
            if filters.contains(.deposit) {
                tableView.selectRow(at: IndexPath(row: 2, section: 1), animated: false, scrollPosition: .none)
            }
            if filters.contains(.withdrawal) {
                tableView.selectRow(at: IndexPath(row: 3, section: 1), animated: false, scrollPosition: .none)
            }
            if filters.contains(.fee) {
                tableView.selectRow(at: IndexPath(row: 4, section: 1), animated: false, scrollPosition: .none)
            }
            if filters.contains(.rebate) {
                tableView.selectRow(at: IndexPath(row: 5, section: 1), animated: false, scrollPosition: .none)
            }
        }
    }
    
    private func updateTableViewHeightAndScrollingEnabledIfNeeded() {
        tableViewHeightConstraint.constant = ceil(tableView.contentSize.height) + 8
        tableView.isScrollEnabled = tableView.contentSize.height >= tableView.frame.height
    }
    
    private func filter(for row: Int) -> SnapshotType {
        switch row {
        case 1:
            return .transfer
        case 2:
            return .deposit
        case 3:
            return .withdrawal
        case 4:
            return .fee
        default:
            return .rebate
        }
    }
    
}
