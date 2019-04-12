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
import CoreBluetooth

class ChatViewController: BaseSerialPortTabBarViewController {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var sendCrSwitch: UISwitch!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageViewDistance: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!

    @IBAction func sendButtonPressed(_ sender: Any) {
        view.endEditing(true)
        sendMessage()
    }

    fileprivate var messages: [ChatMessage] = []
}
extension ChatViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupSerialPortComplitionHandler = {
            BluetoothManager.shared.currentSerialPort?.setDelegate(delegate: self)
        }

        if BluetoothManager.shared.currentPeripheral!.isSupportingSerialPort {
            messageTextField.isEnabled = true
            messageTextField.placeholder = "Message"
            sendButton.isEnabled = true
        } else {
            messageTextField.isEnabled = false
            messageTextField.placeholder = "No serial service"
            sendButton.isEnabled = false
        }

        NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: .main) { [weak self] notification in
            self?.messageViewDistance.constant = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as! CGRect).size.height
            self?.view.setNeedsUpdateConstraints()
        }
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: .main) { [weak self] _ in
            self?.messageViewDistance.constant = 0;
            self?.view.setNeedsUpdateConstraints()
        }

        messages = []
        tableView.reloadData()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.reuseIdentifier) as! ChatTableViewCell
        let chatMessage = messages[indexPath.row]

        if chatMessage.userName == "Me" {
            cell.userFromLabel.text = chatMessage.userName
            cell.dateFromLabel.text = chatMessage.date
            cell.messageFromLabel.text = chatMessage.message
            cell.imageFromImageView.isHidden = false
            cell.messageFromView.isHidden = false

            cell.userToLabel.text = ""
            cell.dateToLabel.text = ""
            cell.messageToLabel.text = ""
            cell.imageToImageView.isHidden = true
            cell.messageToView.isHidden = true
        } else {
            cell.userFromLabel.text = ""
            cell.dateFromLabel.text = ""
            cell.messageFromLabel.text = ""
            cell.imageFromImageView.isHidden = true
            cell.messageFromView.isHidden = true

            cell.userToLabel.text = chatMessage.userName
            cell.dateToLabel.text = chatMessage.date
            cell.messageToLabel.text = chatMessage.message
            cell.imageToImageView.isHidden = false
            cell.messageToView.isHidden = false
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let message = messages[indexPath.row].message
        let width = UIScreen.main.bounds.size.width - 118
        return (message as NSString).boundingRect(with: CGSize.init(width: width, height: .greatestFiniteMagnitude),
                                                  options: .usesLineFragmentOrigin,
                                                  attributes: [.font : UIFont(name: "HelveticaNeue", size: 14)!],
                                                  context: nil).size.height + 80 - 5
    }
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        sendMessage()
        return true
    }

}
fileprivate extension ChatViewController {
    struct ChatMessage: Equatable {
        let userName: String
        let message: String
        let date: String

        init(userName: String, message: String) {
            self.userName = userName
            self.message = message
            date = DateFormatter.ublox.string(from: Date())
        }
        static func ==(lhs: ChatViewController.ChatMessage, rhs: ChatViewController.ChatMessage) -> Bool {
            return lhs.userName == rhs.userName && lhs.message == rhs.message && lhs.date == rhs.date
        }
    }

    func add(chatMessage: ChatMessage) {
        if messages.isEmpty || messages.last! != chatMessage {
            messages.append(chatMessage)
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                guard self.messages.count > 0 else {
                    return
                }
                self.tableView.scrollToRow(at: IndexPath(row: self.messages.count-1, section: 0), at: .bottom, animated: true)
            }
        }
    }

    func sendMessage() {
        guard let messageTextFieldText = messageTextField.text else {
            Logger.quiet(message: "messageTextField has no text")
            return
        }
        let message = messageTextFieldText + (sendCrSwitch.isOn ? "\r" : "")
        BluetoothManager.shared.currentSerialPort?.write(data: message.data(using: .utf8) ?? Data())
        self.add(chatMessage: ChatMessage(userName: "Me", message: message))
        messageTextField.text = ""
    }
}
extension ChatViewController : DataStreamDelegate {
    func onWrite(data: Data) {
        
    }
    
    func onRead(data: Data) {
        self.add(chatMessage: ChatMessage(userName: BluetoothManager.shared.currentPeripheral?.name ?? "Unknown", message: String(data: data, encoding: .utf8)!))
    }
}
