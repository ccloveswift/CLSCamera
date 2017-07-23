//
//  CameraMgr.swift
//  CameraC
//
//  Created by TT on 2017/5/13.
//  Copyright © 2017年 TT. All rights reserved.
//

import UIKit
import AVFoundation
import CLSCommon

class CameraMgr: NSObject {

    public static let instance = CameraMgr()
    
    /// 中间设备
    private var mSession: AVCaptureSession!
    /// 前/后 摄像头输入设备
    private var mVideoInput: AVCaptureDeviceInput?
 
    /// 声音输入设备
    private var mAudioInput: AVCaptureDeviceInput?
    
    /// 照片输出流
    private var mStillImageOutput: AVCaptureStillImageOutput?
    
    
    private override init() {
        
        super.init()
        
        self.mSession = AVCaptureSession.init()

    }
    
    func fStart() -> Void {
        
        self.mSession.startRunning()
    }
    
    func fStop() -> Void {
        
        self.mSession.stopRunning()
    }
    
    
    /// 获取当前摄像头前后位置
    ///
    /// - Returns: 前后位置
    func fGetDevicePostion() -> AVCaptureDevicePosition? {
        
        return mVideoInput?.device.position
    }
    
    /// 切换拍照能力
    ///
    /// - Parameter position: 前后参数
    func fSelectStillImageOutput(position: AVCaptureDevicePosition) -> Void {
        
        let bRet = self.fInitVideoInput(position: position)
        guard bRet == true else {
            
            CLSLogError("错误")
            return
        }
        let _ = self.fSelectSessionPreset(preset: AVCaptureSessionPresetPhoto)
    }
    
    func fSelectSessionPreset(preset: String) -> Bool {
        
        if (self.mSession.canSetSessionPreset(preset)) {
            
            self.mSession.sessionPreset = preset;
            return true;
        }
        
        return false;
    }
    
    /// 切换成视频能力
    ///
    /// - Parameter position: 前后参数
    func fSelectVideo(position: AVCaptureDevicePosition) -> Void {
        
        let _ = self.fInitVideoInput(position: position)
        let _ = self.fInitAudioInput()
        let _ = self.fSelectSessionPreset(preset: AVCaptureSessionPresetHigh)
    }
    
    
    /// 获取显示View
    ///
    /// - Parameter frame:
    /// - Returns:
    func fGetPreviewLayer(frame: CGRect) -> AVCaptureVideoPreviewLayer {
        
        let layer = AVCaptureVideoPreviewLayer.init(session: self.mSession)!
        layer.videoGravity = AVLayerVideoGravityResizeAspect;
        layer.frame = frame
        return layer
    }
    
    
    /// 获取前后摄像头的支持
    ///
    /// - Parameter position:
    /// - Returns:
    func fGetDevicePostions(position: AVCaptureDevicePosition) -> Bool {
        
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for device in devices! {
            
            if (device as! AVCaptureDevice).position == position {
                
                return true;
            }
        }
        
        return false;
    }
    
    
    
    private func fInitVideoInput(position: AVCaptureDevicePosition) -> Bool {
        
        if (self.mVideoInput?.device.position == position) {
            
            return true;
        }
        
        self.fRemoveVideoInput()
        
        var videoDevice: AVCaptureDevice!
        
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for device in devices! {
        
            if (device as! AVCaptureDevice).position == position {
                
                videoDevice = device as! AVCaptureDevice
            }
        }
        
        if videoDevice == nil {
            
            videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        do {
            
            self.mVideoInput = try AVCaptureDeviceInput.init(device: videoDevice)
            
            if (self.mSession.canAddInput(self.mVideoInput)) {
                
                self.mSession.addInput(self.mVideoInput)
            }
        }
        catch {
            
            CLSLogError("error: \(error)")
            return false
        }
        
        return true
    }
    
    private func fRemoveVideoInput() {
        
        if let input = self.mVideoInput {
            
            self.mSession.removeInput(input)
            self.mVideoInput = nil
        }
    }
    
    private func fInitAudioInput() -> Bool {
        
        if self.mAudioInput != nil {
            
            return true;
        }
        
        self.fRemoveAudioInput()
        
        if (self.mAudioInput == nil) {
            
            let mAudioInput = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            
            do {
                
                self.mAudioInput = try AVCaptureDeviceInput.init(device: mAudioInput)
                
                if (self.mSession.canAddInput(self.mAudioInput)) {
                    
                    self.mSession.addInput(self.mAudioInput)
                }
            }
            catch {
                
                CLSLogError("error: \(error)")
                return false
            }
        }
        
        return true
    }
    
    private func fRemoveAudioInput() {
        
        if let input = self.mAudioInput {
            
            self.mSession.removeInput(input)
            self.mAudioInput = nil
        }
    }
}
