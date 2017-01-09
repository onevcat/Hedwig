//
//  Hedwig.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
//
//
import Foundation

#if os(Linux)
import Dispatch
#endif

class Hedwig {
    let actorQueue = DispatchQueue(label: "com.onevcat.Hedwig.actorQueue")
    
    var actors: [SendingActor] = []
    let config: SMTPConfig
    
    init(hostName: String, user: String?, password: String?,
         port: Port? = nil, secure: SMTP.Secure = .tls, validation: SMTP.Validation = .default,
         domainName: String = "localhost", authMethods: [SMTP.AuthMethod] = [.plain, .cramMD5, .login, .xOauth2]) throws
    {
        config = SMTPConfig(hostName: hostName, user: user, password: password, port: port, secure: secure, validation: validation, domainName: domainName, authMethods: authMethods)
    }
    
    func send(_ mails: [Mail], progress: ((Mail) -> Void)? = nil, completion: ((Error?) -> Void)? = nil)
    {
        do {
            let smtp = try SMTP(config: config)
            actorQueue.async {
                let actor = SendingActor(mails: mails, smtp: smtp, progress: progress, completion: completion)
                actor.onFinish = self.actorFinished
                self.actors.append(actor)
                actor.resume()
            }
        } catch {
            completion?(error)
        }
    }
    
    func actorFinished(actor: SendingActor) {
        actor.onFinish = nil
        actorQueue.async {
            if let index = (self.actors.index { $0 === actor }) {
                self.actors.remove(at: index)
            }
        }
    }
}

struct SMTPConfig {
    let hostName: String
    let user: String?
    let password: String?
    let port: Port?
    let secure: SMTP.Secure
    let validation: SMTP.Validation
    let domainName: String
    let authMethods: [SMTP.AuthMethod]
}

extension SMTP {
    convenience init(config: SMTPConfig) throws {
        try self.init(hostName: config.hostName,
                 user: config.user,
                 password: config.password,
                 port: config.port,
                 secure: config.secure,
                 validation: config.validation,
                 domainName: config.domainName,
                 authMethods: config.authMethods)
    }
}

class SendingActor {
    let sendingQueue = DispatchQueue(label: "com.onevcat.Hedwig.sendingQueue")
    var pendings = [Mail]()
    let smtp: SMTP
    
    var sending = false
    
    var onFinish: ((SendingActor) -> Void)?
    
    fileprivate var progress: ((Mail) -> Void)?
    fileprivate var completion: ((Error?) -> Void)?
    
    init(mails: [Mail], smtp: SMTP, progress: ((Mail) -> Void)?, completion: ((Error?) -> Void)?) {
        self.pendings = mails
        self.smtp = smtp
        self.progress = progress
        self.completion = completion
    }
    
    func resume() {
        sendingQueue.async {
            
            if self.sending {
                return
            }
            self.sending = true
            
            do {
                if self.smtp.state != .connected {
                    _ = try self.smtp.connect()
                }
                
                try self.smtp.sayHello()
                if !self.smtp.loggedIn {
                    try self.smtp.login()
                }
                
                try self.sendNext()
            } catch {
                try? self.smtp.close()
                self.sending = false
                self.completion?(error)
                self.onFinish?(self)
            }
        }
    }
    
    private func sendNext() throws {
        if self.pendings.isEmpty {
            
            _ = try smtp.quit()
            
            completion?(nil)
            self.onFinish?(self)
            
            progress = nil
            completion = nil
            return
        }
        
        let mail = pendings.removeFirst()
        try sendFrom(mail)
        try sendTo(mail)
        try sendData(mail)
        try sendDone()
        
        progress?(mail)
        
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
