
import Vapor
import HTTP
import JWT
import Sessions
import Foundation

public final class APIAuthenticationMiddleware: Middleware {
    
    let client: ClientFactoryProtocol
    let clientId: String
    let tenantID: String
    let issuer: String
    let jwksUrl: String
    let v2Endpoint: Bool
    
    public init(_ client: ClientFactoryProtocol, _ clientId: String, _ tenantID: String, _ instance: String, _ jwksUrl: String, _ v2Endpoint: Bool = false) {
        self.client = client
        self.clientId = clientId
        self.tenantID = tenantID
        self.v2Endpoint = v2Endpoint
        self.jwksUrl = jwksUrl
        
        if v2Endpoint{
            self.issuer = instance + "/" + tenantID + "/v2.0"
        }else{
            self.issuer = instance + "/" + tenantID + "/"
        }
    }
    
    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        try assertAuthenticated(request: req)
        return try next.respond(to: req)
    }
    
    func assertAuthenticated(request: Request) throws{
        guard let authHeader = request.headers["Authorization"] else{
            throw AADError.missingBearerToken
        }
        
        guard authHeader.contains("Bearer") else{
            throw AADError.missingBearerToken
        }
        
        let components = authHeader.components(separatedBy: " ")
        guard components.count == 2 else {
            throw AADError.missingBearerToken
        }
        
        let token = components[1]
        do {
            let jwt = try JWT(token: token)
            try validateJWT(jwt: jwt)
        } catch {
            throw AADError.unauthenticated
        }
    }
    
    func validateJWT(jwt: JWT) throws {
        var n: String
        var e: String
        let kid: String = try jwt.headers.get(TokenKeys.kid)
        let payload = jwt.payload
        
        guard let iss: String = try payload.get(TokenKeys.iss),
            let tid: String = try payload.get(TokenKeys.tid),
            let exp: TimeInterval = try payload.get(TokenKeys.exp) else{
                throw AADError.init(.internalServerError, reason: "Missing one of the following claims in payload: iss, tid, aud, exp")
        }
        
        if v2Endpoint{
            guard let aud: String = try payload.get(TokenKeys.aud) else{
                throw AADError.init(.internalServerError, reason: "Missing the following claim in payload: aud")
            }
            
            guard aud == self.clientId else {
                throw AADError.unauthenticated
            }
        }else{
            guard let appid: String = try payload.get(TokenKeys.appid) else{
                throw AADError.init(.internalServerError, reason: "Missing the following claim in payload: appid")
            }
            
            guard appid == self.clientId else {
                throw AADError.unauthenticated
            }
        }
        
        guard iss == self.issuer,
            tid == self.tenantID,
            exp > Date().timeIntervalSince1970 else {
                throw AADError.unauthenticated
        }
        
        let res = try self.client.get(jwksUrl)
        guard let json = res.json else {
            throw AADError.init(.internalServerError, reason: "Invalid JWKS url")
        }
        
        let keys: JSON = try json.get(TokenKeys.keys)
        for key in keys.array!{
            let id: String = try key.get(TokenKeys.kid)
            if kid == id{
                n = try key.get("n")
                e = try key.get("e")
                let signer = RS256(rsaKey: try RSAKey.init(n: n, e: e, d: nil))
                try jwt.verifySignature(using: signer)
                return
            }
        }
    }
}

extension APIAuthenticationMiddleware: ConfigInitializable {
    public convenience init(config: Config) throws {
        let client = try config.resolveClient()
        
        guard let cID: String = config["aad", "authentication", "clientId"]?.string,
            let tID: String = config["aad", "authentication", "tenantId"]?.string,
            let instance: String = config["aad", "authentication", "instance"]?.string,
            let jUrl: String = config["aad", "authentication", "jwksUrl"]?.string,
            let v2Endpoint = config["aad", "v2Endpoint"]?.bool
        else{
                throw AADError.configIncomplete
        }
        
        self.init(client, cID, tID, instance, jUrl, v2Endpoint)
    }
}
