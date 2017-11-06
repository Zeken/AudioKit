//
//  MidiController.swift
//  HelloWorld
//
//  Created by Eloi Marín on 3/11/17.

import AudioKit

class MidiController: AKNode, AKMIDIListener {

    var midi = AKMIDI()
    var samplerUnit = AVAudioUnitSampler()
    var notificationCenter = NotificationCenter.default

    override public init() {
        super.init()
        
        midi.openInput()
        midi.addListener(self)
        avAudioNode = samplerUnit
        AudioKit.output = self
        AudioKit.start()
    }
    
    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        if velocity > 0 {
            play(noteNumber: noteNumber, velocity: 127, channel: channel)
        } else {
            stop(noteNumber: noteNumber, channel: channel)
        }
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        stop(noteNumber: noteNumber, channel: channel)
    }

    func play(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        samplerUnit.startNote(noteNumber, withVelocity: velocity, onChannel: channel)

        // Dispatch notification to the main thread (for UI update)
        DispatchQueue.main.async {
            self.notificationCenter.post(name:Notification.Name(rawValue:"samplerEvent"), object: nil,
                userInfo: ["event": "play", "noteNumber":noteNumber, "velocity": velocity, "channel": channel])
        }
    }

    func stop(noteNumber: MIDINoteNumber, channel: MIDIChannel) {
        samplerUnit.stopNote(noteNumber, onChannel: channel)
        
        // Dispatch notification to the main thread (for UI update)
        DispatchQueue.main.async {
            self.notificationCenter.post(name:Notification.Name(rawValue:"samplerEvent"), object: nil,
                userInfo: ["event": "stop", "noteNumber":noteNumber, "velocity": MIDIVelocity(0), "channel": channel])
        }
    }
}

