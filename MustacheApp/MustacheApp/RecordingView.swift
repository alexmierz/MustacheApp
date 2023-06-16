//
//  RecordingView.swift
//  MustacheApp
//
//  Created by Alex Mierzejewski on 6/15/23.
//



/*

import Foundation
import SwiftUI
import ReplayKit
import RealmSwift

let partitionValue = UUID().uuidString
let appID = "application-0-ntfhg"

class Recording: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var videoURL: String
    @Persisted var soundURL: String?
    @Persisted var duration: TimeInterval
    @Persisted var tag: String

    convenience init(videoURL: String, soundURL: String?, duration: TimeInterval, tag: String) {
        self.init()
        self._id = ObjectId.generate()
        self.videoURL = videoURL
        self.soundURL = soundURL
        self.duration = duration
        self.tag = tag
    }
}

struct RecordingView: View {
    @State private var isRecording = false

    var body: some View {
        VStack {
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .background(isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    private func startRecording() {
        if RPScreenRecorder.shared().isAvailable {
            RPScreenRecorder.shared().startRecording { [self] error in
                if let error = error {
                    print("Recording failed to start: \(error.localizedDescription)")
                } else {
                    print("Recording started")
                    isRecording = true
                }
            }
        }
    }

    private func stopRecording() {
        RPScreenRecorder.shared().stopRecording { [self] (previewViewController, error) in
            if let error = error {
                print("Failed to stop recording: \(error.localizedDescription)")
            } else if let previewViewController = previewViewController {
                let alertController = UIAlertController(title: "Enter Tag", message: "Please enter a tag for the recording:", preferredStyle: .alert)
                alertController.addTextField { textField in
                    textField.placeholder = "Tag"
                }
                let confirmAction = UIAlertAction(title: "Save", style: .default) { _ in
                    if let tag = alertController.textFields?.first?.text {
                        if let videoURL = getLastRecordingURL() {
                            saveRecording(videoURL: videoURL, soundURL: nil, duration: 0.0, tag: tag)
                        } else {
                            print("Failed to retrieve the last recording URL.")
                        }
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                alertController.addAction(confirmAction)
                alertController.addAction(cancelAction)
                
                if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                    rootViewController.present(alertController, animated: true, completion: nil)
                } else {
                    print("Failed to present the alert controller: root view controller not found.")
                }
            }
            isRecording = false
        }
    }


    private func getLastRecordingURL() -> URL? {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
            let sortedFiles = files.sorted(by: { (file1, file2) -> Bool in
                do {
                    let date1 = try file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate!
                    let date2 = try file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate!
                    return date1 > date2
                } catch {
                    print("Failed to retrieve file attributes: \(error.localizedDescription)")
                    return false
                }
            })
            return sortedFiles.first
        } catch {
            print("Failed to get contents of directory: \(error.localizedDescription)")
            return nil
        }
    }

    private func saveRecording(videoURL: URL, soundURL: URL?, duration: TimeInterval, tag: String) {
        let app = App(id: appID)

        app.login(credentials: Credentials.anonymous) { result in
            switch result {
            case .success(let user):
                print("Logged in anonymously: \(user)")

                let realmConfig = user.configuration(partitionValue: partitionValue)
                do {
                    let realm = try Realm(configuration: realmConfig)
                    try realm.write {
                        let recording = Recording(videoURL: videoURL.absoluteString, soundURL: soundURL?.absoluteString, duration: duration, tag: tag)
                        realm.add(recording)
                        print("Recording saved to Realm")
                    }
                } catch {
                    print("Failed to save recording to Realm: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("Failed to log in anonymously: \(error.localizedDescription)")
            }
        }
    }
}

*/

