//
//  NetworkInterceptorProvider.swift
//  RocketReserver
//
//  Created by Thomas Kellough on 5/9/21.
//

import Foundation
import Apollo

class NetworkInterceptorProvider: LegacyInterceptorProvider {
    override func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation : GraphQLOperation {
        var interceptors = super.interceptors(for: operation)
        interceptors.insert(TokenAddingInterceptor(), at: 0)
        return interceptors
    }
}
