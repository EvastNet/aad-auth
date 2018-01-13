
import HTTP
import Vapor
import Sessions
import Foundation

public final class GroupAuthorizationMiddleware: Middleware {
    
    let policy: AuthPolicy
    public init(policy: AuthPolicy) {
        self.policy = policy
    }
    
    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        guard let user = try AADUser.fetchPersisted(for: req) else{
            throw AADError.unauthenticated
        }
        try authorizeUser(user)
        return try next.respond(to: req)
    }
    
    public func authorizeUser(_ user: AADUser) throws{
        var isAuthorized = false
        for role in policy.permittedRoles{
            guard let groups = user.groups else{
                throw AADError.unauthorized
            }
            for group in groups{
                if role == group{
                    isAuthorized = true
                    break
                }
            }
        }
        
        if !isAuthorized { throw AADError.unauthorized }
    }
    
}

