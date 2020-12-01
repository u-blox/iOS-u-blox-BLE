/*
 * Copyright (C) u-blox
 *
 * u-blox reserves all rights in this deliverable (documentation, software, etc.,
 * hereafter “Deliverable”).
 *
 * u-blox grants you the right to use, copy, modify and distribute the
 * Deliverable provided hereunder for any purpose without fee.
 *
 * THIS DELIVERABLE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY. IN PARTICULAR, NEITHER THE AUTHOR NOR U-BLOX MAKES ANY
 * REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY OF THIS
 * DELIVERABLE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 *
 * In case you provide us a feedback or make a contribution in the form of a
 * further development of the Deliverable (“Contribution”), u-blox will have the
 * same rights as granted to you, namely to use, copy, modify and distribute the
 * Contribution provided to us for any purpose without fee.
 */

import UIKit

/// Base class for both the mesh overview and the node detail tables.

class NodeTableController: UITableViewController {
    
    fileprivate let kSpacing = 10 as CGFloat
    
    fileprivate var mesh: MeshHandler
    fileprivate var nodes = [UbloxNode]()
    fileprivate var cellTypes: [BaseCell.Type] { [] }
    fileprivate var noDataCellTypes = [BaseCell.Type]()
    
    fileprivate var historyController = HistoryController()
    fileprivate var usesHistory: Bool { true }
    
    init(mesh: MeshHandler) {
        self.mesh = mesh
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = nodes.first?.name ?? mesh.settings.name
        
        tableView.backgroundColor = .ublox
        tableView.sectionFooterHeight = kSpacing / 2
        tableView.sectionHeaderHeight = kSpacing / 2
        tableView.separatorStyle = .none
        
        historyController.delegate = self
        tableView.tableHeaderView = usesHistory ? historyController.view: UIView(frame: CGRect.zero.withHeight(.leastNonzeroMagnitude))
        tableView.tableFooterView = UIView(frame: CGRect.zero.withHeight(.leastNonzeroMagnitude))
        
        for cellType in cellTypes {
            tableView.register(cellType, forCellReuseIdentifier: cellType.reuseId)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if usesHistory && historyController.selectedLimit != historyLimit {
            historyController.selectedLimit = historyLimit
            updateVisibleCells(animated: false)
        }
    }
        
    func updateVisibleCells(animated: Bool) {
        let cells = tableView.visibleCells as? [BaseCell]
        cells?.forEach { $0.update(animated: animated) }
    }
    
    fileprivate func cellType(forIndexPath indexPath: IndexPath) -> BaseCell.Type { cellTypes[indexPath.row] }
    
    fileprivate func node(forIndexPath indexPath: IndexPath) -> UbloxNode? { indexPath.section >= nodes.count ? nil: nodes[indexPath.section] }
    
    fileprivate func cellTappable(_ cell: BaseCell) -> Bool { true }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = cellType(forIndexPath: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: type.reuseId, for: indexPath) as! BaseCell
        cell.indexPath = indexPath
        cell.node = node(forIndexPath: indexPath)
        cell.delegate = self
        cell.configure()
        cell.selectionStyle = cellTappable(cell) && !(cell is Orientation3DCell) ? .default: .none
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let type = cellType(forIndexPath: indexPath)
        return type.height
    }
}

extension NodeTableController: BaseCellDelegate, HistoryControllerDelegate {
    
    private var historyLimitKey: String { "historyLimitKey" }
    
    var historyLimit: HistoryLimit {
        get { HistoryLimit(rawValue: defaults.integer(forKey: historyLimitKey)) ?? .last10Min }
        set {
            defaults.set(newValue.rawValue, forKey: historyLimitKey)
            updateVisibleCells(animated: true)
        }
    }
      
    func nodeRenamed() {
        if nodes.count == 1 {
            title = nodes.first?.name
        }
    }
}

/// The multiple nodes, condensed info table version.
class OverviewNodeTableController: NodeTableController {
    
