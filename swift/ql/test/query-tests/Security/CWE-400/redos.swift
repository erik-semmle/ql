//codeql-extractor-options: -module-name ReDoS

import Foundation

let bad1 = try! NSRegularExpression(pattern: "(a|aa)*Y", options: [])