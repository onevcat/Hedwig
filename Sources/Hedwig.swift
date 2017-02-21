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

/// Hedwig is the manager type of Hedwig framework. You can initialize an 
/// instance with common SMTP config and then send an email with it.
public struct Hedwig {
    let config: SMTPConfig
    
    /// Initialize a Hedwig instance with SMTP config.
    ///
    /// - Parameters:
    ///   - hostName: Hostname of your SMTP server. 
    ///               The host name should not include any scheme. For example,
    ///               "smtp.example.com" is a valid host name.
    ///   - user: User name used to auth with SMTP server. Pass `nil` to this 
    ///           parameter if there is no need to auth with your server.
    ///   - password: Password used to auth with SMTP server. Pass `nil` to this
    ///               parameter if there is no need to auth with your server.
    ///   - port: Port number which Hedwig should connect to. Default is `nil`, 
    ///           which means Hedwig will determine the port for you according 
    ///           to `secure` parameter and use the standard port.
    ///   - secure: Security level used when communicating with server. Default
    ///             is `.tls`.
    ///   - validation: Validation used when setup a secure connection with 
    ///                 server.
    ///   - domainName: The clinet domain name used when communicating with
    ///                 server. Default is `localhost`
    ///   - authMethods: Auth methods accepted in client when auth with server.
    ///                  By default all auth methods (.plain, .cramMD5, .login, 
    ///                  .xOauth2) in Hedwig are supported.
    ///
    /// - Note:
    ///     Initializing a `Hedwig` instance will not do the actual connecting 
    ///     work. It will not try to connect to server until you send a mail.
    ///
    public init(hostName: String,
                user: String?,
                password: String?,
                port: Port? = nil,
                secure: SMTP.Secure = .tls,
                validation: SMTP.Validation = .default,
                domainName: String = "localhost",
                authMethods: [SMTP.AuthMethod] =
                        [.plain, .cramMD5, .login, .xOauth2])
    {
        config = SMTPConfig(hostName: hostName, user: user, password: password,
                            port: port, secure: secure, validation: validation,
                            domainName: domainName, authMethods: authMethods)
    }
    
    /// Send a single email.
    ///
    /// - Parameters:
    ///   - mail: The email which will be sent.
    ///   - completion: Callback when sending finishes, with an optional `Error`
    ///                 to indicate whether there is an error happened while 
    ///                 sending. If the mail is sent successfully, callback 
    ///                 parameter would be `nil`.
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
    
    /// Send an array of emails.
    ///
    /// - Parameters:
    ///   - mails: The emails which will be sent.
    ///   - progress: Callback when an email sending finishes.
    ///   - completion: Callback when all emails sending finished.
    ///
    /// - Note:
    ///   - If a failure is encountered when while sending multiple mails, the 
    ///     whole sending process will not stop until all pending mails are sent.
    ///     Each mail sending will trigger an invocation of `progress`, and when
    ///     all mails sending finish, `completion` handler will be called.
    ///
    ///   - The parameter of `progress` block contains the mail and an optional
    ///     `Error`. If the mail is sent successfully, the error parameter would
    ///     be `nil`. Otherwise, it contains the error type.
    ///
    ///   - The first parameter of `completion` is an array of sucessully sent 
    ///     mails, while the second is an array of failed mails and 
    ///     corresponding errors for each.
    ///
    ///   - This method will queue the `mails` and send them one by one. If you 
    ///     need to send mails in a concurrent way, call 
    ///     `send(_:progress:completion:)` again with another array of mails.
    ///
    public func send(_ mails: [Mail],
                     progress: ((Mail, Error?) -> Void)? = nil,
                     completion: (
                      (_ sent: [Mail],
                       _ failed: [(mail: Mail, error: Error)]) -> Void)? = nil)
    {
        do {
            let smtp = try SMTP(config: config)
            let actor = SendingActor(mails: mails,
                                     smtp: smtp,
                                     progress: progress,
                                     completion: completion)
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
    fileprivate var completion: (([Mail], [(mail: Mail, error: Error)]) -> Void)?
    
    init(mails: [Mail],
         smtp: SMTP,
         progress: ((Mail, Error?) -> Void)?,
         completion: (([Mail], [(mail: Mail, error: Error)]) -> Void)?)
    {
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
