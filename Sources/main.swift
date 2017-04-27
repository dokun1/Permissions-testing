import Kitura
import Foundation

let router = Router()

private func generateRandomSessionString(length: Int) -> String {
    let charArray: [String] = "123456789".characters.map { String($0) }
    var randomString = ""
    for _ in 0 ..< length {
        #if os(Linux)
            let rand = Int(random() % (charArray.count))
        #else
            let rand = Int(arc4random_uniform(UInt32(charArray.count)))
        #endif
        randomString += charArray[rand]
    }
    return randomString
}

public extension Int {
    public var digitCount: Int {
        get {
            return numberOfDigits(in: self)
        }
    }
    private func numberOfDigits(in number: Int) -> Int {
        if abs(number) < 10 {
            return 1
        } else {
            return 1 + numberOfDigits(in: number/10)
        }
    }
}

router.get("/helloWorld") { request, response, next in
    defer { next() }
    response.send(json: ["message" : "hello, world!"])
}

router.get("random/:guess") { request, response, next in
    defer { next() }
    guard let guessString = request.parameters["guess"] else {
        response.send(json: ["error" : "Could not read guess parameter"])
        return
    }
    guard let guess = Int(guessString) else {
        response.send(json: ["error" : "Could not cast guess to integer"])
        return
    }
    guard let randomNumber = Int(generateRandomSessionString(length: guess.digitCount)) else {
        response.send(json: ["error" : "Could not generate random number"])
        return
    }
    response.send(json: ["guess" : guess, "answer" : randomNumber, "isCorrect" : randomNumber == guess])
}

let envVars = ProcessInfo.processInfo.environment
let portString = envVars["PORT"] ?? envVars["CF_INSTANCE_PORT"] ?? envVars["VCAP_APP_PORT"] ?? "8080"
let port = Int(portString) ?? 8080

Kitura.addHTTPServer(onPort: port, with: router)
Kitura.run()
