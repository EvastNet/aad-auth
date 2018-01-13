# AAD Auth
AAD Authentication and Authorization Library for use with Vapor

#### Usage
For protecting an API that is registered with AAD, add an `aad.json` file to the `Config/secrets` folder with the following format:
```javascript
{
    "//": "aad.json",
    "//": "AZURE ACTIVE DIRECTORY CONFIGURATION",
    
    "//": "API AUTHENTICATION SETTINGS",
    "authentication": {
        "tenantId": "<AAD_TENANT_ID>",
        "jwksUrl": "https://login.microsoftonline.com/common/discovery/v2.0/keys",
        "instance": "https://login.microsoftonline.com",
        "audience": "<APP_ID>"
    }
}
```
For protecting a Web App that is registered with AAD, add an `aad.json` file to the `Config/secrets` folder with the following format:
```javascript
{
    "//": "aad.json",
    "//": "AZURE ACTIVE DIRECTORY CONFIGURATION",
    
    "//": "API AUTHENTICATION SETTINGS",
    "authentication": {
        "tenantId": "<AAD_TENANT_ID>",
        "clientId": "<APP_ID>",
        "redirectEndpoint": "<REDIRECT_PATH_COMPONENT> ex: for '/redirect' the value entered should be redirect",
        "domain": "<URL> Domian of the app for building the redirect uri. ex: 'http://localhost:8080'",
        "jwksUrl": "https://login.microsoftonline.com/common/discovery/v2.0/keys",
        "instance": "https://login.microsoftonline.com",
        "grantType": "client_credentials",
        "clientSecret": "<CLIENT_SECRET>",
        "scope": "<SCOPE>"
    }
}
```
