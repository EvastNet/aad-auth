

protocol Pathable {
    mutating func appendPathComponent(comp: String)
    mutating func appendParameters(params: [String: String])
}

extension String: Pathable{
    
    mutating func appendPathComponent(comp: String){
        let compStr = "/".appending(comp)
        self.append(compStr)
    }
    
    mutating func appendPathComponents(_ comps: [String]){
        for comp in comps{
            self.appendPathComponent(comp: comp)
        }
    }

    mutating func appendParameters(params: [String: String]){
        var parametersStr = "?"
        for param in params{
            parametersStr.append("\(param.key)=\(param.value)&")
        }
        parametersStr.remove(at: parametersStr.index(before: parametersStr.endIndex))
        self.append(parametersStr)
    }
}
