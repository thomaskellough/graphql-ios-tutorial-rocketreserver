//
//  TokenAddingInterceptor.swift
//  RocketReserver
//
//  Created by Thomas Kellough on 5/9/21.
//

import Foundation
import Apollo
import KeychainSwift

class TokenAddingInterceptor: ApolloInterceptor {
    func interceptAsync<Operation>(chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation : GraphQLOperation {
        
        let keychain = KeychainSwift()
        if let token = keychain.get(LoginViewController.loginKeychainKey) {
            request.addHeader(name: "Authorization", value: token)
        }
        
        chain.proceedAsync(request: request, response: response, completion: completion)
    }
}
