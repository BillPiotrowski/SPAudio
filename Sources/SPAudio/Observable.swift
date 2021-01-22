//
//  Observable.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//
/*
import Foundation

public protocol Observable2: class {
    var observations2: [ObjectIdentifier : Observer2] { get set }
}

extension Observable2 {
    /*
    var observerType: Any {
        return AudioTransportObserver.self
    }
 */
    public func addObserver2(_ observerClass: ObserverClass2) {
        let id = ObjectIdentifier(observerClass)
        observations2[id] = Observer2(ref: observerClass)
        //print("Observer: \(observerType)")
        //print(type(of:observerType))
        //print(observerClass.self is AudioTransportObserver)
        
    }
    public func removeObserver2(_ observerClass: ObserverClass2) {
        let id = ObjectIdentifier(observerClass)
        observations2.removeValue(forKey: id)
    }
    public func sendToObservers2(_ observation: Observation2){
        for (id, observer) in observations2 {
            // If the observer is no longer in memory, we
            // can clean up the observation for its ID
            guard observer.ref != nil else {
                observations2[id] = nil
                observations2.removeValue(forKey: id)
                continue
            }
            
            //let _observer = observer as (observerType)
            
            observer.call(observation)
            //observer.call(sequencerState)
        }
    }
}


*/
