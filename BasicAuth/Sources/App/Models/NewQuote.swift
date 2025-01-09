import Hummingbird

  //  NewQuote model for create
struct NewQuote: ResponseCodable {
  var quoteText: String
  var author: String
}
