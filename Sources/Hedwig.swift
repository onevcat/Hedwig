//
//  Hedwig.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
//
//  Copyright (c) 2017 Wei Wang <onev@onevcat.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

#if os(Linux)
import Dispatch
#endif

public struct Hedwig {
    let config: SMTPConfig
    
    public init(hostName: String, user: String?, password: String?,
         port: Port? = nil, secure: SMTP.Secure = .tls, validation: SMTP.Validation = .default,
         domainName: String = "localhost", authMethods: [SMTP.AuthMethod] = [.plain, .cramMD5, .login, .xOauth2])
    {
        config = SMTPConfig(hostName: hostName, user: user, password: password, port: port, secure: secure, validation: validation, domainName: domainName, authMethods: authMethods)
    }
    
    public func send(_ mail: Mail,
                     completion: ((Error?) -> Void)? = nil)
    {
        send([mail], progress: nil) { (sent, failed) in
            if sent.isEmpty {
                completion?(failed.first!.1)
            } else {
                completion?(nil)
            }
        }
    }
    
    public func send(_ mails: [Mail],
                     progress: ((Mail, Error?) -> Void)? = nil,
                     completion: ((_ sent: [Mail], _ failed: [(Mail, Error)]) -> Void)? = nil)
    {
        do {
            let smtp = try SMTP(config: config)
            let actor = SendingActor(mails: mails, smtp: smtp, progress: progress, completion: completion)
            actor.resume()
        } catch {
            completion?([], mails.map { ($0, error) })
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
    
    var sent = [Mail]()
    var failed = [(Mail, Error)]()
    
    let smtp: SMTP
    
    var sending = false
    
    fileprivate var progress: ((Mail, Error?) -> Void)?
    fileprivate var completion: (([Mail], [(Mail, Error)]) -> Void)?
    
    init(mails: [Mail], smtp: SMTP, progress: ((Mail, Error?) -> Void)?, completion: (([Mail], [(Mail, Error)]) -> Void)?) {
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
            } catch {
                try? self.smtp.close()
                self.sending = false
                self.completion?([], self.pendings.map { ($0, error) })
            }
            
            if self.sending {
                self.sendNext()
            }
        }
    }
    
    private func sendNext() {
        
        if self.pendings.isEmpty {
            _ = try? smtp.quit()
            sending = false
            completion?(sent, failed)
            progress = nil
            completion = nil
            return
        }
        
        let mail = pendings.removeFirst()

        do {
            try checkMail(mail)
            try sendFrom(mail)
            try sendTo(mail)
            try sendData(mail)
            try sendDone()
            sent.append(mail)
            progress?(mail, nil)
        } catch {
            failed.append((mail, error))
            progress?(mail, error)
        }
        
        // Avoid recursive.
        sendingQueue.async {
            self.sendNext()
        }
    }
    
    private func checkMail(_ mail: Mail) throws {
        if !mail.hasSender {
            throw MailError.noSender
        }
        
        if !mail.hasRecipient {
            throw MailError.noRecipient
        }
    }
    
    private func sendFrom(_ mail: Mail) throws {
        let fromAddress = mail.from?.address ?? ""
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
    
    deinit {
        try? smtp.close()
    }
}
