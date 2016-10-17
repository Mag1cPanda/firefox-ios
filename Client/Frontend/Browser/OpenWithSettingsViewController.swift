/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class OpenWithSettingsViewController: UITableViewController {

    private lazy var mailSchemes: [[String:String]] = {
        var plistSchemes: [[String:String]] = self.loadMailSchemes()
        return plistSchemes
    }()
    private var mailSchemeEnableCache: [String:Bool] = [String:Bool]()
    private let prefs: Prefs
    private var currentChoice: String = "mailto"

    private let BasicCheckmarkCell = "BasicCheckmarkCell"

    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsOpenWithSectionName

        tableView.accessibilityIdentifier = "OpenWithPage.Setting.Options"

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: BasicCheckmarkCell)
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor

        let headerFooterFrame = CGRect(origin: CGPointZero, size: CGSize(width: self.view.frame.width, height: UIConstants.TableViewHeaderFooterHeight))
        let headerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        headerView.titleLabel.text = Strings.SettingsOpenWithPageTitle
        headerView.showTopBorder = false
        headerView.showBottomBorder = true

        let footerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        footerView.showTopBorder = true
        footerView.showBottomBorder = false

        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OpenWithSettingsViewController.SELappDidBecomeActiveNotification), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadMailSchemeEnableCache()
        if let prefMailtoScheme = self.prefs.stringForKey("MailToOption"), let previousChoice = mailSchemeEnableCache[prefMailtoScheme], let defaultScheme = mailSchemes[0]["scheme"] {
            self.currentChoice = previousChoice ? prefMailtoScheme : defaultScheme
        }
        tableView.reloadData()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.prefs.setString(currentChoice, forKey: "MailToOption")
    }

    func SELappDidBecomeActiveNotification() {
        reloadMailSchemeEnableCache()
        tableView.reloadData()
    }

    func loadMailSchemes() -> [[String:String]] {
        if let path = NSBundle.mainBundle().pathForResource("MailSchemes", ofType: "plist"), let dictRoot = NSArray(contentsOfFile: path) {
            var schemes: [[String:String]] = []
            dictRoot.forEach({ dict in
                let dictionary = dict as! [String:String]
                schemes.append(dictionary)
            })
            return schemes
        }
        return []
    }

    func reloadMailSchemeEnableCache() {
        if let path = NSBundle.mainBundle().pathForResource("MailSchemes", ofType: "plist"), let dictRoot = NSArray(contentsOfFile: path) {
            dictRoot.forEach({ dict in
                let dictionary = dict as! [String:String]
                if let scheme = dictionary["scheme"] {
                    mailSchemeEnableCache[scheme] = canOpenMailScheme(scheme)
                }
            })
        }
    }

    func canOpenMailScheme(scheme: String) -> Bool {
        if let url = NSURL(string: scheme) {
            return UIApplication.sharedApplication().canOpenURL(url)
        }
        return false
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(BasicCheckmarkCell, forIndexPath: indexPath)

        let option = mailSchemes[indexPath.row]

        guard let schemeName = option["name"], let scheme = option["scheme"] else {
            return cell
        }

        cell.textLabel?.attributedText = NSAttributedString.tableRowTitle(schemeName)

        let enabled = mailSchemeEnableCache[scheme] ?? false

        cell.accessoryType = (currentChoice == scheme && enabled) ? .Checkmark : .None

        cell.textLabel?.textColor = enabled ? UIConstants.TableViewRowTextColor : UIConstants.TableViewDisabledRowTextColor
        cell.userInteractionEnabled = enabled

        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mailSchemes.count
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let currentChoice = mailSchemes[indexPath.row]["scheme"] {
            self.currentChoice = currentChoice
        }
        tableView.reloadData()
    }
}
