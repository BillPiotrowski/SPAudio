//
//  File.swift
//  
//
//  Created by William Piotrowski on 12/27/20.
//

import AVFoundation

// CONCEPT OF LOCKING IN CHAIN EVEN IF NOT CONNECTED.
/*
 Verbs? Hold. Register. insert. 
 
 
 
 */

private protocol ReceivableNode {
    
}
extension ReceivableNode {
    // CONNECTS TO NEXT AVAILABLE BUS, returns bus number
    func insert(_ input: SendableNode) -> Int {
        return 0
    }
    func insert(_ input: SendableNode, bus: Int) {
        
    }
}


private protocol SendableNode {
    
}
