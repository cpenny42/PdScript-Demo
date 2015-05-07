//
//  PdSession.swift
//  PdScript
//
//  Created by Chris Penny on 4/28/15.
//  Copyright (c) 2015 Intrinsic Audio. All rights reserved.
//

import Foundation

/*
    PdSession - dynamic patching session in pure data

        A new session is created during instantiation, after which objects can be created, connected, & deleted.

        Send PdScript messages with .script(script: String) - the script must consist of lines conforming to the syntax described below, separated by a comma and one space (", ").

        General messages to receivers in Pd can be sent with send(receiver: String, message: String).  This method sends a list to dynamicpd.pd, which then causes your message to be sent from within Pd itself. This prevents any headaches regarding types (you don't need a [list trim] in your patch for it).

        Multiple PdSessions can be run at the same time.

        Most functionality in this class wraps the dynamic patching syntax in dynamicpd.pd:

    Object Creation:

        "obj \(key) \(type & args...)"

        A key is needed for each object that is created. This will be used for connections & deletion. The key can be any Pd symbol (can't be a number).
        The type & args are exactly as they would be typed in Pd to create the object.

        Examples:

            .script("obj foo loadbang")
            .obj("foo", type: "loadbang") // Alternate syntax
            .script("obj print PD_PRINTER")

    Object Deletion: - CURRENTLY DOES NOT WORK DUE TO LIBPD FEATURE/BUG

        "delete \(key)"

        This will remove the object from the patch, disconnecting it from everything.
        Currently does not work at all in libpd, but it does in pure data. This is due libpd's ignoring of canvas GUI properties which were used for deletion in dynamicpd.pd - will be fixed soon.

        A way around deletion is to disconnect everything from the object you want to delete. Though delete is broken, "reset" still works.

        Examples:

        .script("delete foo")
        .delete("foo")

    Connections:

        "connect \(senderKey) \(outlet#) \(receiverKey) \(inlet#)"

        Two objects are connected using their keys and outlet/inlet numbers, with 0 being the leftmost inlet or outlet.

        The outlet or inlet number is optional if the value is 0.

        Examples:

            .script("connect foo bar")
            .connect("foo", receiver: "bar")
            .script("connect foo 1 bar 3")
            .connect("foo", outlet: 1, receiver: "bar", inlet: 3)
            .connect("bar", receiver: "baz", inlet: 2)

        Disconnections are handled exactly the same as connections:

            .script("disconnect foo bar")
            .disconnect("foo", outlet: 1, receiver: "bar", inlet: 3)

    Sending:

        "send \(receiver) \(message...)"

        This function sends a list to dynamicpd.pd that then sends a message from within Pd. The string is received in Pd exactly as you'd expect it, and you don't need to worry about PdBase.sendMessage being weird or PdBase.sendList needing a [list trim].  The end result is exactly the same.

        Examples:

            .script("send foo 15")
            .script("send foo bar baz")
            .send("foo", message: "bar baz")

    Subpatches:

        "target \(subpatch)"

        Subpatches are created with the [pd] object. Once it has been created, the "target" method will set that subpatch as the active canvas for scripting.  Multiple subpatches can be managed at once and targeted independently, and each patch lives in a separate namespace.

        Examples:

            .script("obj foo pd my_subpatch")
            .script("target my_subpatch")
            .script("obj foo loadbang, obj bar print, connect foo bar, loadbang")

            .target("my_subpatch") // Alternate syntax

    Loadbang:

        "loadbang"

        Loadbangs must be sent programatically - if you make a patch in PdScript that needs a loadbang for initialization, send "loadbang" after loading it. Patches you load programatically with "obj" will still automatically have loadbangs on initialization as you would expect.

        Examples:

            .script("loadbang")
            .loadbang()

    Reset:

        "reset"

        Clears the currently targeted patch, removing all objects and connections.  While delete is currently broken, this definitely works.

        Examples:

            .script("clear")
            .clear()



    Example Scripts:

    1:
        "obj foo loadbang, obj bar print, connect foo bar, loadbang"
        -- should print "bang" to the console

    2:  session.script(
            "obj input r input, " +
            "obj router route zero one elephant three four, " +
            "msg message There will be coffee, " +
            "obj printer print Hello, " +

            "connect input router, " +
            "connect router 2 message, " +
            "connect message printer, " +

            "send input elephant"
        )

        -- should print "Hello: There will be coffee" to the console

        This could be replaced with:

            session.obj("input", definition: "r input")
            session.obj("router", definition: "route zero one elephant three four")
            session.obj("message", definition: "msg There will be coffee")
            session.obj("printer", definition: "print HELLO")

            session.connect("input", inletKey: "router")
            session.connect("router", outletIndex: 2, inletKey: "message")
            session.connect("message", inletKey: "printer")

            session.send("input", message: "elephant")

        It's up to you if you'd rather use the script() method or the wrapper methods (such as obj(), connect(), & send()).
*/

class PdSession {
    
    // dynamicpd.pd is part of pd-for-libpd
    let patch = "dynamicpd.pd"
    var interpreter: String
    var file: UnsafeMutablePointer<Void>
    var _$0: Int32
    
