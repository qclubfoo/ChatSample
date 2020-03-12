//
//  EditViewController.swift
//  ChatSample
//
//  Created by admin on 12.03.2020.
//  Copyright © 2020 admin. All rights reserved.
//

import UIKit
import SoundWave

protocol AudioVisualizationProtocol {
    
}

enum AudioRecodingState {
    
    case ready
    case recording
    case recorded
    case playing
    case paused

    var buttonImage: UIImage {
        switch self {
        case .ready, .recording:
            return UIImage(systemName: "mic.circle")!
        case .recorded, .paused:
            return UIImage(systemName: "play.circle")!
        case .playing:
            return UIImage(systemName: "pause.circle")!
        }
    }

    var audioVisualizationMode: AudioVisualizationView.AudioVisualizationMode {
        switch self {
        case .ready, .recording:
            return .write
        case .paused, .playing, .recorded:
            return .read
        }
    }
}

class EditViewController: UIViewController {

    /// переменные для работы с визуалицией аудио дорожки
    var audioVisualizationView: AudioVisualizationView?
    var chronometer: Chronometer?
    var audioModel: AudioModel?
    
    /// главные подпредставления
    private var containerView = UIView()
    private var backroundView = UIView()
    
    /// подпредставлени ядля работы с плеером
    private var playButton =    UIButton()
    private var replaceButton = UIButton()
    private var cropButton =    UIButton()
    
    /// подпредставления
    private var doneButton =    UIButton()
    
    /// stack view
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
                                                        cropButton,
                                                        replaceButton,
                                                        doneButton
                                                        ])
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupColors()
        setupSubviews()
        addConstraints()
    }
}

extension EditViewController {
    
    private func setupColors() {
        view.backgroundColor = .white
    }
    
    private func setupSubviews() {
        setupContainerView()
        setupBackroundView()
        
        setupAudioVisualizationView()
        
        setupPlayButton()
        setupReplaceButton()
        setupCropButton()
        setupDoneButton()
        
        setupStackView()
    }
    
    private func addConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: view.frame.height / 2).isActive = true
        
        backroundView.translatesAutoresizingMaskIntoConstraints = false
        backroundView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        backroundView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        backroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        backroundView.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        audioVisualizationView?.translatesAutoresizingMaskIntoConstraints = false
        audioVisualizationView?.heightAnchor.constraint(equalToConstant: 125).isActive = true
        audioVisualizationView?.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        audioVisualizationView?.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        audioVisualizationView?.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15).isActive = true
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        playButton.topAnchor.constraint(equalTo: audioVisualizationView?.bottomAnchor ?? containerView.topAnchor).isActive = true
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    }
    
    private func setupContainerView() {
        view.addSubview(containerView)
    }
    
    private func setupBackroundView() {
        containerView.addSubview(backroundView)
    }
    
    private func setupAudioVisualizationView() {
        guard let audioVV = audioVisualizationView else { return }
        containerView.addSubview(audioVV)
    }
    
    private func setupPlayButton() {

        containerView.addSubview(playButton)

        playButton.setImage(#imageLiteral(resourceName: "icons8-play-50"), for: .normal)
        
        playButton.addTarget(self, action: #selector(didPlayButtonClicked), for: .touchUpInside)
    }
    
    private func setupReplaceButton() {
        
        replaceButton.setTitle("REPLACE", for: .normal)
        replaceButton.setTitleColor(.white, for: .normal)
        replaceButton.backgroundColor = .red
        replaceButton.layer.cornerRadius = 20
        replaceButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 27)
        
        replaceButton.addTarget(self, action: #selector(didReplaceButtonDown), for: .touchDown)
        replaceButton.addTarget(self, action: #selector(didReplaceButtonClicked), for: .touchUpInside)
    }
    
    private func setupCropButton() {
        
        cropButton.setImage(#imageLiteral(resourceName: "icons8-crop-50"), for: .normal)
        
        cropButton.addTarget(self, action: #selector(didCropButtonClicked), for: .touchUpInside)
    }
    
    private func setupDoneButton() {
        
        doneButton.setImage(#imageLiteral(resourceName: "icons8-ok-50"), for: .normal)
        
        doneButton.addTarget(self, action: #selector(didDoneButtonClicked), for: .touchUpInside)
    }
    
    private func setupStackView() {
        containerView.addSubview(stackView)
    }
    
}

extension EditViewController {
    
    @objc private func didPlayButtonClicked() {
        print("didPlayButtonClicked")
    }
    
    @objc private func didReplaceButtonDown() {
        print("didReplaceButtonDown")
    }
    
    @objc private func didReplaceButtonClicked() {
        print("didReplaceButtonClicked")
    }
    
    @objc private func didCropButtonClicked() {
        print("didCropButtonClicked")
    }
    
    @objc private func didDoneButtonClicked() {
        print("didDoneButtonClicked")
    }
}

extension EditViewController: AudioVisualizationProtocol {
    
    
    
    
}
