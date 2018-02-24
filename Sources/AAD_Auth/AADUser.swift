import HTTP
import Vapor
import Sessions
import JWT
import Foundation

public final class AADUser{
    
    public let id: String
    public let name: String
    public let email: String?
    public let groups: [String]?
    public let roles: [String]?
    public let token: JWT
    public let rawToken: String
    public let givenName: String?
    public let familyName: String?
    
    public var initials: String? {
        var i: String
        let components = name.components(separatedBy: " ")
        guard components.count > 1,
            let first = components[0].first,
            let second = components[1].first
        else{
            return nil
        }
    
        i = "\(first)\(second)"
        
        return i
    }
    
    init(token: String) throws {
        
        self.rawToken = token
        self.token = try JWT(token: token)
        self.name = try self.token.payload.get("name")
        self.givenName = try self.token.payload.get("given_name")
        self.familyName = try self.token.payload.get("family_name")
        self.id = try self.token.payload.get("oid")
        self.groups = try self.token.payload.get("groups")
        self.roles = try self.token.payload.get("roles")
        
        var tokenEmail: String?
        
        if let preferred_username: String = try self.token.payload.get("preferred_username"){
            tokenEmail = preferred_username
        }else if let upn: String = try self.token.payload.get("upn") {
            tokenEmail = upn
        }
        
        self.email = tokenEmail
    }
    
    public func persist(for req: Request) throws {
        let session = try req.assertSession()
        
        do {
            
            let u: Node = try session.data.get("sessionUser")
            let user = try AADUser(node: u)
            if user.id != self.id{
                
                try session.data.set("sessionUser", self.makeNode(in: nil))
            }
            
        } catch {
            
            try session.data.set("sessionUser", self.makeNode(in: nil))
        }
    }
    
    public func unpersist(for req: Request) throws {
        try req.assertSession().data.removeKey("sessionUser")
    }
    
    public static func fetchPersisted(for req: Request) throws -> AADUser? {
        let session = try req.assertSession()
        guard let u = try session.data.get("sessionUser") as Node? else {
            
            return nil
        }
        
        let user = try AADUser(node: u)
        
        return user
    }
}
extension AADUser: NodeInitializable {
    convenience public init(node: Node) throws {
        try self.init(token: node.get("token"))
    }
}
extension AADUser: NodeRepresentable {
    
    public func makeNode(in context: Context?) throws -> Node {
        var node = Node(context)
        try node.set("id", self.id)
        try node.set("token", self.rawToken)
        try node.set("name", self.name)
        try node.set("email", self.email)
        try node.set("initials", self.initials)
        try node.set("givenName", self.givenName)
        try node.set("familyName", self.familyName)
        try node.set("groups", self.groups)
        return node
        
    }
    
}
