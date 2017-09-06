import cURL
import PerfectCURL
import PerfectLib
import PerfectThread
import Foundation

func Now() -> UInt64 {
  #if os(Linux)
    var n = timespec()
    _ = clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &n)
    return UInt64(n.tv_sec * 1_000_000_000 + n.tv_nsec)
  #else
    return DispatchTime.now().uptimeNanoseconds
  #endif
}

public protocol URLClient {
  init(_ url: String)
  func perform () -> UInt64?
}

public class URLImplPerfect: URLClient {
  let urlString: String
  let curl: CURL
  public required init(_ url: String) {
    urlString = url
    curl = CURL(url: urlString)
  }
  public func perform() -> UInt64? {
    let start = Now()
    let r = curl.performFully()
    let end = Now()
    curl.reset()
    curl.url = urlString
    if r.0 == 0 , (r.1.count + r.2.count) > 0 {
      return end - start
    } else {
      return nil
    }
  }
}

public class URLImplApple: URLClient {
  let request: URLRequest
  let session: URLSession
  public required init(_ url: String) {
    let config = URLSessionConfiguration.default
    request = URLRequest(url: URL(string: url)!)
    session = URLSession(configuration: config)
  }
  public func perform() -> UInt64? {
    let start = Now()
    var elapse: UInt64? = nil
    let task = session.dataTask(with: request) { data, response, error in
      guard let d = data, d.count > 0 else {
        return
      }
      let end = Now()
      elapse = end - start
    }
    task.resume()
    while task.state == .running {
      Threading.sleep(seconds: 0.001)
    }
    return elapse
  }
}

public class URLBenchMark {
  let client: URLClient

  public init(client: URLClient) {
    self.client = client
  }

  public func evaluate(loops: Int) -> (cnt: Int, err: Int, max: UInt64, min: UInt64, avg: UInt64) {
    var mi = UInt64(UINT32_MAX)
    var ma = UInt64(0)
    var total = UInt64(0)
    var count = 0
    var errors = 0
    for _ in 1 ... loops {
      if let elapse = client.perform() {
        if elapse > ma {
          ma = elapse
        }
        if elapse < mi {
          mi = elapse
        }
        total += elapse
        count += 1
      } else {
        errors += 1
      }
    }
    return (cnt: count, err: errors, max: ma, min: mi,
            avg: total / UInt64(count))
  }
}
