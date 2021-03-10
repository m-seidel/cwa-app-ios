//
//  TableViewController.swift
//  UITestPlayground
//
//  Created by Carsten Knoblich on 10.03.21.
//

import UIKit

class TableViewController: UITableViewController {

    lazy var model = DummyContent()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return model.sections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.rowsPerSection[section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = model.content[indexPath.section]![indexPath.row]
        cell.accessibilityIdentifier = "\(indexPath.section)-\(indexPath.row)"

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Section \(section)"
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return Array(0..<model.sections).map { String($0) }
    }

}
