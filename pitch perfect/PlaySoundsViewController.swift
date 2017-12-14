//
//  PlaySoundsViewController.swift
//  pitch perfect
//
//  Created by LL on 1/30/16.
//  Copyright © 2016 LL. All rights reserved.
//

import UIKit
import AVFoundation
import AWSS3
import AWSCore
import AWSCognito

class PlaySoundsViewController: UIViewController {
    
    var audioPlayer:AVAudioPlayer! //declared here
    var audioPlayer2:AVAudioPlayer! // used for echo
    var receivedAudio:RecordedAudio!
    
    var audioEngine: AVAudioEngine!
    var audioFile: AVAudioFile!
    
    /*
    citation
    http://sandmemory.blogspot.com/2014/12/how-would-you-add-reverbecho-to-audio.html
    tutorial on reverb and echo
    */
    var revPlayers:[AVAudioPlayer] = [] //declare an array of players to reverb,same idea as echo, but with more players and decreasing volume
    let N:Int = 10
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioPlayer = try! AVAudioPlayer(contentsOf: receivedAudio.filePathUrl as URL)
        //rate
        audioPlayer.enableRate=true
        audioPlayer2 = try! AVAudioPlayer(contentsOf: receivedAudio.filePathUrl as URL)
        //rate
        audioPlayer2.enableRate=true
        audioEngine = AVAudioEngine()
        audioFile = try! AVAudioFile(forReading: receivedAudio.filePathUrl as URL)
        
        //Reverb - iterate thru using for-loop
        for i in 0...N{
            let temp = try! AVAudioPlayer(contentsOf: receivedAudio.filePathUrl as URL)
            revPlayers.append(temp)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func playAudioWithVariablePitch(_ pitch:Float){
        audioPlayer.stop()
        audioEngine.stop()
        audioEngine.reset()
        
        let audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        let changePitchEffect = AVAudioUnitTimePitch()
        changePitchEffect.pitch = pitch
        audioEngine.attach(changePitchEffect)
        
        audioEngine.connect(audioPlayerNode, to:changePitchEffect, format:nil)
        audioEngine.connect(changePitchEffect, to:audioEngine.outputNode, format:nil)
        
        audioPlayerNode.scheduleFile(audioFile, at:nil, completionHandler:nil)
        try! audioEngine.start()
        
        audioPlayerNode.play()
    }
    
    
    //changed to play normal auto
    @IBAction func playSlowAudio(_ sender: UIButton) {
        //Play audio slowly here..
        audioPlayer.stop()  //good practice to stop it before it begins
        audioEngine.stop()
        audioEngine.reset()
        audioPlayer.rate=1.0
        audioPlayer.currentTime=0.0 //ensures audio starts from beg.
        audioPlayer.play() //used here
    }
    
    @IBAction func playFastAudio(_ sender: UIButton) {
        //Play audio quickly here...
        audioPlayer.stop()
        audioEngine.stop()
        audioEngine.reset()
        audioPlayer.rate=1.5
        audioPlayer.currentTime=0.0 //ensures audio starts from beg.
        audioPlayer.play()
    }
    
    @IBAction func playChipmunkAudio(_ sender: UIButton) {
        audioPlayer.stop()
        playAudioWithVariablePitch(1000)
    }
    
    @IBAction func playDarthvaderAudio(_ sender: UIButton) {
        audioPlayer.stop()
        playAudioWithVariablePitch(-1000)
    }
    
    
    @IBAction func playReverbAudio(_ sender: UIButton) {
        audioPlayer.stop()
        let delay:TimeInterval=0.05
        for i in 0...N {
            let currentDelay:TimeInterval = delay * TimeInterval(i)
            let player:AVAudioPlayer = revPlayers[i]
            let exponent:Double = (-Double(i))/(Double(N/2)) //log
            let volume = Float(pow(Double(M_E), exponent))
            player.volume = volume
            player.play(atTime: player.deviceCurrentTime + currentDelay)
            
        }
    }
    
  
    @IBAction func playEchoAudio(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime=0.0
        audioPlayer.play()
        
        let delay:TimeInterval=0.2 //200ms, the amount of delay
        var playtime:TimeInterval
        playtime = audioPlayer2.deviceCurrentTime + delay
        audioPlayer2.stop()
        audioPlayer2.currentTime = 0
        audioPlayer2.volume = 0.7
        audioPlayer2.play(atTime: playtime)
        
    }
    
    @IBAction func stopAllAudio(_ sender: UIButton) {
        audioPlayer.stop()
    }
    
    @IBAction func uploadAudio(_ sender: UIButton) {
        print("uploadAudio button pressed")
        audioPlayer.stop()
        //let accessKey = "ryanlevin"
        //let secretKey = "ricarla"
        
        
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
                                                                identityPoolId:"us-east-1:cfd8959a-655e-4f69-aa17-892244c988d5")
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        let cognitoId = credentialsProvider.identityId
        print(cognitoId)
        
        let url = receivedAudio.filePathUrl
        let remoteName = "places.wav"
        let S3BucketName = "storytime1234"
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()!
        uploadRequest.body = url!
        uploadRequest.key = remoteName
        uploadRequest.bucket = S3BucketName
        uploadRequest.contentType = "audio/wav"
        uploadRequest.acl = .publicRead
        
        let transferManager = AWSS3TransferManager.default()
        transferManager.upload(uploadRequest).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as? NSError {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error uploading: \(uploadRequest.key) Error: \(error)")
                    }
                } else {
                    print("Error uploading: \(uploadRequest.key) Error: \(error)")
                }
                return nil
            }
            
            let uploadOutput = task.result
            print("Upload complete for: \(uploadRequest.key)")
            return nil
        })
        
        
        /*
        if let fileUrl = receivedAudio.filePathUrl {
            
            let directoryName = WebClient.sharedInstance().assessment.assessmentHeader.uniqueId
            
            WebClient.sharedInstance().assessment.assessmentBody.images[currentQuestionIndex].responseAudioUrl = APTAWSConstants.ResponseStorageBucketBaseUrl + directoryName + "/" + fileUrl.lastPathComponent
            
            print("responseAudioUrl = " + WebClient.sharedInstance().assessment.assessmentBody.images[currentQuestionIndex].responseAudioUrl)
            
            print("attempting to upload file: \(fileUrl.lastPathComponent)")
            
            let uploadRequest = AWSS3TransferManagerUploadRequest()
            uploadRequest?.body = fileUrl
            uploadRequest?.key = directoryName + "/" + fileUrl.lastPathComponent
            uploadRequest?.bucket = APTAWSConstants.ResponseStorageBucketName
            
            print("Upload request started...")
            
            activityIndicatorShow()
            
            // Helper function that initiates the upload to S3, see code for it below **
            WebClient.uploadToS3(uploadRequest) { (success: Bool) in
                
                self.activityIndicatorHide()
                
                if success {
                    print("Upload finished successfully.")
                } else {
                    print("!! Upload failed !!")
                }
            }
        }
        
        if currentQuestionIndex < WebClient.sharedInstance().assessment.assessmentBody.images.count - 1 {
            currentQuestionIndex += 1
            loadQuestionAtIndex(currentQuestionIndex)
            resetInterface()
        } else {
            endOfAssessment()
        }
        */
    }
}
