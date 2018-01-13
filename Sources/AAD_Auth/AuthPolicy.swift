
public protocol AuthPolicy{
    var description: String? { get set }
    var name: String { get set }
    var permittedRoles: [String] {get set}
}

public class Policy: AuthPolicy{
    public var name: String
    public var description: String?
    public var permittedRoles: [String]
    
    public init(
        name: String,
        description: String,
        permittedRoles: [String]
    ) {
        self.description = description
        self.name = name
        self.permittedRoles = permittedRoles
    }
    
    ///TODO:
    
    //init to fetch permitted roles
    
    
}
