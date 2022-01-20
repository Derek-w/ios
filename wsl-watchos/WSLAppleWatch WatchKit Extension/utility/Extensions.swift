
import Foundation
import RxSwift
import UIKit

extension DisposeBag {
    func insertAll(all:Disposable...) {
        for arg: Disposable in all {
            insert(arg)
        }
    }
}

extension String {
    func convertToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
