//
//  AccountService.swift
//  FoodTree
//
//  Created by s8579_stnfrd on 12/16/25.
//

import Foundation
import Supabase

final class AccountService {
    static let shared = AccountService()
    private init() {}

    private let client = SupabaseConfig.shared.client

    func deleteAccount() async throws {
        let session = try await client.auth.session
        let jwt = session.accessToken

        let functionsURL = URL(string: "\(Config.supabaseURL)/functions/v1/delete-account")!
        var request = URLRequest(url: functionsURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        await AuthService.shared.signOut()
    }
}
