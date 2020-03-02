//
//  ContentView.swift
//  Push Notification GUI
//
//  Created by Hina Kormoczi on 2020. 02. 24.
//  Copyright © 2020. Hina Kormoczi. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var devices: Devices
    @EnvironmentObject var pushDetails: PushDetails
    
    var body: some View {
        return NavigationView {
            VStack{
                Text("Available devices:").padding(.top, CGFloat(10))
                if (devices.devices.filter { $0.isAvailable }).count == 0 {
                    List{
                        HStack(alignment: .center){
                            Spacer()
                            Text("You don't have any Simulator booted.").font(.subheadline).padding(.top, CGFloat(10))
                            Spacer()
                        }
                    }
                } else {
                    List {
                        ForEach(devices.devices.filter { $0.isAvailable }, id: \.uuid) { device in
                            DeviceRow(device: device).environmentObject(self.pushDetails)
                        }
                    }
                }
                Button("Refresh"){
                    let devicesList = Helpers.getDevices().map{ Helpers.stringToDevice($0) }
                    self.devices.devices = devicesList
                }.padding(.bottom, 10)
            }
            .frame(minWidth: 500, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity, alignment: .trailing)
            
        }
    }
}

struct DeviceRow: View {
    @EnvironmentObject var pushDetails: PushDetails
    var device: Device
    
    var body: some View {
        NavigationLink(destination: DetailView(device: device).environmentObject(pushDetails)){
            HStack{
                Text(device.name.trimmingCharacters(in: .whitespacesAndNewlines))
                    .fontWeight(.regular)
                    .bold()
                Text(device.uuid.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.caption)
                    .fontWeight(.thin)
            }
        }
    }
}

class ApplicationDetails {
    var apps: [ApplicationDetail] = []
}

struct ApplicationDetail {
    var name: String
    var bundleID: String
}

struct DetailView: View {
    @EnvironmentObject var pushDetails: PushDetails
    @State private var selection = 0
    
    let device: Device
    var apps : ApplicationDetails = ApplicationDetails()
    
    var body: some View {
        apps.apps.removeAll()
        do {
            let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask).first!
            let applicationFolders = try FileManager.default.contentsOfDirectory(at: libraryURL.appendingPathComponent("Developer/CoreSimulator/Devices/\(device.uuid)/data/Containers/Bundle/Application/"), includingPropertiesForKeys: nil)
            for applicationFolder in applicationFolders {
                let enumerator = FileManager.default.enumerator(atPath: applicationFolder.path)
                let filePaths = enumerator?.allObjects as! [String]
                let appFilePaths = filePaths.filter{$0.contains(".app/Info.plist")}
                for appFilePath in appFilePaths{
                    let fileAbsolutePath = applicationFolder.appendingPathComponent(appFilePath)
                    if let dictionary = NSDictionary(contentsOf: fileAbsolutePath) {
                        apps.apps.append(ApplicationDetail(name: dictionary["CFBundleName"] as! String, bundleID: dictionary["CFBundleIdentifier"] as! String))
                    }
                }
            }
            
        } catch { print(error) }
        
        return VStack{
            Text(device.name.trimmingCharacters(in: .whitespacesAndNewlines)).bold().fontWeight(.heavy)
            Text(device.uuid.trimmingCharacters(in: .whitespacesAndNewlines)).bold().fontWeight(.medium)
            Form {
                Divider()
                Section(header: Text("Target").font(.headline).padding(10)) {
                    if (apps.apps.count > 0){
                        VStack{
                            Text("Choose a target application")
                            Picker(selection: $selection, label: Text("")){
                                ForEach(0..<apps.apps.count){
                                    Text(self.apps.apps[$0].name)
                                }
                            }
                        }
                        .padding()
                    } else {
                        VStack {
                            Text("No applications installed on this Simulator!")
                            Picker(selection: $selection, label: Text("")){
                                Text("")
                            }.disabled(true)
                        }
                        .padding()
                    }
                }
            }
            Divider()
            if (apps.apps.count > 0){
                Section(header: Text("Push Notification").font(.headline).padding(10)) {
                    VStack {
                        Text("Alert title").font(.subheadline)
                        TextField("You've got a Notification!", text: $pushDetails.title)
                        Text("Sound").font(.subheadline)
                        TextField("default", text: $pushDetails.sound)
                        Text("Badge count").font(.subheadline)
                        TextField("1", text: $pushDetails.badge)
                        Toggle(isOn: $pushDetails.contentAvailable){
                            Text("Is content available? (For background update)")
                        }
                    }.padding()
                }
            }
            Divider()
            HStack(alignment: .center) {
                Spacer()
                if (apps.apps.count > 0){
                    Button("Send Push Notification!"){
                        let uuid = self.device.uuid
                        let identifier = self.apps.apps[self.selection].bundleID
                        print(identifier)
                        var title = self.pushDetails.title
                        var sound = self.pushDetails.sound
                        var badge = self.pushDetails.badge
                        let contentAvailable = self.pushDetails.contentAvailable
                        
                        if (!contentAvailable) {
                            if title == "" { title = "You've got a Notification!" }
                            if sound == "" { sound = "default" }
                            if badge == "" { badge = "1" }
                        }
                        let apns = """
                        {
                        "Simulator Target Bundle": "\(identifier)",
                        "aps": {
                        \(title == "" ? "" : "\"alert\": \"\(title)\",")
                        \(sound == "" ? "" : "\"sound\": \"\(sound)\",")
                        \(badge == "" ? "" : "\"badge\": \(badge),")
                        "content-available": \(contentAvailable ? "1" : "0")
                        }
                        }
                        """
                        if let cacheFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                            let appFolder = cacheFolder.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.HinaKormoczi.Push-Notification-GUI")
                            do {
                                try FileManager.default.createDirectory(atPath: appFolder.path, withIntermediateDirectories: true, attributes: nil)
                                let filename = appFolder.appendingPathComponent("push.apns")
                                try apns.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
                                Helpers.sendPushToSimulator(uuid: uuid, bundle: identifier, filePath: filename.path)
                            } catch { print(error) }
                        }
                    }
                } else {
                    Text("No application is available for Notification.")
                }
                Spacer()
            }
            .padding()
            .frame(alignment: .center)
        }
        .padding()
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity, alignment: .top)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
