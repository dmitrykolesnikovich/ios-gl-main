import UIKit
import Foundation

// main!
let argv = UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory(to: UnsafeMutablePointer<Int8>.self, capacity: Int(CommandLine.argc))
UIApplicationMain(CommandLine.argc, argv, nil, NSStringFromClass(AppDelegate.self))