    init() {
        
        PdBase.addToSearchPath(NSBundle.mainBundle().resourcePath)
        
        file = PdBase.openFile(patch, path: NSBundle.mainBundle().resourcePath)
        _$0 = PdBase.dollarZeroForFile(self.file)
        interpreter = "\(_$0)-dynamicpd"
        
        sendListAsString(interpreter, message: "init")
    }
    
    
    func script(script: String) {
        for line in script.componentsSeparatedByString(", ") {
            sendListAsString(self.interpreter, message: line)
        }
    }
    
// Sending to Pure Data:
    
    // Send a type-safe message to any receiver without needing a [list trim] in your patch. The message is actually sent from within [dynamicpd].
    func send(receiver: String, message: String) {
        sendListAsString(interpreter, message: "send \(receiver) \(message)")
    }
    
    func sendBang(receiver: String) {
        PdBase.sendBangToReceiver(receiver)
    }
    
    func sendFloat(receiver: String, float: Float) {
        PdBase.sendFloat(float, toReceiver: receiver)
    }
    
    func sendList(receiver: String, list: [AnyObject]) {
        PdBase.sendList(list, toReceiver: receiver)
    }
    
    // sendListAsString and sendMessageAsString both use the .toDouble String extension defined at the bottom
    
    // Converts a string into a list of floats or symbols and sends it to Pd
    func sendListAsString(receiver: String, message: String) {
        
        var finalMessage = [AnyObject]()
        
        for item in message.componentsSeparatedByString(" ") {
            var number = item.toDouble()
            
            if number == nil {
                finalMessage.append(item)
            } else {
                finalMessage.append(Float(number!))
            }
        }
        
        PdBase.sendList(finalMessage, toReceiver: receiver)
    }
    
    // Converts a string into a list of floats or symbols, starting with a symbol, and sends it to Pd as a message
    func sendMessageAsString(receiver: String, message: String) {
        
        let messageList = message.componentsSeparatedByString(" ")
        
        if messageList[0].toDouble() == nil {
            var finalMessage = [AnyObject]()
            for item in messageList {
                var number = item.toDouble()
                
                if number == nil {
                    finalMessage.append(item)
                } else {
                    finalMessage.append(number!)
                }
            }
            PdBase.sendList(finalMessage, toReceiver: receiver)
        } else {
            println("PdScript Error - can't send message beginning with a float. Try send(receiver: String, message: String) instead.")
        }
    }
    
// Creating objects:
    
    // Instantiate any object or patch in Pd's search path
    func obj(key: String, definition: String) {
        
        var defList = definition.componentsSeparatedByString(" ")
        var type = definition
        var arguments = ""
        
        if defList.count > 1 {
            type = defList[0]
            defList.removeAtIndex(0)
            arguments = " ".join(defList)
        }
        
        if type == "msg" {
            self.msg(key, message: arguments)
        } else if type == "floatatom" {
            self.floatatom(key, arguments: arguments)
        } else if type == "symbolatom" {
            self.symbolatom(key, arguments: arguments)
        } else {
            sendListAsString(interpreter, message: "obj \(key) \(definition)")
        }
    }
    
    // Create a message box
    func msg(key: String, message: String) {
        sendListAsString(interpreter, message: "msg \(key) \(message)")
    }
    
    // Create a GUI Number box
    func floatatom(key: String, arguments: String) {
        sendListAsString(interpreter, message: "floatatom \(key) \(arguments)")
    }
    
    // Create a GUI Symbol box
    func symbolatom(key: String, arguments: String) {
        sendListAsString(interpreter, message: "symbolatom \(key) \(arguments)")
    }
    
    // Delete an object - DOESN'T WORK IN LIBPD, but it does in pd.
    func delete(key: String) {
        sendListAsString(interpreter, message: "delete \(key)")
    }
    
    // Inlets & outlets default to 0 if not specified
    func connect(outletKey: String, outletIndex: Int = 0, inletKey: String, inletIndex: Int = 0) {
        sendListAsString(interpreter, message: "connect \(outletKey) \(outletIndex) \(inletKey) \(inletIndex)")
    }

    func disconnect(outletKey: String, outletIndex: Int = 0, inletKey: String, inletIndex: Int = 0) {
        sendListAsString(interpreter, message: "disconnect \(outletKey) \(outletIndex) \(inletKey) \(inletIndex)")
    }
    
    // Target a subpatch after the corresponding [pd] object has been created
    func target(subpatch: String) {
        sendListAsString(interpreter, message: "target \(subpatch)")
    }
    
    // Reset to default configuration - clears the patch
    func reset() {
        sendListAsString(interpreter, message: "init")
    }
    
    // Send a loadbang programatically
    func loadbang() {
        sendListAsString(interpreter, message: "loadbang")
    }
}

// Needed to convert string numbers to floats - you'll get a lot of weird errors in Pd otherwise when you try to send floats
extension String {
    func toDouble() -> Double? {
        enum F {
            static let formatter = NSNumberFormatter()
        }
        if let number = F.formatter.numberFromString(self) {
            return number.doubleValue
        }
        return nil
    }
}