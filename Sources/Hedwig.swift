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
    var smtp: SMTP
    var sending = false
    
    fileprivate var progress: ((Mail) -> Void)?
    fileprivate var completion: ((Error?) -> Void)?
    
    init?(hostName: String, user: String?, password: String?,
         port: Port? = nil, secure: SMTP.Secure = .tls, validation: SMTP.Validation = .default,
         domainName: String = "", authMethods: [SMTP.AuthMethod] = [.plain, .cramMD5, .login, .xOauth2], progress: ((Mail) -> Void)? = nil, completion: ((Error?) -> Void)? = nil)
    {
        do {
            smtp = try SMTP(hostName: hostName, user: user, password: password, port: port, secure: secure, validation: validation, domainName: domainName, authMethods: authMethods)
            self.progress = progress
            self.completion = completion
        } catch {
            return nil
        }
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
                self.sending = true
                try? self.smtp.close()
                self.completion?(error)
            }
        }
    }
    
    func sendNext() throws {
        if self.pendings.isEmpty {
            completion?(nil)
            return
        }
        
        let mail = pendings.removeFirst()
        try sendFrom(mail)
        try sendTo(mail)
        try sendData(mail)
        try sendDone()
        
        try sendNext()
    }
    
    func sendFrom(_ mail: Mail) throws {
        let fromAddress = mail.from.address
        _ = try smtp.send(.mail(fromAddress))
    }
    
    func sendTo(_ mail: Mail) throws {
        let to = mail.to ?? []
        let cc = mail.cc ?? []
        let bcc = mail.bcc ?? []
        
        let toAddresses = to + cc + bcc
        try toAddresses.forEach {
            _ = try smtp.send(.rcpt($0.address))
        }
    }
    
    func sendData(_ mail: Mail) throws {
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
    
    func sendDone() throws {
        _ = try smtp.send(.dataEnd)
    }
}
