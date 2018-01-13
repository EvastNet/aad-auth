
import Vapor
import Sessions
import JWT
import Foundation

public final class WebAuthenticationMiddleware: Middleware {
    
    let client: ClientFactoryProtocol
    let redirectUri: String
    let redirectEndpoint: String
    let clientID: String
    let tenantID: String
    let instance: String
    let jwksUrl: String
    let domain: String
    let loginUrl: String
    let v2Endpoint: Bool
    
    public init(_ client: ClientFactoryProtocol, _ clientID: String, _ tenantID: String, _ redirectEndpoint: String,  _ instance: String, _ jwksUrl: String, _ domain: String, _ v2Endpoint: Bool = false) {
        self.client = client
        self.clientID = clientID
        self.redirectEndpoint = redirectEndpoint
        self.tenantID = tenantID
        self.instance = instance
        self.jwksUrl = jwksUrl
        self.domain = domain
        self.redirectUri = domain.appending("/").appending(redirectEndpoint)
        self.v2Endpoint = v2Endpoint
        
        var url = instance
        
        if v2Endpoint{
            url.appendPathComponents([self.tenantID, "oauth2", "v2.0", "authorize"])
        }else{
            url.appendPathComponents([self.tenantID, "oauth2", "authorize"])
        }
        
        url.appendParameters(params: [
            "client_id": clientID,
            "response_type": "id_token",
            "redirect_uri": self.redirectUri,
            "response_mode": "form_post",
            "scope": "openid%20profile",
            "nonce": "12345"
            ])
        
        self.loginUrl = url
        
    }
    
    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        if let user = try AADUser.fetchPersisted(for: req){
            do {
                //check if user is still valid
                try validateUser(user)
            } catch  {
                //Invalid User: Redirect to loginUrl
                return Response(redirect: loginUrl)
            }
            //Valid user - continue middleware chain
            return try next.respond(to: req)
        }else{
            if req.uri.path == "/".appending(self.redirectEndpoint){
                //Redirected from microsoft
                //Create new AADUser
                if let idToken = req.data["id_token"]?.string {
                    let user = try AADUser(token: idToken)
                    try validateUser(user)
                    try user.persist(for: req)
                    return try next.respond(to: req)
                }
            }
            //Else send to login
            return Response(redirect: loginUrl)
        }
    }
    
    func validateUser(_ user: AADUser) throws {
        var n: String
        var e: String
        let jwt = user.token
        let kid: String = try jwt.headers.get(TokenKeys.kid)
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

extension WebAuthenticationMiddleware: ConfigInitializable {
    public convenience init(config: Config) throws {
        let client = try config.resolveClient()
        guard let cID: String = config["aad", "authentication", "clientId"]?.string,
            let tID: String = config["aad", "authentication", "tenantId"]?.string,
            let rEndpoint: String = config["aad", "authentication", "redirectEndpoint"]?.string,
            let instance: String = config["aad", "authentication", "instance"]?.string,
            let domain: String = config["aad", "authentication", "domain"]?.string,
            let jUrl: String = config["aad", "authentication", "jwksUrl"]?.string,
            let v2Endpoint = config["aad", "v2Endpoint"]?.bool
        else {
                throw AADError.configIncomplete
        }
        
        self.init(client, cID, tID, rEndpoint, instance, jUrl, domain, v2Endpoint)
    }
}






