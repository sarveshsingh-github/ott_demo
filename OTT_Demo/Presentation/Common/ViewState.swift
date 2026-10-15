import Foundation

// MARK: - ViewState
// A generic enum representing common UI states.
// This fulfills Requirement #9 (Loading, Success, Empty, Error).

public enum ViewState<T>: Equatable where T: Equatable {
    case idle
    case loading
    case success(T)
    case empty
    case error(String)
}
