#!/usr/bin/env swift

import Foundation

guard CommandLine.arguments.count > 1 else {
    print("You have to to provide a module name as the first argument.")
    exit(-1)
}

func getUserName(_ args: String...) -> String {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.standardError = pipe
    task.launchPath = "/usr/bin/env"
    task.arguments = ["git", "config", "--global", "user.name"]
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "CIVIPERGENERATOR"
    task.waitUntilExit()
    return output
    //return (output, task.terminationStatus)
}

let userName = getUserName()
let module = CommandLine.arguments[1]
let prefix = CommandLine.arguments[2]
let fileManager = FileManager.default

let workUrl           = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
let moduleUrl         = workUrl.appendingPathComponent(module)

let interfaceRouterUrl         = moduleUrl.appendingPathComponent(prefix+"Router").appendingPathExtension("swift")
let interfacePresenterUrl      = moduleUrl.appendingPathComponent(prefix+"Presenter").appendingPathExtension("swift")
let interfaceInteractorUrl     = moduleUrl.appendingPathComponent(prefix+"Interactor").appendingPathExtension("swift")
let interfaceViewControllerUrl = moduleUrl.appendingPathComponent(prefix+"ViewController").appendingPathExtension("swift")

func fileComment(for module: String, type: String) -> String {
    let today    = Date()
    let calendar = Calendar(identifier: .gregorian)
    let year     = String(calendar.component(.year, from: today))
    let month    = String(format: "%02d", calendar.component(.month, from: today))
    let day      = String(format: "%02d", calendar.component(.day, from: today))

    return """
        //
        //  \(module)\(type).swift
        //  CIViperGenerator
        //
        //  Created by \(userName) on \(day).\(month).\(year).
        //  Copyright © \(year) \(userName). All rights reserved.
        //
        """
}

let interfaceRouter = """
\(fileComment(for: prefix, type: "Router"))

import Foundation
import UIKit

class \(prefix)Router: NSObject {

    weak var presenter: \(prefix)Presenter?

    func setupModule(){
      let view = \(prefix)ViewController()
      let interactor = \(prefix)Interactor()
      let presenter = \(prefix)Presenter()
      let router = \(prefix)Router()

      view.presenter = presenter

      presenter.interactor = interactor
      presenter.view = view
      presenter.router = router

      router.presenter = presenter
      interactor.presenter = presenter
    }
}
"""

let interfacePresenter = """
\(fileComment(for: prefix, type: "Presenter"))

import Foundation

protocol \(prefix)PresenterInterface:class {}
protocol \(prefix)PresenterOutput:class {}
class \(prefix)Presenter:\(prefix)PresenterOutput {

    weak var view:\(prefix)ViewController?
    var router:\(prefix)Router?
    var interactor:\(prefix)Interactor?

}
extension \(prefix)Presenter:\(prefix)PresenterInterface {}

"""

let interfaceViewController = """
\(fileComment(for: prefix, type: "ViewController"))

import Foundation
import UIKit

protocol \(prefix)ViewControllerInterface:class {}
class \(prefix)ViewController : TYRootViewController {

    var presenter : \(prefix)Presenter?

}

extension \(prefix)ViewController:\(prefix)ViewControllerInterface {}

"""

let interfaceInteractor = """
\(fileComment(for: prefix, type: "Interactor"))

import Foundation

protocol \(prefix)InteractorInput:class {}

class \(prefix)Interactor:NSObject {

  weak var presenter:\(prefix)Presenter?

}


"""

do {
    try [moduleUrl].forEach {
        try fileManager.createDirectory(at: $0, withIntermediateDirectories: true, attributes: nil)
    }

    try interfaceRouter.write(to: interfaceRouterUrl, atomically: true, encoding: .utf8)
    try interfacePresenter.write(to: interfacePresenterUrl, atomically: true, encoding: .utf8)
    try interfaceViewController.write(to: interfaceViewControllerUrl, atomically: true, encoding: .utf8)
    try interfaceInteractor.write(to: interfaceInteractorUrl, atomically: true, encoding: .utf8)

}
catch {
    print(error.localizedDescription)
}
