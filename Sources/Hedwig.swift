//
//  Hedwig.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
//
//
import Foundation

class Hedwig {
    var sendingQueue = DispatchQueue(label: "com.onevcat.Hedwig.sendingQueue")
    
    var pendings = [Mail]()
    fileprivate var smtp: SMTP
    var sending = false
    
    fileprivate var progress: ((Mail) -> Void)?
    fileprivate var completion: ((Error?) -> Void)?
    
    init(hostName: String, user: String?, password: String?,
         port: Port? = nil, secure: SMTP.Secure = .tls, validation: SMTP.Validation = .default,
         domainName: String = "localhost", authMethods: [SMTP.AuthMethod] = [.plain, .cramMD5, .login, .xOauth2], progress: ((Mail) -> Void)? = nil, completion: ((Error?) -> Void)? = nil) throws
    {
        smtp = try SMTP(hostName: hostName, user: user, password: password, port: port, secure: secure, validation: validation, domainName: domainName, authMethods: authMethods)
        self.progress = progress
        self.completion = completion
    }
    
    deinit {
        progress = nil
        completion = nil
        try? smtp.close()
    }
    
    func send(_ mails: [Mail])
    {
        sendingQueue.async {
            do {
                self.pendings.append(contentsOf: mails)
                if self.sending { return }
                
                self.sending = true
                if self.smtp.state != .connected {
                    _ = try self.smtp.connect()
                }
                
                try self.smtp.sayHello()
                if !self.smtp.loggedIn {
                    try self.smtp.login()
                }
                
                try self.sendNext()
                
            } catch {
                self.pendings.removeAll()
                try? self.smtp.close()
                self.sending = false
                self.completion?(error)
            }
        }
    }
    
    private func sendNext() throws {
        if self.pendings.isEmpty {
            
            _ = try smtp.quit()
            
            completion?(nil)
            progress = nil
            completion = nil
            return
        }
        
        let mail = pendings.removeFirst()
        try sendFrom(mail)
        try sendTo(mail)
        try sendData(mail)
        try sendDone()
        
        try sendNext()
    }
    
    private func sendFrom(_ mail: Mail) throws {
        let fromAddress = mail.from.address
        _ = try smtp.send(.mail(fromAddress))
    }
    
    private func sendTo(_ mail: Mail) throws {
        let to = mail.to
        let cc = mail.cc ?? []
        let bcc = mail.bcc ?? []
        
        let toAddresses = to + cc + bcc
        try toAddresses.forEach {
            _ = try smtp.send(.rcpt($0.address))
        }
    }
    
    private func sendData(_ mail: Mail) throws {
        _ = try smtp.send(.data)
        
        var messageError: Error? = nil
        let mailStream = MailStream(mail: mail) { bytes in
            do { try self.smtp.message(bytes: bytes) }
            catch { messageError = error }
        }
        
        try mailStream.stream()
        
        if let messageError = messageError {
            throw messageError
        }
    }
    
    private func sendDone() throws {
        _ = try smtp.send(.dataEnd)
    }
}
