
import HTTP
import Vapor
import Sessions
import Foundation

public final class RoleAuthorizationMiddleware: Middleware {
    
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
            guard let userRoles = user.roles else{
                throw AADError.unauthorized
            }
            for r in userRoles{
                if role == r{
                    isAuthorized = true
                    break
                }
            }
        }
        
        if !isAuthorized { throw AADError.unauthorized }
    }
    
}

