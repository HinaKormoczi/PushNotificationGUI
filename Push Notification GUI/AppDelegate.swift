//
//  AppDelegate.swift
//  Push Notification GUI
//
//  Created by Hina Kormoczi on 2020. 02. 24.
//  Copyright © 2020. Hina Kormoczi. All rights reserved.
//

import Cocoa
import SwiftUI

class Devices: ObservableObject, Identifiable {
    @Published var devices : [Device] = []
    
    init(_ devices: [Device]) {
        self.devices = devices
    }
}

class PushDetails: ObservableObject {
    @Published var identifier : String = ""
    @Published var title : String = ""
    @Published var sound : String = ""
    @Published var badge : String = ""
    @Published var contentAvailable : Bool = false
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let devicesList = Helpers.getDevices().map{ Helpers.stringToDevice($0) }
        let devices = Devices(devicesList)
        let pushDetails = PushDetails()
        let contentView = ContentView().environmentObject(devices).environmentObject(pushDetails)

        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

