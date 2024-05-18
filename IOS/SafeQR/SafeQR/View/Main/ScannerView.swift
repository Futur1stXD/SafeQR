//
//  ScannerView.swift
//  SafeQR
//
//  Created by Abylaykhan Myrzakhanov on 11.04.2024.
//

import SwiftUI
import AVKit

struct ScannerView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var qrDelegate = QRScannerDelegate()
    @State private var scannedCode: String = ""
    
    @State private var isScanning: Bool = false
    @State private var session: AVCaptureSession = .init()
    @State private var cameraPermission: CameraPermission = .idle
    
    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    
    @State private var showUrlInfo: Bool = false
    
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Place the QR code inside the area")
                .font(.title3)
                .foregroundStyle(.primary.opacity(0.8))
                .padding(.top, 20)
            
            Text("Scanning will start automatically")
                .font(.callout)
                .foregroundStyle(.gray)
            
            // Scanner
            GeometryReader {
                let size = $0.size
                
                ZStack {
                    CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                        .scaleEffect(0.97)
                    
                    ForEach(0...4, id:\.self) { index in
                        let rotation = Double(index) * 90
                        
                        RoundedRectangle(cornerRadius: 2, style: .circular)
                            .trim(from: 0.61, to: 0.64)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                            .rotationEffect(.init(degrees: rotation))
                    }
                }
                .frame(width: size.width, height: size.width)
                .overlay(alignment: .top, content: {
                    Rectangle()
                        .fill(.blue)
                        .frame(height: 2.5)
                        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: isScanning ? 15 : -15)
                        .offset(y: isScanning ? size.width : 0)
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 25)
            
            Spacer(minLength: 100)
        }
        .padding(15)
        .onAppear(perform: checkCameraPermission)
        .alert(errorMessage, isPresented: $showError) {
            if cameraPermission == .denied {
                Button("Settings") {
                    let settingsString = UIApplication.openSettingsURLString
                    if let settingsUrl = URL(string: settingsString) {
                        openURL(settingsUrl)
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
        }
        .onChange(of: qrDelegate.scannedCode) {
            if let code = qrDelegate.scannedCode {
                scannedCode = code
                
                // When code is analyzed, stop the camera
                session.stopRunning()
                stopScannerAnimation()
                
                // Clearing the Data on Delegate
                qrDelegate.scannedCode = nil
                
                showUrlInfo.toggle()
            }
        }
        .sheet(isPresented: $showUrlInfo, content: {
            UrlInfoView(scannedCode: $scannedCode)
                .presentationDetents([.height(600)])
                .presentationCornerRadius(15)
        })
        .onChange(of: showUrlInfo) {
            // If sheet is closed
            if !showUrlInfo {
                if !session.isRunning && cameraPermission == .approved {
                    reactivateCamera()
                    activateScannerAnimation()
                }
            }
        }
    }
    
    // Reactivating Camera Session
    func reactivateCamera() {
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    // Activating Scanner Animation
    func activateScannerAnimation() {
        withAnimation(.easeInOut(duration: 0.8).delay(0.1).repeatForever(autoreverses: true)) {
            isScanning = true
        }
    }
    
    // Stop Scanner Animation
    func stopScannerAnimation() {
        withAnimation(.easeInOut(duration: 0.8)) {
            isScanning = false
        }
    }
    
    // Checking Camera Permission
    func checkCameraPermission() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                cameraPermission = .approved
                if session.inputs.isEmpty {
                    setupCamera()
                } else {
                    // Already existing one
                    
                    reactivateCamera()
                }
            case .notDetermined:
                // Requesting Camera Access
                if await AVCaptureDevice.requestAccess(for: .video) {
                    cameraPermission = .approved
                    setupCamera()
                } else {
                    cameraPermission = .denied
                    presentError("Please Provide Access to Camera for analyze the QR code")
                }
            case .denied, .restricted:
                cameraPermission = .denied
                presentError("Please Provide Access to Camera for analyze the QR code")
            default: break
            }
        }
    }
    
    // Setting Up Camera
    func setupCamera() {
        do {
            // Finding Back Camera
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first else {
                presentError("UNKNOWN DEVICE ERROR")
                return
            }
            
            // Camera Input
            let input = try AVCaptureDeviceInput(device: device)
            
            // Checking Wheter input & output can be added to the session
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else {
                presentError("UNKNOWN INPUT/OUTPUT ERROR")
                return
            }
            
            // Adding Input & Output to Camera Session
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            
            //Setting Output config to read QR Code
            qrOutput.metadataObjectTypes = [.qr]
            
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            
            // Note Session must be started on Background thread
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
            
            activateScannerAnimation()
        } catch {
            presentError(error.localizedDescription)
        }
    }
    
    // Presenting Error
    func presentError(_ message: String) {
        errorMessage = message
        showError.toggle()
    }
}

#Preview {
    ScannerView()
}
