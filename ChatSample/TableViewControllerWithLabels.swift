//
//  TableViewControllerWithLabels.swift
//  DelegateTest
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 admin. All rights reserved.
//

import UIKit
import AVFoundation
import MultiSlider

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
    
    var editViewController = EditViewController()
    
    var messageArray: [MessageType] = [
    TextMessage(text: "Hi"),
    TextMessage(text: "Hi!"),
    TextMessage(text: "How are you?"),
    TextMessage(text: "I'am fine, thanks! What about you?"),
    TextMessage(text: "Hi"),
    TextMessage(text: "Hi!"),
    TextMessage(text: "How are you?"),
    TextMessage(text: "I'am fine, thanks! What about you?"),
    TextMessage(text: "Hi"),
    TextMessage(text: "Hi!"),
    TextMessage(text: "How are you?"),
    TextMessage(text: "I'am fine, thanks! What about you?"),
    TextMessage(text: "Hi"),
    TextMessage(text: "Hi!"),
    TextMessage(text: "How are you?"),
    TextMessage(text: "I'am fine, thanks! What about you?"),
    TextMessage(text: "Hi"),
    TextMessage(text: "Hi!"),
    TextMessage(text: "How are you?"),
    TextMessage(text: "I'am fine, thanks! What about you?")
    ]
    var voiceRecordNumber = 1
    var activePlayingButton: CustomPlayButton?
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder?
    var player: AVAudioPlayer?
    
    var cropView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet var longPressOutlet: UILongPressGestureRecognizer!
    @IBOutlet weak var bottomContainerView: UIView!
    

    
    
    @IBAction func sendMessageButton(_ sender: UIButton) {
        guard let message = messageTextField.text else { return }
        if message == "" {
            return
        }
        messageArray.append(TextMessage(text: message))
        messageTextField.text = ""
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(item: messageArray.count - 1, section: 0), at: .bottom, animated: true)
        sendButton.setBackgroundImage(UIImage.init(systemName: "mic.circle.fill"), for: .normal)
    }
    
    @IBAction func longPressButton(_ sender: Any) {
        if messageTextField.text == "" {
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
                    addCropView()
                }
            }
        }
    }
    
    private func addCropView() {
        guard let window = view.window else { return }
        cropView = UIView(frame: CGRect(
            x: window.frame.minX,
            y: window.frame.maxY,
            width: bottomContainerView.frame.width,
            height: bottomContainerView.frame.height + 10.0))
        cropView.backgroundColor = .white
        view.addSubview(cropView)
        
        view.bringSubviewToFront(cropView)
        
        let sendButton = UIButton()
        let cropButton = UIButton()
        let recButton = UIButton()
        let playButton = UIButton()
        let trashButton = UIButton()
        let slider = UISlider()
        
        sendButton.setBackgroundImage(UIImage(systemName: "arrow.up.circle"), for: .normal)
        cropButton.setBackgroundImage(UIImage(systemName: "scissors"), for: .normal)
        recButton.setBackgroundImage(UIImage(systemName: "mic.circle"), for: .normal)
        playButton.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal)
        trashButton.setBackgroundImage(UIImage(systemName: "trash.fill"), for: .normal)
        slider.setThumbImage(UIImage(systemName: "mappin"), for: .normal)
        
        trashButton.addTarget(self, action: #selector(deleteRecAndCancelSending), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendVoiceMessageFromCropView), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playLastVoiceMessage), for: .touchUpInside)
        
        

        
        let buttons = [sendButton, cropButton, playButton, trashButton, recButton]
        for button in buttons {
            cropView.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
        }
        cropView.addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint.init(item: slider, attribute: .top, relatedBy: .equal, toItem: cropView, attribute: .topMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: slider, attribute: .leading, relatedBy: .equal, toItem: cropView, attribute: .leading, multiplier: 1, constant: 10.0),
            NSLayoutConstraint.init(item: slider, attribute: .trailing, relatedBy: .equal, toItem: cropView, attribute: .trailing, multiplier: 1, constant: 10.0),
            NSLayoutConstraint.init(item: slider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
        ])
        
        NSLayoutConstraint.activate([
        NSLayoutConstraint.init(item: sendButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35),
        NSLayoutConstraint.init(item: sendButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35),
        NSLayoutConstraint.init(item: sendButton, attribute: .trailing, relatedBy: .equal, toItem: cropView, attribute: .trailing, multiplier: 1, constant: -20),
        NSLayoutConstraint.init(item: sendButton, attribute: .centerY, relatedBy: .equal, toItem: cropView, attribute: .centerY, multiplier: 1, constant: 15)
        ])
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint.init(item: cropButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35),
            NSLayoutConstraint.init(item: cropButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35),
            NSLayoutConstraint.init(item: cropButton, attribute: .centerY, relatedBy: .equal, toItem: sendButton, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: cropButton, attribute: .trailing, relatedBy: .equal, toItem: sendButton, attribute: .leading, multiplier: 1, constant: -20)
        ])
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint.init(item: recButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35),
            NSLayoutConstraint.init(item: recButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35),
            NSLayoutConstraint.init(item: recButton, attribute: .centerY, relatedBy: .equal, toItem: cropButton, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: recButton, attribute: .trailing, relatedBy: .equal, toItem: cropButton, attribute: .leading, multiplier: 1, constant: -20)
        ])
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint.init(item: playButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35),
            NSLayoutConstraint.init(item: playButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35),
            NSLayoutConstraint.init(item: playButton, attribute: .centerY, relatedBy: .equal, toItem: recButton, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: playButton, attribute: .trailing, relatedBy: .equal, toItem: recButton, attribute: .leading, multiplier: 1, constant: -20)
        ])
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint.init(item: trashButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35),
            NSLayoutConstraint.init(item: trashButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35),
            NSLayoutConstraint.init(item: trashButton, attribute: .centerY, relatedBy: .equal, toItem: playButton, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: trashButton, attribute: .trailing, relatedBy: .equal, toItem: playButton, attribute: .leading, multiplier: 1, constant: -20)
        ])
        
        UIView.animate(withDuration: 0.25, animations: {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
            self.tableView.setContentOffset(CGPoint(x: self.tableView.bounds.minX, y: self.tableView.bounds.maxY), animated: true)
            self.cropView.frame = CGRect(x: self.bottomContainerView.frame.minX,
                                         y: self.bottomContainerView.frame.minY - 10,
                                         width: self.cropView.frame.width,
                                         height: self.cropView.frame.height)
        })
        
    }
    
    func removeCropView() {
        guard let window = view.window else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.cropView.frame = CGRect(
                x: window.frame.minX,
                y: window.frame.maxY,
                width: self.bottomContainerView.frame.width,
                height: self.bottomContainerView.frame.height + 10.0)
        }, completion: { complete in
            if complete {
                self.cropView.removeFromSuperview()
                self.cropView = nil
            }
        })
    }
    
    
    @objc func deleteRecAndCancelSending() {
        messageArray.remove(at: messageArray.count - 1)
        voiceRecordNumber -= 1
        removeCropView()
    }
    
    @objc func sendVoiceMessageFromCropView() {
        removeCropView()
        sendVoiceMessage()
    }
    
    @objc func playLastVoiceMessage() {
        if let url = URL(string: messageArray[messageArray.count - 1].text) {
            play(urlToPlay: url)
        }
    }
    
    @IBAction func hidingKeyboardTap(_ sender: Any) {
        messageTextField.resignFirstResponder()
    }
    
    @IBAction func oddPlayButtonTapped(_ sender: CustomPlayButton) {
        playButtonTapped(button: sender)
    }
    
    @IBAction func evenPlayButtonTapped(_ sender: CustomPlayButton) {
        playButtonTapped(button: sender)
    }
    
    func playButtonTapped(button: CustomPlayButton) {
        guard let index = button.cellContainingButtonIndexPath?.row else { return }
        guard let player = self.player else {
            activePlayingButton = button
            play(urlToPlay: URL(fileURLWithPath: messageArray[index].text))
            button.setBackgroundImage(UIImage(systemName: "stop.circle"), for: .normal)
            return
        }
        play(urlToPlay: URL(fileURLWithPath: messageArray[index].text))
        if player.isPlaying {
            activePlayingButton = nil
            player.stop()
            button.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal)
        } else {
            activePlayingButton = button
            play(urlToPlay: URL(fileURLWithPath: messageArray[index].text))
            button.setBackgroundImage(UIImage(systemName: "stop.circle"), for: .normal)
        }
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
        if messageTextField.text != "" {
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
        
        NotificationCenter.default.addObserver(
        self,
        selector: #selector(keyboardDidHide(_:)),
        name: UIResponder.keyboardDidHideNotification,
        object: nil)
        
        messageTextField.delegate = self
        sendButton.setBackgroundImage(UIImage.init(systemName: "mic.circle.fill"), for: .normal)
        messageTextField.addTarget(self, action: #selector(TableViewControllerWithLabels.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
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
//
            })
        }
    }
    
    @objc func keyboardDidHide(_: Notification) {
        if self.cropView != nil {
            self.cropView.frame = CGRect(
                x: self.bottomContainerView.frame.minX,
                y: self.bottomContainerView.frame.minY - 10,
                width: self.bottomContainerView.frame.width,
                height: self.bottomContainerView.frame.height + 10.0)
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
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if activePlayingButton != nil {
            activePlayingButton!.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal)
            activePlayingButton = nil
        }
    }
}
