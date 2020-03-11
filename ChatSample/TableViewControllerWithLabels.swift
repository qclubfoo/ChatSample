//
//  TableViewControllerWithLabels.swift
//  DelegateTest
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 admin. All rights reserved.
//

import UIKit
import LocalAuthentication

protocol MessageType {
    var kind: MessageKind { get }
}


public enum MessageKind {
    case text
    case audio
}

class TextMessage: MessageType {
    var kind: MessageKind = .text
    var text: String = ""
}

class AudioMessage: MessageType {
    var kind: MessageKind = .audio
    var data: String = ""
}


class TableViewControllerWithLabels: UIViewController {
    
    var messageArray: [String] = ["Hi", "Hi", "How are you?", "I'am fine, thanks"]
    var flag = 1
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageOutlet: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet var longPressOutlet: UILongPressGestureRecognizer!
    
    @IBAction func sendMessageButton(_ sender: UIButton) {
        guard let message = messageOutlet.text else { return }
        if message == "" {
            return
        }
        messageArray.append(message)
        messageOutlet.text = ""
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(item: messageArray.count - 1, section: 0), at: .bottom, animated: true)
        sendButton.setBackgroundImage(UIImage.init(systemName: "mic.circle.fill"), for: .normal)
    }
    @IBAction func longPressButton(_ sender: Any) {
        if messageOutlet.text == "" {
            if longPressOutlet.state == .began {
                messageArray.append("mic_rec")
            } else if longPressOutlet.state == .ended {
                sendVoiceMessage()
            }
        }
    }
    
    @IBAction func hidingKeyboardTap(_ sender: Any) {
        messageOutlet.resignFirstResponder()
    }
    
    func sendVoiceMessage() {
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(item: messageArray.count - 1, section: 0), at: .bottom, animated: true)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        //        messageOutlet.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if messageOutlet.text != "" {
            sendButton.setBackgroundImage(UIImage.init(systemName: "arrow.up.circle.fill"), for: .normal)
        } else {
            sendButton.setBackgroundImage(UIImage.init(systemName: "mic.circle.fill"), for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(keyboardWillShow(notification:)),
          name: UIResponder.keyboardWillShowNotification,
          object: nil)

        NotificationCenter.default.addObserver(
          self,
          selector: #selector(keyboardWillHide(_:)),
          name: UIResponder.keyboardWillHideNotification,
          object: nil)
        
        messageOutlet.delegate = self
        
        sendButton.isEnabled = true
        sendButton.setBackgroundImage(UIImage.init(systemName: "mic.circle.fill"), for: .normal)
        messageOutlet.addTarget(self, action: #selector(TableViewControllerWithLabels.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        guard let info = notification.userInfo as NSDictionary?,
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let window = view.window
            else { return }
        if view.frame.height == window.frame.height {
            UIView.animate(withDuration: 0.0, delay: 0, options: .curveEaseOut, animations: {
                self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - keyboardSize.height)
            })
        }
    }
    
    @objc func keyboardWillHide(_: Notification) {
        guard let window = view.window
            else { return }
        if window.frame.height != view.frame.height {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                self.view.frame = CGRect(x: 0, y: 0, width: window.frame.width, height: window.frame.height)
            })
        }
    }
}

extension TableViewControllerWithLabels: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row % 2 == 0 {
            if messageArray[indexPath.row] == "mic_rec" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "oddCellWithVoice", for: indexPath) as! OddCellWithVoice
                cell.voiceMessageLabel.textColor = .white
                cell.voiceMessageLabel.textAlignment = .left
                cell.voiceMessageLabel.backgroundColor = .clear
                cell.containerView.layer.backgroundColor = UIColor.systemBlue.cgColor
                cell.containerView.layer.borderColor = UIColor.black.cgColor
                cell.containerView.layer.borderWidth = 1
                cell.containerView.layer.cornerRadius = 10
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "oddCellWithLabel", for: indexPath) as! OddCellWithLabel
                cell.label.textColor = .white
                cell.label.text = messageArray[indexPath.row]
                cell.label.textAlignment = .left
                cell.label.backgroundColor = .clear
                cell.containerView.layer.backgroundColor = UIColor.systemBlue.cgColor
                cell.containerView.layer.borderColor = UIColor.black.cgColor
                cell.containerView.layer.borderWidth = 1
                cell.containerView.layer.cornerRadius = 10
                return cell
            }
        } else {
            if messageArray[indexPath.row] == "mic_rec" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "evenCellWithVoice", for: indexPath) as! EvenCellVithVoice
                cell.voiceMessageLabel.textColor = .white
                cell.voiceMessageLabel.textAlignment = .left
                cell.voiceMessageLabel.backgroundColor = .clear
                cell.containerView.layer.backgroundColor = UIColor.systemGreen.cgColor
                cell.containerView.layer.borderColor = UIColor.black.cgColor
                cell.containerView.layer.borderWidth = 1
                cell.containerView.layer.cornerRadius = 10
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "evenCellWithLabel", for: indexPath) as! EvenCellWithLabel
                cell.label.textColor = .white
                cell.label.text = messageArray[indexPath.row]
                cell.label.textAlignment = .left
                cell.label.backgroundColor = .clear
                cell.containerView.layer.backgroundColor = UIColor.systemGreen.cgColor
                cell.containerView.layer.borderColor = UIColor.black.cgColor
                cell.containerView.layer.borderWidth = 1
                cell.containerView.layer.cornerRadius = 10
                return cell
            }
        }
    }
}

extension TableViewControllerWithLabels: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessageButton(sendButton)
        return true
    }
}
