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

    struct DeleteAccountResponse: Decodable {
        let success: Bool?
        let error: String?
    }

    func deleteAccount() async throws {
        let session = try await client.auth.session
        let jwt = session.accessToken

        let base = Config.supabaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let functionsURL = URL(string: "\(base)/functions/v1/delete-account")!
        var request = URLRequest(url: functionsURL)
        request.httpMethod = "POST"

        // Required for Edge Functions
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        // Auth for your function's getUser(token)
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        // Optional but good practice
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Your function doesn’t use the body; send empty or "{}"
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Decode body (works for both success + error responses)
        let decoded = (try? JSONDecoder().decode(DeleteAccountResponse.self, from: data))

        guard (200...299).contains(http.statusCode), decoded?.success == true else {
            let message = decoded?.error ?? "Delete account failed (HTTP \(http.statusCode))"
            throw NSError(domain: "DeleteAccount", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        // Optional: sign out locally after server-side anonymization
        await AuthService.shared.signOut()
    }
}
