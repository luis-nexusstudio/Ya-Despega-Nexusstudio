//
//  OrderService.swift
//  YD_App
//
//  Created by Luis Melendez on 20/05/25.
//

// OrderService.swift
import Foundation

struct Order: Decodable {
    let items: [OrderItem]
    let total: Double
    // añade los campos que devuelva tu API
}

struct OrderItem: Decodable, Hashable {
    let name: String
    let qty: Int
}

enum OrderError: Error {
    case urlInvalid, requestFailed, decodingError
}

class OrderService {
    static func fetchOrder(prefId: String,
                           completion: @escaping (Result<Order, OrderError>) -> Void) {
        // reemplaza por la URL real de tu API
        guard let url = URL(string: "http://localhost:4000/api/orders?prefId=\(prefId)") else {
            completion(.failure(.urlInvalid)); return
        }
        URLSession.shared.dataTask(with: url) { data, resp, err in
            guard err == nil, let data = data else {
                completion(.failure(.requestFailed)); return
            }
            do {
                let order = try JSONDecoder().decode(Order.self, from: data)
                completion(.success(order))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
}
