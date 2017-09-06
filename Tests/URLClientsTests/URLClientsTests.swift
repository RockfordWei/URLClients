import XCTest
@testable import URLClients

class URLClientsTests: XCTestCase {
  let site = "https://perfect.org"
  let rounds = 10
  let debug = false

  func testExample() {
    let apple = URLBenchMark(client: URLImplApple(site))
    let perfect =  URLBenchMark(client: URLImplPerfect(site))
    var r = apple.evaluate(loops: rounds)
    print("apple", r)
    r = perfect.evaluate(loops: rounds)
    print("perfect", r)
  }


  static var allTests = [
    ("testExample", testExample),
    ]
}
