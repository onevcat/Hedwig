<p align="center">

<img src="https://cloud.githubusercontent.com/assets/1019875/21935666/b7f8af46-d9f1-11e6-85d7-1cb4bc025226.png"/>

</p>

<p align="center">

<a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/swift-3.0-brightgreen.svg"/></a>

<a href="https://travis-ci.org/onevcat/Hedwig"><img src="https://img.shields.io/travis/onevcat/Hedwig/master.svg"></a>

<a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/platform-macos%20|%20Linux-blue.svg"/></a>

<a href="https://codecov.io/gh/onevcat/Hedwig"><img src="https://codecov.io/gh/onevcat/Hedwig/branch/master/graph/badge.svg"/></a>

<a href="https://codebeat.co/projects/github-com-onevcat-hedwig"><img alt="codebeat badge" src="https://codebeat.co/badges/87196d17-29e4-4152-b24e-20eaab8d718b" /></a>

<a href="https://raw.githubusercontent.com/onevcat/Hedwig/master/LICENSE"><img src="https://img.shields.io/cocoapods/l/Hedwig.svg?style=flat"/></a>

</p>

---

Hedwig is a Swift package which supplies a set of high level APIs to allow you sending email to an SMTP server easily. If you are planning to send emails from your next amazing Swift server app, Hedwig might be a good choice.

## Features

