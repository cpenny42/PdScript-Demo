//
//  SynthViewController.swift
//  PdScript-Demo
//
//  Created by Chris Penny on 4/29/15.
//  Copyright (c) 2015 Intrinsic Audio. All rights reserved.
//

import Foundation

class SynthViewController: UIViewController {
    
    // Create the dynamic pd session
    var session = PdSession()
    
    // Input to synth voices is through the channels~ object
    var channelsReceiver: String
    
    let synthType = "subtractive_synth" // subtractive_synth.pd
    
    var nextVoice = 0
    
    // My ipad mini can't handle more than 6 voices
    var numVoices = 6 {
        
        // If you change the # of voices, delete channels or allocate more if needed
        didSet {
            if numVoices < oldValue {
                for i in numVoices..<oldValue {
                    session.send(channelsReceiver, message: "delete \(i)")
                }
            } else if numVoices > oldValue {
                for i in oldValue..<numVoices {
                    session.send(channelsReceiver, message: "init \(i) stereo \(synthType)")
                }
            }
        }
    }
    
    var synthSettings = [
        "osc1 semi": 0,
        "osc1 cent": 0,
        "osc1 phase": 0,
        "osc1 set": "sine_table",
        "osc1 mode": "o",
        "osc1 on": 1,
        
        "osc2 semi": 0,
        "osc2 cent": 10,
        "osc2 phase": 0.5,
        "osc2 set": "sawtooth_table",
        "osc2 mode": "-",
        "osc2 on": 1,

        "noise filter": 30,
        "noise adsr": "1 100 0 1",
        "noise amount": 0,
        
        "filter frequency": 2000,
        
        "envelope": "1 500 1 1",
        
        "pitchbend": 64,
        "pitchbend range": 12,
        
        "pan": ".5 0",
        "mix": "1 .5",
        
        "volume": 0.5
    ]

    required init(coder aDecoder: NSCoder) {
        
        channelsReceiver = "\(session._$0)-channels"
        
        super.init(coder: aDecoder)
        
        // Create Objects
        session.obj("input", definition: "r \(channelsReceiver)")
        session.obj("channels", definition: "channels~")
        session.obj("dac", definition: "dac~")
        session.obj("waveforms", definition: "subtractor_waveforms")
        
        // Connect them
        session.connect("input", inletKey: "channels")
        session.connect("channels", inletKey: "dac")
        session.connect("channels", outletIndex: 1, inletKey: "dac", inletIndex: 1)
        
        // The above code could be replaced with this:
//
//        session.script(
//            "obj input r \(channels), " +
//            "obj channels channels~, " +
//            "obj dac dac~, " +
//            "obj waveforms subtractor_waveforms, " +
//
//            "connect input channels, " +
//            "connect channels dac, " +
//            "connect channels 1 dac 1"
//        )
        
        configureChannels()
        updateSettings()
        sendToAllVoices("pitchbend range 36")
        
    }
    
    // Initialize a channel for each voice
    func configureChannels() {
        
        for i in 0..<numVoices {
            session.send(channelsReceiver, message: "init \(i) stereo \(synthType)")
        }
    }
    
    // Send all settings to every voice
    func updateSettings() {
        for (parameter, value) in synthSettings {
            sendToAllVoices("\(parameter) \(value)")
        }
    }
    
    // Send a message to every voice
    func sendToAllVoices (message: String) {
        for i in 0..<numVoices {
            session.send(channelsReceiver, message: "\(i) \(message)")
        }
    }
    
    // Send a message to an individual voice
    func sendToVoice(voice: Int, message: String) {
        session.send(channelsReceiver, message: "\(voice) \(message)")
    }
    
    // Get next available voice (new voices will steal old ones if necessary)
    func getNextVoice() -> Int {
        
        let next = nextVoice
        nextVoice = (nextVoice + 1) % numVoices
        
        return next
    }
    
    /////////////////////////////////////////////////////////////////
    ///////////////////////////// UI STUFF //////////////////////////
    /////////////////////////////////////////////////////////////////
    
