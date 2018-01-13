//public enum AADError: Error {
//    case unauthenticated
//    case missingBearerToken
//    case unauthorized
//    case serverError(String)
//    case configIncomplete
//    case unknown(Error)
//}
//
//extension AADError: CustomStringConvertible {
//    public var description: String {
//        let reason: String
//
//        switch self {
//        case .unauthenticated:
//            reason = "Invalid Bearer token."
//        case .missingBearerToken:
//            reason = "Missing Bearer token."
//        case .unauthorized:
//            reason = "The request was denied access to the desired resource."
//        case .serverError(let r):
//            reason = "Server Error - \(r)."
//        case .configIncomplete:
//            reason = "Incomplete aad.json config file."
//        case .unknown(let error):
//            reason = "\(error)."
//        }
//
//        return "AAD Error: \(reason)"
//    }
//}

import HTTP
import Node
import Debugging
import Vapor

/// A basic conformance to `AbortError` for
/// convenient error throwing
public struct AADError: AbortError, Debuggable {
    public let status: Status
    public let metadata: Node?
    
    // MARK: Debuggable
    
    /// See Debuggable.readableName
    public static let readableName = "AAD Error"
    
    /// See AbortError.reason
    public let reason: String
    
    /// See Debuggable.identifier
    public let identifier: String
    
    /// See Debuggable.possibleCauses
    public let possibleCauses: [String]
    
    /// See Debuggable.possibleCauses
    public let suggestedFixes: [String]
    
    /// See Debuggable.documentationLinks
    public let documentationLinks: [String]
    
    /// See Debuggable.stackOverflowQuestions
    public let stackOverflowQuestions: [String]
    
    /// See Debuggable.gitHubIssues
    public let gitHubIssues: [String]
    
    /// File in which the error was thrown
    public let file: String
    
    /// Line number at which the error was thrown
    public let line: Int
    
    /// The column at which the error was thrown
    public let column: Int
    
    /// The function in which the error was thrown
    /// TODO: waiting on https://bugs.swift.org/browse/SR-5380
    /// public let function: String
    
    public init(
        _ status: Status,
        metadata: Node? = nil,
        // Debuggable
        reason: String? = nil,
        identifier: String? = nil,
        possibleCauses: [String]? = nil,
        suggestedFixes: [String]? = nil,
        documentationLinks: [String]? = nil,
        stackOverflowQuestions: [String]? = nil,
        gitHubIssues: [String]? = nil,
        file: String = #file,
        line: Int = #line,
        column: Int = #column
        /// See TODO in property decl
        /// function: String = #function
        ) {
        self.status = status
        self.metadata = metadata
        self.reason = reason ?? status.reasonPhrase
        self.identifier = identifier ?? "\(status)"
        self.possibleCauses = possibleCauses ?? []
        self.suggestedFixes = suggestedFixes ?? []
        self.documentationLinks = documentationLinks ?? []
        self.stackOverflowQuestions = stackOverflowQuestions ?? []
        self.gitHubIssues = gitHubIssues ?? []
        self.file = file
        self.line = line
        self.column = column
        /// See TODO in property decl
        /// self.function = function
    }
    
    // most common
    public static let unauthenticated = Abort(.unauthorized, reason: "Invalid Bearer Token")
    public static let missingBearerToken = Abort(.unauthorized, reason: "Missing Bearer token.")
    public static let unauthorized = Abort(.forbidden, reason: "The request was denied access to the desired resource.")
    public static let serverError = Abort(.internalServerError, reason: "Internal Server Error.")
    public static let configIncomplete = Abort(.internalServerError, reason: "Incomplete aad.json config file.")
    public static let unknown = Abort(.internalServerError, reason: "An unknow error occured.")
}
