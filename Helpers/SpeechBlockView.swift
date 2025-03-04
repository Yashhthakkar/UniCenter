//
//  SpeechBlockView.swift
//  UniConnect
//
//  Created by Yash Thakkar on 12/2/23.
//

import UIKit

class SpeechBlockView: UIView {
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Added to \"Attracted\" list!"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tailView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        self.backgroundColor = .blue
        self.layer.cornerRadius = 8
        self.addSubview(messageLabel)
        self.addSubview(tailView)

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            messageLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            messageLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            messageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5)
        ])

        setupTailView()
    }

    private func setupTailView() {
        let tailWidth: CGFloat = 10
        let tailHeight: CGFloat = 10
        let tailPath = UIBezierPath()
        
        tailPath.move(to: CGPoint(x: 0, y: 0))
        tailPath.addLine(to: CGPoint(x: tailWidth, y: 0))
        tailPath.addLine(to: CGPoint(x: tailWidth / 2, y: tailHeight))
        tailPath.close()

        let tailLayer = CAShapeLayer()
        tailLayer.path = tailPath.cgPath
        tailLayer.fillColor = UIColor.blue.cgColor

        tailView.layer.addSublayer(tailLayer)
        tailView.backgroundColor = .clear

        NSLayoutConstraint.activate([
            tailView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: -40),
            tailView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 5),
            tailView.widthAnchor.constraint(equalToConstant: tailWidth),
            tailView.heightAnchor.constraint(equalToConstant: tailHeight)
        ])
    }
    

}