    var currentOctave = 5
    
    override func viewDidLoad() {
        pianoKeys = [noteC, noteCsharp, noteD, noteDsharp, noteE, noteF, noteFsharp, noteG, noteGsharp, noteA, noteAsharp, noteB, noteCplus, noteCsharpPlus, noteDplus, noteDsharpPlus, noteEplus, noteFplus, noteFsharpPlus, noteGplus, noteGsharpPlus, noteAplus, noteAsharpPlus, noteBplus]
        
        for (rootNote, pianoKey) in enumerate(pianoKeys) {
            pianoKey.note = rootNote
            pianoKey.octave = currentOctave
            pianoKey.controller = self
        }
        
    }
    
    // On/Off toggles
    @IBAction func osc1On(sender: UISegmentedControl) {
        
        var on = 1
        if sender.selectedSegmentIndex == 0 {
            synthSettings["osc1 on"] = 1
        } else {
            synthSettings["osc1 on"] = 0
            on = 0
        }
        
        sendToAllVoices("osc1 on \(on)")
    }
    
    @IBAction func osc2On(sender: UISegmentedControl) {
        
        var on = 1
        if sender.selectedSegmentIndex == 0 {
            synthSettings["osc2 on"] = 1
        } else {
            synthSettings["osc2 on"] = 0
            on = 0
        }
        
        sendToAllVoices("osc2 on \(on)")
    }
    
    // Phase
    @IBAction func osc1Phase(sender: UISlider) {
        
        synthSettings["osc1 phase"] = sender.value
        sendToAllVoices("osc1 phase \(sender.value)")
    }
    
    @IBAction func osc2Phase(sender: UISlider) {
        
        synthSettings["osc2 phase"] = sender.value
        sendToAllVoices("osc2 phase \(sender.value)")
    }
    
    // Phase mode
    @IBAction func osc1Mode(sender: UISegmentedControl) {
        
        var mode = "o"
        if sender.selectedSegmentIndex == 0 {
            synthSettings["osc1 mode"] = "o"
        }
        else if sender.selectedSegmentIndex == 1 {
            synthSettings["osc1 mode"] = "-"
            mode = "-"
        }
        else {
            synthSettings["osc1 mode"] = "x"
            mode = "x"
        }
        
        sendToAllVoices("osc1 mode \(mode)")
    }
    
    @IBAction func osc2Mode(sender: UISegmentedControl) {
        
        var mode = "o"
        if sender.selectedSegmentIndex == 0 {
            synthSettings["osc2 mode"] = "o"
        }
        else if sender.selectedSegmentIndex == 1 {
            synthSettings["osc2 mode"] = "-"
            mode = "-"
        }
        else {
            synthSettings["osc2 mode"] = "x"
            mode = "x"
        }
        
        sendToAllVoices("osc2 mode \(mode)")
    }
    
    // Semi tune
    @IBAction func osc1Semi(sender: UISlider) {
        
        synthSettings["osc1 semi"] = sender.value
        sendToAllVoices("osc1 semi \(sender.value)")
    }
    
    @IBAction func osc2Semi(sender: UISlider) {
        
        synthSettings["osc2 semi"] = sender.value
        sendToAllVoices("osc2 semi \(sender.value)")
    }
    
    // Cent tune
    @IBAction func osc1Cent(sender: UISlider) {
        
        synthSettings["osc1 cent"] = sender.value
        sendToAllVoices("osc1 cent \(sender.value)")
    }
    
    @IBAction func osc2Cent(sender: UISlider) {
        
        synthSettings["osc2 cent"] = sender.value
        sendToAllVoices("osc2 cent \(sender.value)")
    }

    // Waveform select
    
