import PerfectCURL
import PerfectLib
import PerfectThread
import Foundation
public protocol URLClient {
  init(_ url: String)
  func perform (_ completion: @escaping (String?, String?) -> Void)
}

public class URLImplPerfect: URLClient {
  let urlString: String
  public required init(_ url: String) {
    urlString = url
  }
  public func perform(_ completion: @escaping (String?, String?) -> Void) -> Void {
    CURLRequest(urlString).perform() { confirmation in
      do {
        let response = try confirmation()
        let text = response.bodyString
        completion(text, nil)
      }catch {
        completion(nil, "\(error)")
      }
    }
  }
}

public class URLImplApple: URLClient {
  let config: URLSessionConfiguration
  let urlString: String
  public required init(_ url: String) {
    config = URLSessionConfiguration.default
    urlString = url
  }
  public func perform(_ completion: @escaping (String?, String?) -> Void) -> Void {
    guard let u = URL(string: urlString) else {
      completion(nil, "URL init fault")
      return 
    }
    let request = URLRequest(url: u)
    let session = URLSession(configuration: config)
    let task = session.dataTask(with: request) { data, response, error in
      guard let d = data else {
        completion(nil, "\(error!)")
        return
      }
      let s = d.withUnsafeBytes { (p: UnsafePointer<CChar>) -> String in
        return String(cString: p)
      }
      completion(s, nil)
    }
    task.resume()
  }
}

public class URLBenchMark {
  let client: URLClient

  public var debug = false

  public init(client: URLClient) {
    self.client = client
  }

  public func evaluateOnce(_ completion: @escaping (Int) -> Void) -> Void {

    #if os(Linux)
      var start = timespec()
      _ = clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &start)
    #else
      let start = DispatchTime.now().uptimeNanoseconds
    #endif

    client.perform() { text, error in
      if let txt = text {
        #if os(Linux)
          var end = timespec()
          _ = clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &end)
          let en = end.tv_nsec > start.tv_nsec ? end.tv_nsec - start.tv_nsec : start.tv_nsec - end.tv_nsec
          let es = end.tv_sec - start.tv_sec
          let elapse = Int( es * 1_000_000_000 + en )
        #else
          let end = DispatchTime.now().uptimeNanoseconds
          let elapse = Int (end - start)
        #endif
        completion(elapse)
        if self.debug {
          print(txt)
        }
      } else {
        completion(-1)
        if let err = error, self.debug {
          print(err)
        }
      }
    }
  }

  public func evaluate(loops: Int) -> [String: Int] {
    var res: [String: Int] = [:]
    var mi = Int(INT16_MAX)
    var ma = 0
    var total = 0
    var count = 0
    var errors = 0
    let lock = Threading.Lock()
    for _ in 1 ... loops {
      evaluateOnce() { elapse in
        lock.doWithLock {
          if elapse < 0 {
            errors += 1
          } else {
            total += elapse
            count += 1
            if elapse < mi {
              mi = elapse
            }
            if elapse > ma {
              ma = elapse
            }
          }
        }
      }
    }
    while (count + errors) < loops {
      usleep(1000)
    }
    res["cnt"] = count
    res["max"] = ma / 1_000
    res["min"] = mi / 1_000
    if count > 0 {
      res["avg"] = total / count / 1_000
    }
    res["err"] = errors
    return res
  }
}
