import Foundation

enum ReviewsUpdate {
    
    case insertRows([IndexPath])
    case reloadRows([IndexPath])
    case fullReload
    case loadingStarted
    case loadingFinished
    case showError(String)
    
}