    @IBAction func osc1Waveform(sender: UISegmentedControl) {
        
        var waveform = "sine_table"
        if sender.selectedSegmentIndex == 0 {
            synthSettings["osc1 set"] = "sine_table"
        }
        else if sender.selectedSegmentIndex == 1 {
            synthSettings["osc1 set"] = "triangle_table"
            waveform = "triangle_table"
        }
        else if sender.selectedSegmentIndex == 2 {
            synthSettings["osc1 set"] = "sawtooth_table"
            waveform = "sawtooth_table"
        }
        else {
            synthSettings["osc1 set"] = "square_table"
            waveform = "square_table"
        }
        
        sendToAllVoices("osc1 set \(waveform)")
    }
    
    @IBAction func osc2Waveform(sender: UISegmentedControl) {
        
        var waveform = "sine_table"
        if sender.selectedSegmentIndex == 0 {
            synthSettings["osc2 set"] = "sine_table"
        }
        else if sender.selectedSegmentIndex == 1 {
            synthSettings["osc2 set"] = "triangle_table"
            waveform = "triangle_table"
        }
        else if sender.selectedSegmentIndex == 2 {
            synthSettings["osc2 set"] = "sawtooth_table"
            waveform = "sawtooth_table"
        }
        else {
            synthSettings["osc2 set"] = "square_table"
            waveform = "square_table"
        }
        
        sendToAllVoices("osc2 set \(waveform)")
    }
    
    // Noise
    @IBAction func noiseAmount(sender: UISlider) {
        
        synthSettings["noise amount"] = sender.value
        sendToAllVoices("noise amount \(sender.value)")
    }
    
    @IBAction func noiseFilter(sender: UISlider) {
        
        synthSettings["noise filter"] = sender.value
        sendToAllVoices("noise filter \(sender.value)")
        println(sender.value)
    }
    
    @IBAction func noiseAttack(sender: UISlider) {
        
        let decay = (synthSettings["noise adsr"] as! String).componentsSeparatedByString(" ")[1]
        synthSettings["noise adsr"] = "\(sender.value) \(decay) 0 0"
        sendToAllVoices("noise adsr \(sender.value) \(decay) 0 0")
    }
    
    @IBAction func noiseDecay(sender: UISlider) {
        
        let attack = (synthSettings["noise adsr"] as! String).componentsSeparatedByString(" ")[0]
        synthSettings["noise adsr"] = "\(attack) \(sender.value) 0 0"
        sendToAllVoices("noise adsr \(attack) \(sender.value) 0 0")
    }
    
    @IBAction func attack(sender: UISlider) {
        
        let attack = sender.value
        
        let decay = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[1]
        
        let sustain = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[2]
        
        let release = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[3]
        
        synthSettings["envelope"] = "\(attack) \(decay) \(sustain) \(release)"
        sendToAllVoices("envelope \(attack) \(decay) \(sustain) \(release)")
        
    }
    
    @IBAction func decay(sender: UISlider) {
        
        let attack = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[0]
        
        let decay = sender.value
        
        let sustain = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[2]
        
        let release = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[3]
        
        synthSettings["envelope"] = "\(attack) \(decay) \(sustain) \(release)"
        sendToAllVoices("envelope \(attack) \(decay) \(sustain) \(release)")
    }
    
    @IBAction func sustain(sender: UISlider) {
        
        let attack = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[0]
        
        let decay = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[1]
        
        let sustain = sender.value
        
        let release = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[3]
        
        synthSettings["envelope"] = "\(attack) \(decay) \(sustain) \(release)"
        sendToAllVoices("envelope \(attack) \(decay) \(sustain) \(release)")
    }
    
    @IBAction func release(sender: UISlider) {
        
        let attack = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[0]
        
        let decay = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[1]
        
        let sustain = (synthSettings["envelope"] as! String).componentsSeparatedByString(" ")[2]
        
        let release = sender.value
        
        synthSettings["envelope"] = "\(attack) \(decay) \(sustain) \(release)"
        sendToAllVoices("envelope \(attack) \(decay) \(sustain) \(release)")
    }
    