    override var cellTypes: [BaseCell.Type] { mesh.settings.getOverviewCellTypes }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notifications.addObserver(self, selector: #selector(meshConnectionProgress), type: .meshConnectionProgress, object: nil)
        notifications.addObserver(self, selector: #selector(meshConnectionLost), type: .meshConnectionLost, object: nil)
        notifications.addObserver(self, selector: #selector(meshNodeAdded), type: .meshNodeAdded, object: nil)
        
        tableView.register(ConnectionCell.self, forCellReuseIdentifier: ConnectionCell.reuseId)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { max(nodes.count, 1) }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { nodes.isEmpty ? 1: cellTypes.count }
    
    override func cellType(forIndexPath indexPath: IndexPath) -> BaseCell.Type { nodes.isEmpty ? ConnectionCell.self : super.cellType(forIndexPath: indexPath) }
    
    override func cellTappable(_ cell: BaseCell) -> Bool { cell.tappableInOverview }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        // Show indicator on first cell of each node.
        if let connectionCell = cell as? ConnectionCell {
            connectionCell.label.text = "Connecting to \"" + (mesh.peripheral.name ?? mesh.peripheral.identifier.description) + "\""
            connectionCell.selectionStyle = .none
        }
        else {
            let first = indexPath.row == 0
            cell.accessoryType = first ? .disclosureIndicator : .none
        }
        
        return cell
    }
    
    // Show detailed node view when any row representing the node is tapped.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !nodes.isEmpty else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? BaseCell else { return } // Discard taps on connection cell
        if cell.tappableInOverview {
            let uNode = nodes[indexPath.section]
            let nodeController = DetailNodeTableController(mesh: mesh)
            nodeController.nodes = [uNode]
            nodeController.overviewController = self
            navigationController?.pushViewController(nodeController, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reload()
    }
    
    fileprivate func reload() {
        // Nodes may have been renamed, so resort.
        nodes.sort(by: <)
        
        // New cell types may have been chosen, re-register.
        for cellType in cellTypes {
            tableView.register(cellType, forCellReuseIdentifier: cellType.reuseId)
        }
        // Make sure unique reuse ids for all types.
        assert(Set(cellTypes.map { $0.reuseId }).count == cellTypes.count)
        
        tableView.reloadData()
    }
}

extension OverviewNodeTableController {
    
    @objc func meshNodeAdded(notification: Notification) {
        guard let node = notification.meshNode else { return }
        onMain {
            guard !self.nodes.contains(node) else { return }
            let firstNode = self.nodes.isEmpty
            self.nodes.append(node)
            self.nodes.sort(by: <)
            guard let section = self.nodes.firstIndex(where: { $0 == node }) else { return }
            
            if firstNode { self.tableView.reloadSections(IndexSet(integer: 0), with: .middle) }
            else { self.tableView.insertSections(IndexSet(arrayLiteral: section), with: .middle) }
        }
    }
        
    @objc func meshConnectionProgress(notification: Notification) {
        onMain {
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)),
                let connectionCell = cell as? ConnectionCell,
                let progress = notification.progress {
                connectionCell.progressView.setProgress(progress, animated: true)
            }
        }
    }
    
    @objc func meshConnectionLost(notification: Notification) {
        onMain {
            self.navigationController?.popToViewController(self, animated: true)
            
            self.navigationItem.rightBarButtonItem = nil
            self.nodes.removeAll()
            
            self.mesh = MeshHandler(peripheral:self.mesh.peripheral, settings:self.mesh.settings)
            self.reload()
        }
    }
}

/// The single node, detailed info table version.
class DetailNodeTableController: NodeTableController {
    override var cellTypes: [BaseCell.Type] {
        mesh.settings.getDetailCellTypes.filter { wantedType -> Bool in
            let valid = noDataCellTypes.first { invalidType -> Bool in invalidType == wantedType } == nil
            return valid
        }
    }
    var overviewCellTypes: [BaseCell.Type] { mesh.settings.getOverviewCellTypes }
    
    fileprivate weak var overviewController: OverviewNodeTableController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = self.editButtonItem
        
        for cellType in overviewCellTypes {
            tableView.register(cellType, forCellReuseIdentifier: cellType.reuseId)
        }
        
        // Check which cell types are missing data, remove these from displayed types.
        cellTypes.forEach { cellType in
            if let sensorCellType = cellType as? SensorCell.Type {
                let sensorTypes = sensorCellType.sensorTypes
                let anyData = sensorTypes.reduce(false) { (result, type) -> Bool in
                    result || nodes.first!.statusEntries.lastStatus(for: sensorTypes.first!) != nil
                }
                if !anyData { noDataCellTypes.append(cellType) }
            }
        }
        
    }
    
    override func node(forIndexPath indexPath: IndexPath) -> UbloxNode { nodes[0] }
    
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let useTypes = section == 0 ? cellTypes : overviewCellTypes
        return useTypes.count
    }
    
    override func cellType(forIndexPath indexPath: IndexPath) -> BaseCell.Type {
        let useTypes = indexPath.section == 0 ? cellTypes : overviewCellTypes
        return useTypes[indexPath.row]
    }
    
    override func cellTappable(_ cell: BaseCell) -> Bool { cell.tappableInDetail }
    
    /// Rearranges cells according to user, and tracks the new detail- ≠and overview cell types.
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var types = [cellTypes, overviewCellTypes]
        let type = types[sourceIndexPath.section].remove(at: sourceIndexPath.row)
        types[destinationIndexPath.section].insert(type, at: destinationIndexPath.row)
        mesh.settings.setOverViewCellTypes(types[1])
        mesh.settings.setDetailCellTypes(types[0])
        overviewController?.reload()
    }
    
    /// Makes sure there is always at least one cell type to show in overview.
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == 1 && tableView.numberOfRows(inSection: 1) == 1 && proposedDestinationIndexPath.section == 0 {
            return sourceIndexPath
        }
        return proposedDestinationIndexPath
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle { .none }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { section == 1 ? 120 : 0 }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let label = UILabel()
            label.text = """
            Rows of the types below are
            shown in the mesh overview.
            Tap "Edit" to change.
            """
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 3
            return label
        }
        else { return nil }
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool { false }
        
    /// Tracks duration of selection touch. To avoid selecting the 3D cell after user interacts with the model.
    private var lastHighlight: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        lastHighlight = CFAbsoluteTimeGetCurrent()
    }
    
    /// Show the SingleDetailNodeTableController if a valid cell tapped.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! BaseCell
        guard CFAbsoluteTimeGetCurrent() - lastHighlight < 0.25 else { tableView.deselectRow(at: indexPath, animated: false); return }
        if cell.tappableInDetail {
            let single = SingleDetailNodeTableController(mesh: mesh)
            single.nodes = nodes
            single.cellType = type(of: cell)
            navigationController?.pushViewController(single, animated: true)
        }
    }
}

