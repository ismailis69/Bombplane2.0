//
//  PlaySound.swift
//  HappyBird
//
//  Created by Steven Ismaili on 7/14/20.
//  Copyright © 2020 Pierre-Henry Soria. All rights reserved.
//

import AVFoundation
var audioPlayer: AVAudioPlayer?

func playSound(sound: String, type: String){
    if let path = Bundle.main.path(forResource: sound, ofType: type){
        do{
            audioPlayer = try AVAudioPlayer(contentsOf:URL (fileURLWithPath: path))
            audioPlayer?.play()
        } catch {
            print("ERROR")
        }
    }
}

       
       
       
