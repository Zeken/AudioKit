//
//  MidiController.swift
//  HelloWorld
//
//  Created by Eloi Marín on 3/11/17.

import AudioKit

class MidiController: NSObject, AKMIDIListener {

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
        engine.attach(samplerUnit)
        engine.connect(samplerUnit, to: engine.outputNode)
        do {
            try self.engine.start()
        } catch {
            print(error)
        }
    }
    
    @objc func handleRouteChange(notification: NSNotification) {
        let deadlineTime = DispatchTime.now() + .milliseconds(100)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {

            self.engine.stop()
            self.engine.disconnectNodeInput(self.engine.outputNode)

            guard let userInfo = notification.userInfo,
                let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else {
                    return
            }
            switch reason {
            case .newDeviceAvailable:
                let session = AVAudioSession.sharedInstance()
                for output in session.currentRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
                    print("Headphones connected")
                }
            case .oldDeviceUnavailable:
                if let previousRoute =
                    userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                    for output in previousRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
                        print("Headphones disconnected")
                    }
                }
            default: ()
            }
            self.engine.connect(self.samplerUnit, to: self.engine.outputNode)
            do {
                try self.engine.start()
            } catch {
                print(error)
            }
        }
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