- [x] Connect to all SMTP servers, through whether plain, SSL or TLS (STARTTLS) port.
- [x] Authentication with `PLAIN`, `CRAM-MD5`, `LOGIN` or `XOAUTH2`.
- [x] Send email with HTML body and attachments.
- [x] Customize validation method and mail header, to track your mail campaign.
- [x] Queued mail sending, without blocking your app. You can even send mails concurrently.
- [x] Works with Swift Package Manager, in the latest Swift syntax and cross-platform.
- [x] Fully tested and [documented](https://onevcat.github.io/Hedwig/).

## Installation

Add the url of this repo to your Package.swift:

```swift
import PackageDescription

let package = Package(
    name: "YourAwesomeSoftware",
    dependencies: [
        .Package(url: "https://github.com/onevcat/Hedwig.git", 
                 majorVersion: 1)
    ]
)
```

Then run `swift build` whenever you get prepared. (Also remember to grab a cup of coffee 😄)

You can find more information on how to use Swift Package Manager in Apple's [official page](https://swift.org/package-manager/).

## Usage

### Sending text only email

```swift
let hedwig = Hedwig(hostName: "smtp.example.com", user: "foo@bar.com", password: "password")
let mail = Mail(
        text: "Across the great wall we can reach every corner in the world.", 
        from: "onev@onevcat.com", 
        to: "foo@bar.com", 
        subject: "Hello World"
)
    
hedwig.send(mail) { error in
    if error != nil { /* Error happened */ }
}
```

### Sending HTML email

```swift
let hedwig = Hedwig(hostName: "smtp.example.com", user: "foo@bar.com", password: "password")
let attachment = Attachment(htmlContent: "<html><body><h1>Title</h1><p>Content</p></body></html>")
let mail = Mail(
        text: "Fallback text", 
        from: "onev@onevcat.com", 
        to: "foo@bar.com", 
        subject: "Title", 
        attachments: [attachment]
)
hedwig.send(mail) { error in
    if error != nil { /* Error happened */ }
}
```

### CC and BCC

```swift
let hedwig = Hedwig(hostName: "smtp.example.com", user: "foo@bar.com", password: "password")
let mail = Mail(
        text: "Across the great wall we can reach every corner in the world.", 
        from: "onev@onevcat.com", 
        to: "foo@bar.com",
        cc: "Wei Wang <onev@onevcat.com>, tom@example.com", // Addresses will be parsed for you
        bcc: "My Group: onev@onevcat.com, foo@bar.com;",    // Even with group syntax
        subject: "Hello World"
)
hedwig.send(mail) { error in
    if error != nil { /* Error happened */ }
}
```

### Using different SMTP settings (security layer, auth method and etc.)

```swift
let hedwig = Hedwig(
        hostName: "smtp.example.com", 
        user: "foo@bar.com", 
        password: "password",
        port: 1234,     // Determined from secure layer by default
        secure: .plain, // .plain (Port 25) | .ssl (Port 465) | .tls (Port 587) (default)
        validation: .default, // You can set your own certificate/cipher/protocols
        domainName: "onevcat.com", // Used when saying hello to STMP Server
        authMethods: [.plain, .login] // Default: [.plain, .cramMD5, .login, .xOauth2]        
)
```

### Send mails with inline image and other attachment

```swift
let imagePath = "/tmp/image.png"
// You can create an attachment from a local file path.
let imageAttachment = Attachment(
        filePath: imagePath, 
        inline: true, 
        // Add "Content-ID" if you need to embed this image to another attachment.
        additionalHeaders: ["Content-ID": "hedwig-image"] 
)
let html = Attachment(
        htmlContent: "<html><body>A photo <img src=\"cid:hedwig-image\"/></body></html>", 
        // If imageAttachment only used embeded in HTML, I recommend to set it as related.
        related: [imageAttachment]
)

// You can also create attachment from raw data.
let data = "{\"key\": \"hello world\"}".data(using: .utf8)!
let json = Attachment(
        data: data, 
        mime: "application/json", 
        name: "file.json", 
        inline: false // Send as standalone attachment.
)

let mail = Mail(
        text: "Fallback text", 
        from: "onev@onevcat.com", 
        to: "foo@bar.com", 
        subject: "Check the photo and json file!",
        attachments: [html, json]
hedwig.send(mail) { error in
    if error != nil { /* Error happened */ }
}
```

### Send multiple mails

```swift
let mail1: Mail = //...
let mail2: Mail = //...

hedwig.send([mail1, mail2], 
        progress: { (mail, error) in
            if error != nil { 
                print("\(mail) failed. Error: \(error)") 
            }
        },
        completion: { (sent, failed) in
            for mail in sent {
                print("Sent mail: \(mail.messageId)")
            }
            
            for (mail, error) in failed {
                print("Mail \(mail.messageId) errored: \(error)")
            }
        }
)

```

## Help and Questions

Visit the [documentation page](https://onevcat.github.io/Hedwig/) for full API reference.

You could also run the tests (`swift test`) to see more examples to know how to use Hedwig.

If you have found the framework to be useful, please consider a donation. Your kind contribution will help me afford more time on the project.

<p align="center"><a href='https://pledgie.com/campaigns/33218'><img alt='Click here to lend your support to: Hedwig and make a donation at pledgie.com !' src='https://pledgie.com/campaigns/33218.png?skin_name=chrome' border='0' ></a></p>

Or you are a Bitcoin fan and want to treat me a cup of coffe, here is my wallet address:

```
1MqwfsxBJ5pJX4Qd2sRVhK3dKTQrWYooG5
```

### FAQ

#### I cannot send mails with Gmail SMTP.

> Gmail uses an application specific password. You need to create one and use the specified password when auth. See [this](https://support.google.com/accounts/answer/185833?hl=en).

#### I need to add/set some additonal header in the mail.

> Both `Mail` and `Attachment` accept customizing header fields. Pass your headers as `additionalHeaders` when creating the mail or attachment and Hedwig will handle it.

#### Can I use it in iOS?

> At this time Swift Package Manager has no support for iOS, watchOS, or tvOS platforms. So the answer is no. But this framework is not using anything only in iOS (like UIKit), so as soon as Swift Package Manager supports iOS, you can use it there too.

#### Tell me about the name and logo of Hedwig

> Yes, Hedwig (bird) was Harry Potter's pet Snowy Owl. The logo of Hedwig (this framework) is created by myself and it pays reverence to the novels and movies.

#### Other questions

> Submit [an issue](https://github.com/onevcat/Hedwig/issues/new) if you find something wrong. Pull requests are warmly welcome, but I suggest to discuss first.

You can also follow and contact me on [Twitter](http://twitter.com/onevcat) or [Sina Weibo](http://weibo.com/onevcat).

### Enjoy sending your emails

![](https://cloud.githubusercontent.com/assets/1019875/21879961/8321a0ba-d8df-11e6-968d-41992815d2f6.gif)

### License

Hedwig is released under the MIT license. See LICENSE for details.


