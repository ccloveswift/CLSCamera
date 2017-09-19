//
//  CLSCameraMgr.swift
//  CLSCamera
//
//  Created by TT on 2017/5/13.
//  Copyright © 2017年 TT. All rights reserved.
//

import UIKit
import AVFoundation
import CLSCommon

open class CLSCameraMgr: NSObject {

    public static let instance = CLSCameraMgr()
    
    /// 中间设备
    internal var mSession: AVCaptureSession?
    /// 前/后 摄像头输入设备
    internal var mVideoInput: AVCaptureDeviceInput?
 
    /// 声音输入设备
    internal var mAudioInput: AVCaptureDeviceInput?
    
    /// 照片拍照输出
    internal var mStillImageOutput: AVCaptureStillImageOutput?
    
    /// 视频输出流
    internal var mVideoDataOutput: AVCaptureVideoDataOutput?
    
    /// buffer 回调接口
    public var mPreviewBufferBlock: ((_ captureOutput: AVCaptureOutput, _ sampleBuffer: CMSampleBuffer, _ connection: AVCaptureConnection) -> Void)?
    
    
    internal override init() {
        
        super.init()
        #if (arch(x86_64) || arch(i386)) && os(iOS)
        #else
            self.mSession = AVCaptureSession.init()
        #endif
    }
    
    
    /// 开始使用相机模块
    open func fStart() -> Void {
        
        self.mSession?.startRunning()
    }
    
    /// 暂停相机模块
    open func fStop() -> Void {
        
        self.mSession?.stopRunning()
    }
    
    
    /// 获取当前摄像头前后位置
    ///
    /// - Returns: 前后位置
    open func fGetDevicePostion() -> AVCaptureDevicePosition? {
        
        return mVideoInput?.device.position
    }
    
    /// 切换拍照能力
    ///
    /// - Parameter position: 前后参数
    open func fSelectStillImageOutput(position: AVCaptureDevicePosition) -> Void {
        
        let bRet = self.fInitVideoInput(position: position)
        guard bRet == true else {
            
            CLSLogError("错误")
            return
        }
        let _ = self.fInitVideoDataOutput()
        let _ = self.fInitStillImageOutput()
        let _ = self.fSelectSessionPreset(preset: AVCaptureSessionPresetPhoto)
    }
    
    open func fSelectSessionPreset(preset: String) -> Bool {
        
        if let session = self.mSession {
            
            if (session.canSetSessionPreset(preset)) {
                
                session.sessionPreset = preset;
                return true;
            }
        }
        
        return false;
    }
    
    /// 切换成视频能力
    ///
    /// - Parameter position: 前后参数
    open func fSelectVideo(position: AVCaptureDevicePosition) -> Void {
        
        let _ = self.fInitVideoInput(position: position)
        let _ = self.fInitAudioInput()
        let _ = self.fInitVideoDataOutput()
        let _ = self.fInitStillImageOutput()
        let _ = self.fSelectSessionPreset(preset: AVCaptureSessionPresetHigh)
    }
    
    
    /// 获取显示View
    ///
    /// - Parameter frame:
    /// - Returns:
    open func fGetPreviewLayer(frame: CGRect) -> AVCaptureVideoPreviewLayer {
        
        let layer = AVCaptureVideoPreviewLayer.init(session: self.mSession)!
        layer.videoGravity = AVLayerVideoGravityResizeAspect;
        layer.frame = frame
        return layer
    }
    
    
    /// 获取前后摄像头的支持
    ///
    /// - Parameter position:
    /// - Returns:
    open func fGetDevicePostions(position: AVCaptureDevicePosition) -> Bool {
        
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for device in devices! {
            
            if (device as! AVCaptureDevice).position == position {
                
                return true
            }
        }
        
        return false
    }
    
//    var mTorchMode: AVCaptureTorchMode = AVCaptureTorchMode.auto
    var mFlashMode: AVCaptureFlashMode = AVCaptureFlashMode.auto
    
