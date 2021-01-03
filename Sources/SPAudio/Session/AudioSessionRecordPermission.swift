//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/1/21.
//

import AVFoundation
import Promises

// MARK: RECORD PERMISSION
extension AudioSession {
    internal static var recordPermission: RecordPermission {
        avSession.recordPermission
    }
    internal static var isRecordingPermitted: Bool {
        return AudioSession.recordPermission.isRecordingPermitted
    }
    
    /// Requests permission from the user to use the microphone with this app.
    /// - Returns: Returns a Promise that encapsulates a Bool indicating if the user granted permission. Will return false immediately if the user has already granted or denied access.
    internal static func requestRecordPermission(
    ) -> Promise<Bool> {
        return Promise<Bool>{ fulfill, reject in
            //avSession.requestRecordPermission{
            AudioSession.avSession.requestRecordPermission{ didGrantPermission in
                fulfill(didGrantPermission)
            }
        }
    }
}
