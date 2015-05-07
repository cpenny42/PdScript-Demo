//
//  PianoKey.swift
//  Soundfonts-Demo
//
//  Created by Chris Penny on 4/17/15.
//  Copyright (c) 2015 Intrinsic Audio. All rights reserved.
//

import Foundation
import UIKit

// Moving left/right is pitchbend, up/down is volume

class PianoKey: UIButton {
    
    let velocity = 127
    
    var note: Int!
    var octave: Int!
    var controller: SynthViewController!
    var currentVoice: Int = 0
    var startPoint: CGPoint? = nil
    
    let xScaling: Float = 486
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        let touch = touches.first as! UITouch
        startPoint = touch.locationInView(self)
        currentVoice = controller.getNextVoice()
        
        controller.sendToVoice(currentVoice, message: "pitchbend 64")
        controller.sendToVoice(currentVoice, message: "volume \(pow(1 - Float(touch.locationInView(self).y / frame.height), 3))")
        
        controller.sendToVoice(currentVoice, message: "\(note + (12 * octave)) \(velocity)")
        
        touchesMoved(touches, withEvent: event)
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        let touch = touches.first as! UITouch
        let touchPoint = touch.locationInView(self)
        let dx = Float(touch.locationInView(self).x - startPoint!.x)
        
        var pitchbend = ((dx / xScaling) * 64) + 64
        var volume = pow(1 - Float(touchPoint.y / frame.height), 3)
        
        if volume < 0 {
            volume = 0
        }
                
        controller.sendToVoice(currentVoice, message: "pitchbend \(pitchbend)")
        controller.sendToVoice(currentVoice, message: "volume \(volume)")
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        controller.sendToVoice(currentVoice, message: "\(note + (12 * octave)) 0")
    }
    
}