    /// 设置闪光灯状态
    ///
    /// - Parameter torchMode: 闪光灯状态
    /// - Returns: 成功=true
    open func fSetupFlashMode(flashMode: AVCaptureFlashMode) {
        
        mFlashMode = flashMode
    }
    
    private func fResetTorchMode() {
    
        #if (arch(x86_64) || arch(i386)) && os(iOS)
            return
        #endif
        if let input = mVideoInput {
            
            if input.device.hasFlash {
                
                do {
                    try input.device.lockForConfiguration()
                    input.device.flashMode = mFlashMode
                    input.device.unlockForConfiguration()
                } catch {
                    
                }
            }
//            if input.device.hasTorch {
//                
//                do {
//                    /*
//                     off = 0
//                     on = 1
//                     auto = 2
//                     */
//                    CLSLogInfo("当前 device torch mode 状态  \(input.device.torchMode)")
//                    try input.device.lockForConfiguration()
//                    if (mTorchMode == .on) {
//                        
////                        try input.device.setTorchModeOnWithLevel(0.1)
//                        input.device.torchMode = mTorchMode
//                    }
//                    else {
//                        
//                        input.device.torchMode = mTorchMode
//                    }
//                    
//                    input.device.unlockForConfiguration()
//              
//                } catch {
//                    
//                    CLSLogError("Error: fSetupTorchMode \(mTorchMode)")
//                }
//                
//                return
//            }
        }
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
            
            if let session = self.mSession {
            
                if (session.canAddInput(self.mVideoInput)) {
                    
                    session.addInput(self.mVideoInput)
                }
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
            
            self.mSession?.removeInput(input)
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
                
                if let session = self.mSession {
                
                    if (session.canAddInput(self.mAudioInput)) {
                        
                        session.addInput(self.mAudioInput)
                    }
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
            
            self.mSession?.removeInput(input)
            self.mAudioInput = nil
        }
    }
    
    private func fInitVideoDataOutput() -> Bool {
        
        if self.mVideoDataOutput == nil {
            
            guard let session = self.mSession else { return false }
            
            self.mVideoDataOutput = AVCaptureVideoDataOutput.init()
            let fuckPixelFormat = Int(kCVPixelFormatType_32BGRA) // 为了支持iPhone5s
            self.mVideoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : fuckPixelFormat]
            self.mVideoDataOutput?.alwaysDiscardsLateVideoFrames = true
            
            self.mVideoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.init(label: "com.v.data.output"))
            if (session.canAddOutput(self.mVideoDataOutput)) {
                
                session.addOutput(self.mVideoDataOutput)
            }
            else {
                
                return false
            }
        }
        
        return true
    }
    
    private func fInitStillImageOutput() -> Bool {
        
        if self.mStillImageOutput == nil {
        
            guard let session = self.mSession else { return false }
            
            self.mStillImageOutput = AVCaptureStillImageOutput.init()
            self.mStillImageOutput?.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
            if (session.canAddOutput(self.mStillImageOutput)) {
                
                session.addOutput(self.mStillImageOutput)
            }
            else {
                
                return false
            }
        }
        
        return true
    }
    
    public func fCapturePhoto(captureBlock: @escaping (_ jpegData: Data) -> Void) {
        
        if let output = mStillImageOutput {
            
            fResetTorchMode()
            let connection = output.connection(withMediaType: AVMediaTypeVideo)
            output.captureStillImageAsynchronously(from: connection, completionHandler: { (imageDataSampleBuffer: CMSampleBuffer?, error: Error?) in
                
                if error != nil {
                
                    CLSLogError("error = \(String(describing: error))")
                    assert(false)
                }
                else {
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)
                    //let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))!
                    captureBlock(imageData!)
                }
            })
        }
        else {
            
            assert(false)
        }
    }
    
    public func fInitNewSDK() {
        
        if let videoDataOutput = self.mVideoDataOutput {
            
            let videoConn = videoDataOutput.connection(withMediaType: AVMediaTypeVideo)
            videoConn?.videoOrientation = .portrait
        }
    }
}

extension CLSCameraMgr : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        if let block = mPreviewBufferBlock {
            
            block(captureOutput, sampleBuffer, connection)
        }
    }
}
