//
//  Request+Bearer.swift
//

import Vapor
import Foundation

extension Request{

    public func addBearerToken(_ drop: Droplet) throws{
        let config = drop.config
        let cache = drop.cache
        let client = drop.client
        if let apiToken = try cache.get("apiToken")?.string{
            self.headers["Authorization"] = "Bearer " + apiToken
        }else{
            //expired or non existent token
            guard let instance = config["aad", "authentication", "instance"]?.string,
                let client_id = config["aad", "authentication", "clientId"]?.string,
                let tenant_id = config["aad", "authentication", "tenantId"]?.string,
                let grant_type = config["aad", "authentication", "grantType"]?.string,
                let secret = config["aad", "authentication", "clientSecret"]?.string,
                let scope = config["aad", "authentication", "scope"]?.string,
                let v2Endpoint = config["aad", "v2Endpoint"]?.bool else{
                    throw AADError.configIncomplete
                }
            
            var b = JSON()
            try b.set("client_id", client_id)
            try b.set("client_secret", secret)
            try b.set("grant_type", grant_type)
            
            var tokenUrl = instance
            if v2Endpoint{
                tokenUrl.appendPathComponents([tenant_id, "oauth2", "v2.0", "token"])
                try b.set("scope", scope)
            }else{
                tokenUrl.appendPathComponents([tenant_id, "oauth2", "token"])
                try b.set("resource", scope)
            }
        
            let request = Request(method: .post, uri: tokenUrl, body: b.makeBody())
            request.formURLEncoded = b.makeNode(in: nil)
            let response = try client.respond(to: request)
            guard let token = response.data["access_token"]?.string else{
                throw AADError.init(.internalServerError, reason: "No access token with server response")
            }
            
            guard let expiration = response.data["expires_in"]?.int else{
                throw AADError.init(.internalServerError, reason: "No expiration date with server response")
            }
        
            try cache.set("apiToken", token.makeNode(in: nil), expiration: Date(timeIntervalSinceNow: TimeInterval(expiration)))
            self.headers["Authorization"] = "Bearer " + token
        }
    }
}
