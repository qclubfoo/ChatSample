//
//  TableViewControllerWithLabels.swift
//  DelegateTest
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 admin. All rights reserved.
//

import UIKit
import LocalAuthentication
import AVFoundation

protocol MessageType {
    var kind: MessageKind { get }
    var text: String { get }
}


public enum MessageKind {
    case text
    case audio
}

class TextMessage: MessageType {
    var kind: MessageKind = .text
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    convenience init() {
        self.init(text: "")
    }
}

class AudioMessage: MessageType {
    var text: String { url.path }
    var kind: MessageKind = .audio
    var url: URL
    
    init(url: URL) {
        self.url = url
    }
}


class TableViewControllerWithLabels: UIViewController {
    
    var messageArray: [MessageType] = [
//    TextMessage(text: "Hi"),
//    TextMessage(text: "Hi!"),
//    TextMessage(text: "How are you?"),
//    TextMessage(text: "I'am fine, thanks! What about you?"),
    ]
    var voiceRecordNumber = 1
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder?
    var player: AVAudioPlayer?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageOutlet: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet var longPressOutlet: UILongPressGestureRecognizer!
    

    
    
    @IBAction func sendMessageButton(_ sender: UIButton) {
        guard let message = messageOutlet.text else { return }
        if message == "" {
            return
        }
        messageArray.append(TextMessage(text: message))
        messageOutlet.text = ""
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(item: messageArray.count - 1, section: 0), at: .bottom, animated: true)
        sendButton.setBackgroundImage(UIImage.init(systemName: "mic.circle.fill"), for: .normal)
    }
    
    @IBAction func longPressButton(_ sender: Any) {
        if messageOutlet.text == "" {
            let recName = "VoiceMessage_\(voiceRecordNumber).m4a"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(recName)

            if longPressOutlet.state == .began {
                if audioRecorder == nil {
                    startRecorder(recordUrl: url)
                }
            } else if longPressOutlet.state == .ended {
                if audioRecorder != nil {
                    finishRecording(success: true)
                    messageArray.append(AudioMessage(url: url))
                    voiceRecordNumber += 1
                    sendVoiceMessage()
                }
            }
        }
    }
    
    @IBAction func hidingKeyboardTap(_ sender: Any) {
        messageOutlet.resignFirstResponder()
    }
    
    @IBAction func oddPlayButtonTapped(_ sender: CustomPlayButton) {
        guard let index = sender.cellContainingButtonIndexPath?.row else { return }
        play(urlToPlay: URL(fileURLWithPath: messageArray[index].text))
    }
    
    @IBAction func evenPlayButtonTapped(_ sender: CustomPlayButton) {
        guard let index = sender.cellContainingButtonIndexPath?.row else { return }
        play(urlToPlay: URL(fileURLWithPath: messageArray[index].text))
    }
    
    func play(urlToPlay: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: urlToPlay)
            player?.delegate = self
            player?.volume = 1.0
            player?.play()
        } catch {
            print("There is no files to play")
        }
    }
    
    
    func startRecorder(recordUrl: URL) {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 320000,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitDepthHintKey: 32
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: recordUrl, settings: settings)
            if audioRecorder != nil {
                let aR = audioRecorder!
                aR.delegate = self
                aR.record()
            }
        } catch {
            finishRecording(success: false)
        }
    }
    
    func sendVoiceMessage() {
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(item: messageArray.count - 1, section: 0), at: .bottom, animated: true)
    }
    
    func finishRecording(success: Bool) {
        if audioRecorder != nil {
            audioRecorder!.stop()
            audioRecorder = nil
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if messageOutlet.text != "" {
            sendButton.setBackgroundImage(UIImage.init(systemName: "arrow.up.circle.fill"), for: .normal)
        } else {
            sendButton.setBackgroundImage(UIImage.init(systemName: "mic.circle.fill"), for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.overrideOutputAudioPort(.speaker)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("premission granted")
                    } else {
                        print("premission denied, record was failed")
                    }
                }
            }
        } catch {
            print("failed to record")
        }
        
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
        let text = messageArray[indexPath.row].text
        if indexPath.row % 2 == 0 {
            if messageArray[indexPath.row].kind == .audio {
                let cell = tableView.dequeueReusableCell(withIdentifier: "oddCellWithVoice", for: indexPath) as! OddCellWithVoice
                cell.playButton.cellContainingButtonIndexPath = indexPath
                setupLabel(label: cell.label, text: "Voice message")
//                setupLabel(label: cell.label, text: text)
                setupContainer(containerView: cell.containerView, color: UIColor.systemBlue.cgColor)
                return cell
            }
            if messageArray[indexPath.row].kind == .text {
                let cell = tableView.dequeueReusableCell(withIdentifier: "oddCellWithLabel", for: indexPath) as! OddCellWithLabel
                setupLabel(label: cell.label, text: text)
                setupContainer(containerView: cell.containerView, color: UIColor.systemBlue.cgColor)
                return cell
            }
        } else {
            if messageArray[indexPath.row].kind == .audio {
                let cell = tableView.dequeueReusableCell(withIdentifier: "evenCellWithVoice", for: indexPath) as! EvenCellVithVoice
                cell.playButton.cellContainingButtonIndexPath = indexPath
                setupLabel(label: cell.label, text: "Voice message")
                setupContainer(containerView: cell.containerView, color: UIColor.systemGreen.cgColor)
                return cell
            }
            if messageArray[indexPath.row].kind == .text {
                let cell = tableView.dequeueReusableCell(withIdentifier: "evenCellWithLabel", for: indexPath) as! EvenCellWithLabel
                setupLabel(label: cell.label, text: text)
                setupContainer(containerView: cell.containerView, color: UIColor.systemGreen.cgColor)
                return cell
            }
        }
        return UITableViewCell()
    }
    
    private func setupLabel(label: UILabel, text: String) {
        label.textColor = .white
        label.textAlignment = .left
        label.backgroundColor = .clear
        label.text = text
    }
    
    private func setupContainer(containerView: UIView, color: CGColor) {
        containerView.layer.backgroundColor = color
        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.cornerRadius = 10
    }
}

extension TableViewControllerWithLabels: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessageButton(sendButton)
        return true
    }
}

extension TableViewControllerWithLabels: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}

extension TableViewControllerWithLabels: AVAudioPlayerDelegate {
    
}
