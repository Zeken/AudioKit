//
//  ViewController.swift
//  HelloWorld
//
//  Created by Aurelius Prochazka on 12/4/15.
//  Copyright © 2015 AudioKit. All rights reserved.
//

import AudioKit
import AudioKitUI

import UIKit

import AVFoundation
import CoreAudio

import Foundation

class ViewController: UIViewController {

    var midiController = MidiController()

    @IBOutlet weak var textView: UITextView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let nc = NotificationCenter.default
        nc.addObserver(forName:Notification.Name(rawValue:"samplerEvent"),
                       object:nil, queue:nil,
                       using:onSamplerEvent)
    }
    
    @objc func onSamplerEvent(notification:Notification) -> Void {
        guard let userInfo = notification.userInfo,
            let event = userInfo["event"] as? String,
            let noteNumber = userInfo["noteNumber"] as? MIDINoteNumber,
            let velocity   = userInfo["velocity"] as? MIDIVelocity,
            let channel    = userInfo["channel"] as? MIDIChannel else {
                print("No userInfo found in notification")
                return
        }
        let oldText = self.textView.text!
        self.textView.text = "\(oldText)\nMidiProcessor.\(event)(\(noteNumber), \(velocity), \(channel))"
    }

}
