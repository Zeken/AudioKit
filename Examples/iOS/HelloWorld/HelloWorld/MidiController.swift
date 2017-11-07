//
//  MidiController.swift
//  HelloWorld
//
//  Created by Eloi Marín on 3/11/17.

import AudioKit

class MidiController: AKNode, AKMIDIListener {

    var midi = AKMIDI()
    var engine = AVAudioEngine()
    var samplerUnit = AVAudioUnitSampler()

    override public init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: .AVAudioSessionRouteChange,
            object: nil)

        midi.openInput()
        midi.addListener(self)

        initSampler()

        avAudioNode = samplerUnit
        AudioKit.output = self
        AudioKit.start()
    }

    func initSampler() {
        guard let url = Bundle.main.url(forResource: "piano", withExtension: "wav") else {
            fatalError("file not found.")
        }
        do {
            try samplerUnit.loadAudioFiles(at: [url])
        } catch {
            print("[Error] samplerUnit.loadAudioFiles()")
        }
    }

    @objc func handleRouteChange(notification: NSNotification) {
        let deadlineTime = DispatchTime.now() + .milliseconds(100)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.initSampler()
        }
    }

    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        if velocity > 0 {
            play(noteNumber: noteNumber, velocity: velocity, channel: channel)
        } else {
            stop(noteNumber: noteNumber, channel: channel)
        }
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        stop(noteNumber: noteNumber, channel: channel)
    }

    func play(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        samplerUnit.startNote(noteNumber, withVelocity: velocity, onChannel: channel)

        // Dispatch notification to the main thread (for UI log update)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name:Notification.Name(rawValue:"samplerEvent"), object: nil,
                userInfo: ["event": "play", "noteNumber":noteNumber, "velocity": velocity, "channel": channel])
        }
    }

    func stop(noteNumber: MIDINoteNumber, channel: MIDIChannel) {
        samplerUnit.stopNote(noteNumber, onChannel: channel)
        
        // Dispatch notification to the main thread (for UI log update)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name:Notification.Name(rawValue:"samplerEvent"), object: nil,
                userInfo: ["event": "stop", "noteNumber":noteNumber, "velocity": MIDIVelocity(0), "channel": channel])
        }
    }
}

