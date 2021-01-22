//
//  Observer.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//
/*
import Foundation

public struct Observer2 {
    weak var ref: ObserverClass2?
    
    func call(_ observation: Observation2){
        switch observation {
//        case .audioTransport(let transportState):
//            guard let audioTransportObserver = ref as? AudioTransportObserver else {
//                return
//            }
//            audioTransportObserver.audioTransportChanged(transportState)

        case .audioSequencer(let sequencerState, let deck):
            guard let audioSequenceObserver = ref as? AudioSequencerObserver else { return }
            audioSequenceObserver.audioDeckObserver(sequencerState, deck: deck)
            /*
        case .playbackEngine(let activeDeckState):
            guard let playbackEngineObserver = ref as? PlaybackEngineObserver else { return }
            playbackEngineObserver.playbackEngineObserver(activeDeckState)
 */
        /*
        case .oldPlaylist(let playlistState):
            guard let playlistObserver = ref as? PlaylistObserver else { return }
            playlistObserver.playlistObserver(playlistState)
 */
            /*
        case .playbackEngineCurrent(let playbackItem):
            guard let playbackEngineObserver = ref as? PlaybackEngineObserver else { return }
            playbackEngineObserver.playbackEngineUpdate(
                current: playbackItem
            )
        case .playbackEngineQueued(let playableItem):
            guard let playbackEngineObserver = ref as? PlaybackEngineObserver else { return }
            playbackEngineObserver.playbackEngineUpdate(
                queued: playableItem
            )
 */
//        case .audioPlayer(let playerState):
//            guard let audioPlayerObserver = ref as? AudioPlayerObserver else { return }
//            audioPlayerObserver.audioPlayerObservation(playerState)
            /*
        case .cues(let cuesState):
            guard let cuesObserver = ref as? CuesObserver else { return }
            cuesObserver.cuesObserver(cuesState)
        case .cartridge(let cartridgeState):
            guard let cartridgeObserver = ref as? CartridgeObserver else { return }
            cartridgeObserver.cartridgeChanged(state: cartridgeState)
            /*
        case .albumsLoader(let state):
            guard let albumsLoaderObserver = ref as? AlbumsLoaderObserver else { return }
 */
            //albumsLoaderObserver.albumsLoaderChanged(state: state)
        case .playlist(let playlist):
            guard let playlistObserver = ref as? NewPlaylistObserver else { return }
            playlistObserver.playlistUpdated(playlist: playlist)
        case .userSecureData(let secureData):
            guard let playlistObserver = ref as? UserSecureDataObserver
            else { return }
            playlistObserver.userSecureDataUpdated(userSecureData: secureData)
        case .meter(let reading):
            guard let meterObserver = ref as? MeterObserver
                else { return }
            meterObserver.meterUpdated(reading: reading)
             */
        case .audioEngine:
            guard let audioEngineObserver = ref as? AudioEngineObserver
                else { return }
            audioEngineObserver.audioEngineUpdated()
        /*
        case .inputEngine(let input, let isRunning):
            guard let inputEngineObserver = ref as? InputEngineObserver
                else { return }
            inputEngineObserver.inputEngineUpdate(inputOption: input, isRunning: isRunning)
            /*
        case .playbackTransition(let progress):
            guard let playbackTransitionObserver = ref as? PlaybackTransitionObserver
                else { return }
            playbackTransitionObserver.playbackTransitionUpdated(
                progress: progress
            )
 */
        case .cueObserver(let state):
            guard let cueObserver = ref as? CueObserver
                else { return }
            cueObserver.cueUpdated(state: state)
        case .playbackCrossfade(let transition):
            guard let observer = ref as? PlaybackCrossfadeObserver
                else { return }
            observer.playbackCrossfadeUpdated(crossFade: transition)
 */
        }
        
    }
}

public protocol AudioEngineObserver: ObserverClass2 {
    func audioEngineUpdated()
}
*/
