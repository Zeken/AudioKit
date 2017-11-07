//
//  MidiController.swift
//  HelloWorld
//
//  Created by Eloi Marín on 3/11/17.

import AudioKit

class MidiController: NSObject, AKMIDIListener {

    var midi = AKMIDI()
    var engine = AVAudioEngine()
    var samplerUnits = [AVAudioUnitSampler]()

    override public init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: .AVAudioSessionRouteChange,
            object: nil)

        createSampler()
        midi.openInput()
        midi.addListener(self)
        startEngine()
    }
    
    func createSampler() {
        engine.disconnectNodeInput(self.engine.outputNode)
        samplerUnits.append(AVAudioUnitSampler())
        initSampler(samplerUnits.last!)
        engine.attach(samplerUnits.last!)
        engine.connect(samplerUnits.last!, to: engine.outputNode)
    }
    
    func initSampler(_ sampler: AVAudioUnitSampler) {
        guard let url = Bundle.main.url(forResource: "piano", withExtension: "wav") else {
            fatalError("file not found.")
        }
        do {
            try sampler.loadAudioFiles(at: [url])
        } catch {
            print("[Error] samplerUnit.loadAudioFiles()")
        }
    }
        
    func startEngine() {
        if (!engine.isRunning) {
            do {
                try self.engine.start()
            } catch  {
                fatalError("couldn't start engine.")
            }
        }
    }
    
    @objc func handleRouteChange(notification: NSNotification) {
        self.engine.stop()
        let deadlineTime = DispatchTime.now() + .milliseconds(100)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.createSampler()
            self.startEngine()
        }
    }

    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        if velocity > 0 {
            play(noteNumber: noteNumber, velocity: 127, channel: 0)
        } else {
            stop(noteNumber: noteNumber, channel: 0)
        }
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        stop(noteNumber: noteNumber, channel: 0)
    }

    func play(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        samplerUnits.last?.startNote(noteNumber, withVelocity: velocity, onChannel: channel)
        print(samplerUnits.count)

        // Dispatch notification to the main thread (for UI log update)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name:Notification.Name(rawValue:"samplerEvent"), object: nil,
                userInfo: ["event": "play", "noteNumber":noteNumber, "velocity": velocity, "channel": channel])
        }
    }

    func stop(noteNumber: MIDINoteNumber, channel: MIDIChannel) {
        samplerUnits.last?.stopNote(noteNumber, onChannel: channel)
        
        // Dispatch notification to the main thread (for UI log update)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name:Notification.Name(rawValue:"samplerEvent"), object: nil,
                userInfo: ["event": "stop", "noteNumber":noteNumber, "velocity": MIDIVelocity(0), "channel": channel])
        }
    }
}

