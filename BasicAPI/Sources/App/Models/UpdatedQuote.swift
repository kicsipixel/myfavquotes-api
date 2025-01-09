import Foundation
import Hummingbird

  //  UpdatedQuote model for edit
struct UpdatedQuote: ResponseCodable {
  var quoteText: String?
  var author: String?
}
