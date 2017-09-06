import XCTest
@testable import URLClients

class URLClientsTests: XCTestCase {
  let site = "https://perfect.org"
  let rounds = 10
  let debug = false

  func testExample() {
    let apple = URLBenchMark(client: URLImplApple(site))
    let perfect =  URLBenchMark(client: URLImplPerfect(site))
    apple.debug = self.debug
    perfect.debug = self.debug
    var r = apple.evaluate(loops: rounds)
    print("apple", r)
    XCTAssertGreaterThan(r.count, 0)
    r = perfect.evaluate(loops: rounds)
    print("perfect", r)
    XCTAssertGreaterThan(r.count, 0)
  }


  static var allTests = [
    ("testExample", testExample),
    ]
}
