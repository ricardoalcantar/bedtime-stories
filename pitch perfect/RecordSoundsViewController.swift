//
//  RecordSoundsViewController.swift
//  pitch perfect
//
//  Created by LL on 1/29/16.
//  Copyright © 2016 LL. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate{

    /*
    var = recordingInProgress
    type = IBOutlet
    weak = manage memory for variable, someone else created the var, have a weak reference
    strong = I created teh memory for variable, keep until I no longer needed
    ! = Optional variable, value is optional
    */
    @IBOutlet weak var tapToStart: UILabel!
    @IBOutlet weak var recordingInProgress: UILabel!
    @IBOutlet weak var pausedRecording: UILabel!
    
    
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
   
    var audioRecorder:AVAudioRecorder!
    var recordedAudio: RecordedAudio!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
 
    override func viewWillAppear(_ animated: Bool) {
        recordButton.isEnabled = true
        
        //thing to show
        tapToStart.isHidden = false
        
        //things to hide
        pausedRecording.isHidden=true
        pauseButton.isHidden = true
        resumeButton.isHidden = true
        stopButton.isHidden=true
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //IB = Interface Builder --> linked to story border or interface builder (not ordinary button)
    @IBAction func recordAudio(_ sender: UIButton) {
        //labels
        tapToStart.isHidden = true
        recordingInProgress.isHidden=false
        pausedRecording.isHidden = true

        //buttons
        recordButton.isEnabled=false
        pauseButton.isHidden = false
        pauseButton.isEnabled = true
        stopButton.isHidden=false
        pauseButton.isEnabled = true
        resumeButton.isHidden = true
        
        //TODO: record user's voice
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,  .userDomainMask, true)[0] as String
        
        //Commented out to save space, will only have one new recording to use
        /*
        var currentDateTime = NSDate()
        var formatter = NSDateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        var recordingName = formatter.stringFromDate(currentDateTime)+".wav"
        */
        
        //changed to record only to file "my_audio.wav"
        let recordingName = "my_audio.wav"
        var pathArray = [dirPath,recordingName]
        let filePath = NSURL.fileURL(withPathComponents: pathArray)
        //let filePath = URL.fileURL(withPathComponents: pathArray)
        print(filePath)
        
        //Setup audio session
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        
        //Initialize and prepare to record
        try! audioRecorder=AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder.delegate=self
        audioRecorder.isMeteringEnabled=true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }
    
    //extra credit
    @IBAction func pauseAudioRecord(_ sender: UIButton) {
        //labels
        tapToStart.isHidden = true
        recordingInProgress.isHidden=true
        pausedRecording.isHidden = false
        
        //buttons
        pauseButton.isEnabled = false
        resumeButton.isHidden = false
        audioRecorder.pause()
        
        
        
    }
    
    //extra credit
    @IBAction func restartRecording(_ sender: UIButton) {
        //labels
        tapToStart.isHidden = true
        recordingInProgress.isHidden = false
        pausedRecording.isHidden = true
        
        //buttons
        pauseButton.isEnabled = true
        resumeButton.isHidden = true
        
        audioRecorder.record()
      
    }
    
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if(flag)
        {
            //Step 1 - Save the recorded file
            recordedAudio = RecordedAudio()
            recordedAudio.filePathUrl = recorder.url
            recordedAudio.title = recorder.url.lastPathComponent
            
            //Step 2 - Move to the next scene aka perform segue
            self.performSegue(withIdentifier: "stopRecording", sender: recordedAudio)
        } else {
            print("Recording was NOT successful")
            recordButton.isEnabled=true
            stopButton.isHidden=true
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier=="stopRecording"){
            let playSoundsVC:PlaySoundsViewController = segue.destination as! PlaySoundsViewController
            let data = sender as! RecordedAudio
            playSoundsVC.receivedAudio = data
        }
    }
    @IBAction func stopRecord(_ sender: UIButton) {
        recordingInProgress.isHidden=true
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }

}