    // Pan
    @IBAction func osc1Pan(sender: UISlider) {
        
        let osc1Pan = sender.value
        
        let osc2Pan = (synthSettings["pan"] as! String).componentsSeparatedByString(" ")[1]
        
        synthSettings["pan"] = "\(osc1Pan) \(osc2Pan)"
        sendToAllVoices("pan \(osc1Pan) \(osc2Pan)")
    }
    
    @IBAction func osc2Pan(sender: UISlider) {
        
        let osc1Pan = (synthSettings["pan"] as! String).componentsSeparatedByString(" ")[0]
        
        let osc2Pan = sender.value
        
        synthSettings["pan"] = "\(osc1Pan) \(osc2Pan)"
        sendToAllVoices("pan \(osc1Pan) \(osc2Pan)")
    }
    
    @IBAction func osc1Mix(sender: UISlider) {
        
        let osc1Mix = sender.value
        
        let osc2Mix = (synthSettings["mix"] as! String).componentsSeparatedByString(" ")[1]
        
        synthSettings["mix"] = "\(osc1Mix) \(osc2Mix)"
        sendToAllVoices("mix \(osc1Mix) \(osc2Mix)")
    }
    
    @IBAction func osc2Mix(sender: UISlider) {
        
        let osc1Mix = (synthSettings["mix"] as! String).componentsSeparatedByString(" ")[0]
        
        let osc2Mix = sender.value
        
        synthSettings["mix"] = "\(osc1Mix) \(osc2Mix)"
        sendToAllVoices("mix \(osc1Mix) \(osc2Mix)")
    }
    
    @IBAction func filter(sender: UISlider) {
        
        synthSettings["filter frequency"] = sender.value
        sendToAllVoices("filter frequency \(sender.value)")
    }
    
    @IBAction func volume(sender: UISlider) {
        
        synthSettings["volume"] = sender.value
        sendToAllVoices("volume \(sender.value)")
    }
    
    // Piano Keys
    @IBOutlet weak var noteC: PianoKey!
    @IBOutlet weak var noteCsharp: PianoKey!
    @IBOutlet weak var noteD: PianoKey!
    @IBOutlet weak var noteDsharp: PianoKey!
    @IBOutlet weak var noteE: PianoKey!
    @IBOutlet weak var noteF: PianoKey!
    @IBOutlet weak var noteFsharp: PianoKey!
    @IBOutlet weak var noteG: PianoKey!
    @IBOutlet weak var noteGsharp: PianoKey!
    @IBOutlet weak var noteA: PianoKey!
    @IBOutlet weak var noteAsharp: PianoKey!
    @IBOutlet weak var noteB: PianoKey!
    @IBOutlet weak var noteCplus: PianoKey!
    @IBOutlet weak var noteCsharpPlus: PianoKey!
    @IBOutlet weak var noteDplus: PianoKey!
    @IBOutlet weak var noteDsharpPlus: PianoKey!
    @IBOutlet weak var noteEplus: PianoKey!
    @IBOutlet weak var noteFplus: PianoKey!
    @IBOutlet weak var noteFsharpPlus: PianoKey!
    @IBOutlet weak var noteGplus: PianoKey!
    @IBOutlet weak var noteGsharpPlus: PianoKey!
    @IBOutlet weak var noteAplus: PianoKey!
    @IBOutlet weak var noteAsharpPlus: PianoKey!
    @IBOutlet weak var noteBplus: PianoKey!

    var pianoKeys = [PianoKey]()
    
    // Octave
    @IBOutlet weak var octaveLabel: UILabel!
    
    @IBAction func octaveUp() {
        
        if currentOctave < 10 {
            currentOctave += 1
            
            for key in pianoKeys {
                key.octave = currentOctave
            }
            
            octaveLabel.text = String(currentOctave)
        }
    }
    
    @IBAction func octaveDown() {
        
        if currentOctave > 0 {
            currentOctave -= 1
            
            for key in pianoKeys {
                key.octave = currentOctave
            }
            
            octaveLabel.text = String(currentOctave)
        }
    }
    
    
}
