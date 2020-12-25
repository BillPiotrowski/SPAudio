//
//  AudioExtensions.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import Foundation
import AVKit

extension AVAudioNode {
    public var isOutputConnected: Bool {
        return isOutputConnected(bus: 0)
    }
    public func isOutputConnected(bus: Int) -> Bool {
        guard let engine = engine else { return false }
        return engine.outputConnectionPoints(for: self, outputBus: bus).count > 0 ? true : false
    }
}




extension AVAudioEngine {
    enum ConnectionError: ScorepioError {
        case missingEngine(node: String)
        
        var message: String {
            switch self {
            case .missingEngine(let node): return "Could not connect: \(node) is missing engine."
            }
        }
    }
    /// Custom func to help reduce connection errors. Needs to be enhanced.
    public func connect(from: AVAudioNode, to: AVAudioNode, fromBus: AVAudioNodeBus, toBus: AVAudioNodeBus, format: AVAudioFormat?) throws {
        guard from.engine != nil else {
            throw ConnectionError.missingEngine(node: "From Node")
        }
        guard to.engine != nil else {
            throw ConnectionError.missingEngine(node: "To Node")
        }
        let toConnectionPoint = AVAudioConnectionPoint(node: to, bus: toBus)
        _ = try toConnectionPoint.connectable()
        connect(from, to: to, fromBus: fromBus, toBus: toBus, format: format)
    }
}



extension AVAudioConnectionPoint {
    var isAvailable: Bool {
        do {
            _ = try connectable()
            return true
        } catch {
            return false
        }
    }
    public func connectable() throws -> AVAudioConnectionPoint {
        return try AVAudioConnectionPoint.connectable(self)
    }
    public static func connectable(_ point: AVAudioConnectionPoint) throws -> AVAudioConnectionPoint {
        guard let node = point.node else { throw Error.nodeMissing }
        guard let engine = node.engine else { throw Error.engineMissing }
        guard engine.inputConnectionPoint(for: node, inputBus: point.bus) == nil else {
            throw Error.alreadyConnected
        }
        return point
    }
    public static func connectable(_ points: [AVAudioConnectionPoint]) throws ->  [AVAudioConnectionPoint] {
        guard points.count > 0 else { throw Error.connectionPointsEmpty }
        for point in points {
            _ = try point.connectable()
        }
        return points
    }
    
    enum Error: ScorepioError {
        case nodeMissing
        case engineMissing
        case alreadyConnected
        case connectionPointsEmpty
        var message: String {
            switch self {
            case .nodeMissing: return "Audio connection point is missing node."
            case .engineMissing: return "Audio connection point is missing engine."
            case .alreadyConnected: return "Audio connection point is already connected."
            case .connectionPointsEmpty: return "Audio connection points array is empty. There are no connection points."
            }
        }
    }
}
