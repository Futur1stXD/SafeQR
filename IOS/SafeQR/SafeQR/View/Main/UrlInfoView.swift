//
//  LinkInfoView.swift
//  SafeQR
//
//  Created by Abylaykhan Myrzakhanov on 12.04.2024.
//

import SwiftUI

struct UrlInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var scannedCode: String
    
    @State private var urlInfo: UrlInfo?
    
    @State private var isUrlMalicious: Bool = false
    @State private var maliciousCounter: [AttackTypes] = []
    @State private var maliciousErrors: [AttackTypes] = []
    @State private var serverPostingCounter: Int = 0
    
    @State private var isLoading: LoadingState = .none
    
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    enum LoadingState {
        case none
        case info
        case analyze
    }
    
    enum AttackTypes: String, CaseIterable {
        case phishing = "phishing"
        case phishingWeb = "phishing-web"
        case malwareDefacement = "malware-defacement"
        case sqlInjection = "sql-injection"
        case xss = "xss"
        case virusTotal = "virus-total"
        
        func displayName() -> String {
            switch self {
            case .phishing:
                return "Phishing"
            case .phishingWeb:
                return "Phishing Web"
            case .malwareDefacement:
                return "Malware | Defacement"
            case .sqlInjection:
                return "SQL Injection"
            case .xss:
                return "XSS"
            case .virusTotal:
                return "Virus Total"
            }
        }
        
        func icon() -> Image {
            switch self {
            case .phishing:
                return Image(systemName: "fish.circle.fill")
            case .phishingWeb:
                return Image(systemName: "figure.fishing")
            case .malwareDefacement:
                return Image(systemName: "nosign.app")
            case .sqlInjection:
                return Image(systemName: "apple.terminal.on.rectangle")
            case .xss:
                return Image(systemName: "network.slash")
            case .virusTotal:
                return Image(systemName: "shield.lefthalf.filled.trianglebadge.exclamationmark")
            }
        }
    }
    
    let server_ip: String = "192.168.1.92"
    
    var body: some View {
        VStack(spacing: 15) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .frame(width: 25, height: 25)
                    .background(.gray.opacity(0.8))
                    .clipShape(.circle)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Received URL
            VStack(alignment: .leading) {
                Text("URL")
                    .font(.system(size: 16))
                    .bold()
                Text("\(scannedCode)")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
                    .underline()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 60)
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(.gray.opacity(0.4))
            .clipShape(.rect(cornerRadius: 15))
            
            // URL Detailed Info
            if isLoading == .info {
                // Loading && Waiting data from the server
                Spacer(minLength: 15)
                ProgressView()
            } else {
                if let urlInfo = urlInfo {
                    VStack(alignment: .leading) {
                        Text("Domain")
                            .font(.system(size: 16))
                            .bold()
                        Text("\(urlInfo.domain)")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                            .underline()
                    }
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .background(.gray.opacity(0.4))
                    .clipShape(.rect(cornerRadius: 15))
                    
                    HStack {
                        VStack(spacing: 5) {
                            Text("IP-Address")
                                .font(.system(size: 16))
                                .bold()
                            Text("\(urlInfo.ip_address)")
                                .font(.system(size: 12))
                        }
                        .frame(maxWidth: .infinity, maxHeight: 60)
                        .background(.gray.opacity(0.4))
                        .clipShape(.rect(cornerRadius: 15))
                        
                        Spacer()
                        
                        VStack(spacing: 5) {
                            Text("Region")
                                .font(.system(size: 16))
                                .bold()
                            Text("\(urlInfo.countryCode) (\(urlInfo.city))")
                                .font(.system(size: 12))
                        }
                        .frame(maxWidth: .infinity, maxHeight: 60)
                        .background(.gray.opacity(0.4))
                        .clipShape(.rect(cornerRadius: 15))
                    }
                    
                    HStack {
                        // Result && Loading Circle
                        ZStack {
                            Circle()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(.white)
                            
                            Circle()
                                .stroke(!isUrlMalicious ? .green : .red, lineWidth: 2)
                                .frame(width: 80, height: 80)
                            
                            if serverPostingCounter == 6 {
                                Text("\(maliciousCounter.count) / \(AttackTypes.allCases.count)")
                                    .foregroundStyle(.black)
                            } else {
                                ProgressView()
                                    .tint(.black)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment:. center, spacing: 10) {
                            VStack(alignment: .center) {
                                Text("Analyzing URL")
                                    .font(.system(size: 16))
                                    .bold()
                                
                                Text("Phishing, Phishing Web, Malware,\nDefacement, SQL Injection, XSS\nVirus Total")
                                    .font(.system(size: 10))
                                    .italic()
                                    .foregroundStyle(.gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: 60)
                            
                            if serverPostingCounter == 6 {
                                Text(!isUrlMalicious ? "\(Image(systemName: "checkmark.seal.fill")) None of the security systems have marked this URL as malicious." : "\(Image(systemName: "exclamationmark.triangle.fill")) \(maliciousCounter.count) of the security systems visited this URL as malicious.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(isUrlMalicious ? .red : .green)
                                
                                if isUrlMalicious {
                                    VStack {
                                        ForEach(maliciousCounter, id:\.self) { malicious in
                                            Text("\(malicious.icon()) \(malicious.displayName())")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.red)
                                                .padding(.vertical, 5)
                                                .padding(.horizontal, 10)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        ForEach(maliciousErrors, id:\.self) { errors in
                                            Text("\(errors.icon()) \(errors.displayName()): error")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.orange)
                                                .padding(.vertical, 5)
                                                .padding(.horizontal, 10)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            } else {
                                ProgressView()
                                    .tint(.primary)
                                    .padding(.vertical)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(.gray.opacity(0.4))
                    .clipShape(.rect(cornerRadius: 15))
                }
            }
            
            Spacer()
        }
        .padding(10)
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"),
                  message: Text("\(errorMessage)"),
                  dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            Task {
                await getUrlInfo()
                for attack in AttackTypes.allCases {
                    await analyzingUrlPhishing(attack_type_url: attack.rawValue, attack: attack)
                }
            }
        }
    }
    
    // Sending POST request to analyzing basic URL info
    func getUrlInfo() async {
        isLoading = .info
        
        guard let url = URL(string: "http://\(server_ip):8080/url-info") else {
            presentError("Error while making request to the server")
            isLoading = .none
            return
        }
        
        let body = ["url": scannedCode]
        do {
            let finalBody = try JSONSerialization.data(withJSONObject: body)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = finalBody
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let semaphore = DispatchSemaphore(value: 0)
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                defer {
                    semaphore.signal()
                }
                
                if error != nil {
                    presentError("Error while making request to the server")
                    isLoading = .none
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                urlInfo = try? JSONDecoder().decode(UrlInfo.self, from: data)
                
                isLoading = .none
            }
            .resume()
            
            await withCheckedContinuation { continuation in
                DispatchQueue.global().async {
                    semaphore.wait()
                    continuation.resume()
                }
            }
            
        } catch {
            presentError(error.localizedDescription)
            isLoading = .none
        }
    }
    
    // Sending POST request for analyzing URL for phishing
    func analyzingUrlPhishing(attack_type_url: String, attack: AttackTypes) async {
        isLoading = .analyze
        guard let url = URL(string: "http://\(server_ip):8080/\(attack_type_url)") else {
            presentError("Error while making request to the server")
            isLoading = .none
            return
        }
        
        if urlInfo != nil {
    
            let body = ["url": scannedCode]
            
            do {
                let finalBody = try JSONSerialization.data(withJSONObject: body)
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.httpBody = finalBody
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if error != nil {
                        presentError("Error while making request to the server")
                        isLoading = .none
                        return
                    }
                    
                    guard let data = data else {
                        return
                    }
                  
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let result = json["result"] {
                        if result == "bad" || result == "malware" || result == "defacement" {
                            maliciousCounter.append(attack)
                            isUrlMalicious = true
                        }
                        
                        if result == "error" {
                            maliciousErrors.append(attack)
                        }
                        serverPostingCounter += 1
                    } else {
                        presentError("Error while decoding...")
                    }
                    
                    isLoading = .none
                }
                .resume()
            } catch {
                presentError(error.localizedDescription)
                isLoading = .none
            }
        }
    }
    
    // Presenting Error
    func presentError(_ message: String) {
        errorMessage = message
        showError.toggle()
    }
}

#Preview {
    UrlInfoView(scannedCode: .constant(""))
}
