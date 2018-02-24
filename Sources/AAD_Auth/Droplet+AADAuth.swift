//
//  Droplet+ADAuth.swift

import Vapor

extension Droplet{
    public func setupADAuthentication() throws{
        guard
            let redirectEndpoint = self.config["aad", "authentication", "redirectEndpoint"]?.string,
            let tenantId = config["aad", "authentication", "tenantId"]?.string
        else{
            throw AADError.configIncomplete
        }
        
        post(redirectEndpoint){ request in
            let session = try request.assertSession()
            
            var redirectTo: String
            if let intendedEndpoint: String = try session.data.get("intendedEndpoint"){
                redirectTo = intendedEndpoint
            }else{
                redirectTo = "/"
            }
            return Response(redirect: redirectTo)
        }
        
        get("logout"){ request in
            let user = try AADUser.fetchPersisted(for: request)
            try user?.unpersist(for: request)
            return Response.init(redirect: "https://login.microsoftonline.com/" + tenantId + "/oauth2/logout")
        }
    }
}