/// The single node, single full screen cell.
class SingleDetailNodeTableController: NodeTableController {
    fileprivate var cellType: BaseCell.Type!
    override var cellTypes: [BaseCell.Type] { [cellType] }
    override var usesHistory: Bool { cellType is SensorGraphCell.Type }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelection = false
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = 0
        title = nodes.first!.name + ": " + (cellType.title ?? "?")
    }
    
    override func node(forIndexPath indexPath: IndexPath) -> UbloxNode { nodes[0] }
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tableView.bounds.size.height -
            (tableView.tableHeaderView?.bounds.size.height ?? 0) -
            (tableView.tableFooterView?.bounds.size.height ?? 0)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            self.tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .middle)
        })
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        (cell as? Orientation3DCell)?.sceneView.allowsCameraControl = true
        return cell
    }
}

enum HistoryLimit: Int {
    case lastYear = 956_080_000
    case lastMonth = 2_592_000
    case lastWeek = 604_800
    case lastDay = 86_400
    case lastHour = 3_600
    case last10Min = 600
    case lastMin = 60
    
    static var maxValue: CFAbsoluteTime { HistoryLimit.lastYear.time }
    
    var title: String {
        switch self {
        case .lastYear: return "year"
        case .lastMonth: return "month"
        case .lastWeek: return "week"
        case .lastDay: return "24h"
        case .lastHour: return "hour"
        case .last10Min: return "10m"
        case .lastMin: return "min"
        }
    }
    
    var next: HistoryLimit {
        switch self {
        case .lastYear: return .lastMonth
        case .lastMonth: return .lastWeek
        case .lastWeek: return .lastDay
        case .lastDay: return .lastHour
        case .lastHour: return .last10Min
        case .last10Min: return .lastMin
        case .lastMin: return .lastYear
        }
    }
    
    var subLength: CFAbsoluteTime { self == .lastMin ? 10: next.time }
    
    var time: CFAbsoluteTime { CFAbsoluteTime(rawValue) }
}

protocol HistoryControllerDelegate: AnyObject {
    var historyLimit: HistoryLimit { get set }
}

class HistoryController: UIViewController {
    private let entries = [HistoryLimit.lastMonth, .lastWeek, .lastDay, .lastHour, .last10Min, .lastMin]
    private var control: UISegmentedControl!
    weak var delegate: HistoryControllerDelegate?
    var selectedLimit: HistoryLimit {
        get { entries[control.selectedSegmentIndex] }
        set { control.selectedSegmentIndex = entries.firstIndex(of: newValue) ?? 0 }
    }
    
    override func loadView() {
        let label = UILabel()
        label.textColor = .white
        label.text = "Last"
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.adjustsFontSizeToFitWidth = true
        
        control = UISegmentedControl(items: entries.map { $0.title })
        control.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        let font = control.titleTextAttributes(for: .normal)?[NSAttributedString.Key.font] as? UIFont
        let boldFont = UIFont.boldSystemFont(ofSize: font?.pointSize ?? UIFont.systemFontSize)
        let attr = [NSAttributedString.Key.foregroundColor: UIColor.ublox, NSAttributedString.Key.font: boldFont]
        control.setTitleTextAttributes(attr, for: .selected)
        control.setTitleTextAttributes(attr, for: .highlighted)
        if #available(iOS 13.0, *) { control.backgroundColor = UIColor.ublox.withBrightness(1).withAlphaComponent(0.2) }
        control.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        selectedLimit = delegate?.historyLimit ?? .last10Min
        control.apportionsSegmentWidthsByContent = true
        
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = .init(top: kTableInset, left: kTableInset, bottom: kTableInset, right: kTableInset)
        stack.bounds.size.height = 36 + 2 * kTableInset
        stack.tintColor = .white
        
        view = stack
    }
    
    @objc func valueChanged() { delegate?.historyLimit = selectedLimit }
}
