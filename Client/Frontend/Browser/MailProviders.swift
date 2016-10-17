/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

protocol MailProvider {
    var beginningScheme: String {get set}
    var supportedHeaders: [String] {get set}
    func newEmailURLFromMetadata(metadata: MailToMetadata) -> NSURL?
}

// mailto headers: subject, body, cc, bcc

class ReaddleSparkIntegration : MailProvider {
    var beginningScheme = "readdle-spark://compose?"
    var supportedHeaders = [
        "subject",
        "recipient",
        "textbody",
        "html",
        "cc",
        "bcc"
    ]

    func newEmailURLFromMetadata(metadata: MailToMetadata) -> NSURL? {
        var readdleSparkMailURL = beginningScheme

        var lowercasedHeaders = [String: String]()
        metadata.headers.forEach { (hname, hvalue) in
            lowercasedHeaders[hname.lowercaseString] = hvalue
        }

        var toParam: String
        if let toHValue = lowercasedHeaders["to"] {
            let value = metadata.to.isEmpty ? toHValue : [metadata.to, toHValue].joinWithSeparator("%2C%20")
            lowercasedHeaders.removeValueForKey("to")
            toParam = "recipient=\(value)"
        } else {
            toParam = "recipient=\(metadata.to)"
        }

        var queryParams: [String] = []
        lowercasedHeaders.forEach({ (hname, hvalue) in
            if supportedHeaders.contains(hname) {
                queryParams.append("\(hname)=\(hvalue)")
            }

            if hname == "body" {
                queryParams.append("textbody=\(hvalue)")
            }
        })
        let stringParams = queryParams.joinWithSeparator("&")
        readdleSparkMailURL +=
            stringParams.isEmpty ? toParam : [toParam, stringParams].joinWithSeparator("&")

        return readdleSparkMailURL.asURL
    }
}

class AirmailIntegration : MailProvider {
    var beginningScheme = "airmail://compose?"
    var supportedHeaders = [
        "subject",
        "from",
        "to",
        "cc",
        "bcc",
        "plainBody",
        "htmlBody"
    ]

    func newEmailURLFromMetadata(metadata: MailToMetadata) -> NSURL? {
        var airmailURL = beginningScheme
        var lowercasedHeaders = [String: String]()
        metadata.headers.forEach { (hname, hvalue) in
            lowercasedHeaders[hname.lowercaseString] = hvalue
        }

        var toParam: String
        if let toHValue = lowercasedHeaders["to"] {
            let value = metadata.to.isEmpty ? toHValue : [metadata.to, toHValue].joinWithSeparator("%2C%20")
            lowercasedHeaders.removeValueForKey("to")
            toParam = "to=\(value)"
        } else {
            toParam = "to=\(metadata.to)"
        }

        var queryParams: [String] = []
        lowercasedHeaders.forEach({ (hname, hvalue) in
            if supportedHeaders.contains(hname) {
                queryParams.append("\(hname)=\(hvalue)")
            }

            if hname == "body" {
                queryParams.append("htmlBody=\(hvalue)")
            }
        })
        let stringParams = queryParams.joinWithSeparator("&")
        airmailURL +=
            stringParams.isEmpty ? toParam : [toParam, stringParams].joinWithSeparator("&")
        return airmailURL.asURL
    }
}

class MyMailIntegration : MailProvider {
    var beginningScheme = "mymail-mailto://"
    var supportedHeaders = [
        "to",
        "subject",
        "body",
        "cc",
        "bcc"
    ]

    func newEmailURLFromMetadata(metadata: MailToMetadata) -> NSURL? {
        var myMailURL = beginningScheme
        var lowercasedHeaders = [String: String]()
        metadata.headers.forEach { (hname, hvalue) in
            lowercasedHeaders[hname.lowercaseString] = hvalue
        }

        var toParam: String
        if let toHValue = lowercasedHeaders["to"] {
            let value = metadata.to.isEmpty ? toHValue : [metadata.to, toHValue].joinWithSeparator("%2C%20")
            lowercasedHeaders.removeValueForKey("to")
            toParam = "?to=\(value)"
        } else {
            toParam = "?to=\(metadata.to)"
        }

        let queryParams = lowercasedHeaders.filter { (hname, hvalue) in
            return supportedHeaders.contains(hname)
            } .map { "\($0)=\($1)" } .joinWithSeparator("&")


        myMailURL +=
            queryParams.isEmpty ? toParam : [toParam, queryParams].joinWithSeparator("&")

        return myMailURL.asURL
    }
}

class MailRuIntegration : MyMailIntegration {
    override init() {
        super.init()
        self.beginningScheme = "mailru-mailto://"
    }
}

class MSOutlookIntegration : MailProvider {
    var beginningScheme = "ms-outlook://emails/new?"
    var supportedHeaders = [
        "to",
        "cc",
        "bcc",
        "subject",
        "body"
    ]

    func newEmailURLFromMetadata(metadata: MailToMetadata) -> NSURL? {
        var msOutlookMailURL = beginningScheme

        // The web is a crazy place and some people like to capitalize the hname values in their mailto: links.
        // Make sure we lowercase anything we found in the metadata since Outlook requires them to be lower case.
        var lowercasedHeaders = [String: String]()
        metadata.headers.forEach { (hname, hvalue) in
            lowercasedHeaders[hname.lowercaseString] = hvalue
        }

        // If we have both a [ to ] parameter and an hname 'to', combine them according to the RFC.
        var toParam: String
        if let toHValue = lowercasedHeaders["to"] {
            let value = metadata.to.isEmpty ? toHValue : [metadata.to, toHValue].joinWithSeparator("%2C%20")
            lowercasedHeaders.removeValueForKey("to")
            toParam = "to=\(value)"
        } else {
            toParam = "to=\(metadata.to)"
        }

        let queryParams = lowercasedHeaders.filter { (hname, hvalue) in
            return supportedHeaders.contains(hname)
            } .map { "\($0)=\($1)" } .joinWithSeparator("&")


        msOutlookMailURL +=
            queryParams.isEmpty ? toParam : [toParam, queryParams].joinWithSeparator("&")
        
        return msOutlookMailURL.asURL
    }
}
