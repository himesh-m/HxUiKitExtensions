//
//  AppUtilities.swift
//  Hearty
//
//  Created by Himesh Mistry on 9/24/21.
//

import Foundation
import UIKit

public class AppUtilities: NSObject {
    // MARK: - Share Instance
    class var sharedInstance: AppUtilities {
        struct Singleton {
            static let instance = AppUtilities()
        }
        return Singleton.instance
    }
    var window: UIWindow?
    
    // MARK: - List out custom font names
    func listFontNames() {
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("Family: \(family) Font names: \(names)")
        }
    }
    //MARK: - Table Footer Spinner
    func headerFooterSpinner(animate: Bool) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: DeviceConstant.screenWidth, height: 100))
        let spinner = UIActivityIndicatorView()
        if animate {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        spinner.center = view.center
        view.addSubview(spinner)
        return view
    }
    //MARK: - Archive Ops
    func archImgData(_ img: UIImage, _ key: String) {
        var imgData = Data()
        if #available(iOS 11.0, *) {
            imgData = try! NSKeyedArchiver.archivedData(withRootObject: img, requiringSecureCoding: true)
        } else {
            imgData = NSKeyedArchiver.archivedData(withRootObject: img)
        }
        userDefault.set(imgData, forKey: key)
        userDefault.synchronize()
    }
    func unarchImgData(_ key: String) -> UIImage {
        let imgData = userDefault.data(forKey: key)
        let imgResult = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imgData ?? Data())
        if imgResult != nil {
            return imgResult as! UIImage
        }
        return UIImage()
    }
    func archData(_ data: Any, _ key: String, _ isSecure: Bool = true) {
        var anyData = Data()
        if #available(iOS 11.0, *) {
            anyData = try! NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: isSecure)
        } else {
            anyData = NSKeyedArchiver.archivedData(withRootObject: data)
        }
        userDefault.set(anyData, forKey: key)
        userDefault.synchronize()
    }
    func unarchData(_ key: String) -> Any {
        let anyData = userDefault.data(forKey: key)
        let result = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(anyData ?? Data())
        return result ?? Data()
    }
    
    //MARK: - Check Update
    func checkUpdate(vc: UIViewController) {
        if !userDefault.bool(forKey: UserKey.remindLater) {
            _ = try? self.isUpdateAvailable { (update, error) in
                if currentVersion < newVersion {
                    self.showAlertUpdate(title: updateAvailable + "\(newVersion)", msg: updateMsg, view: vc)
                }
                if let error = error {
                    debugPrint(error)
                } else if let update = update {
                    debugPrint(update)
                }
            }
        }
    }
    func isUpdateAvailable(completion: @escaping (Bool?, Error?) -> Void) throws -> URLSessionDataTask {
        guard let info = Bundle.main.infoDictionary,
              let strCurrentVersion = info["CFBundleShortVersionString"] as? String,
              let identifier = info["CFBundleIdentifier"] as? String,
              let url = URL(string: updateLink + identifier) else {
                  throw VersionError.invalidBundleInfo
              }
        currentVersion = Int(strCurrentVersion.replacingOccurrences(of: ".", with: "")) ?? 0
        debugPrint(currentVersion)
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let error = error { throw error }
                guard let data = data else { throw VersionError.invalidResponse }
                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
                let jsonResult = json?["results"] as? [Any]
                if !jsonResult!.isEmpty {
                    guard let result = jsonResult?[0] as? [String: Any],
                          let version = result["version"] as? String else {
                              throw VersionError.invalidResponse
                          }
                    debugPrint(version)
                    newVersion = Int(version.replacingOccurrences(of: ".", with: "")) ?? 0
                    completion(version != strCurrentVersion, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
        return task
    }
    enum VersionError: Error {
        case invalidResponse, invalidBundleInfo
    }
    func nextReminderForUpdate() {
        let nextDate = userDefault.value(forKey: UserKey.nextDate) as? Date ?? Date()
        if Date() >= nextDate {
            userDefault.setValue(false, forKey: UserKey.remindLater)
        }
    }
    func showAlertUpdate(title: String, msg: String, view: UIViewController) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let update = UIAlertAction(title: updateNow, style: .default) { UIAlertAction in
            if let url = URL(string: appStoreLink) {
                UIApplication.shared.open(url)
            }
        }
        let later = UIAlertAction(title: remindMeLater, style: .default) { UIAlertAction in
            let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            debugPrint(nextDate)
            userDefault.setValue(nextDate, forKey: UserKey.nextDate)
            userDefault.setValue(true, forKey: UserKey.remindLater)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { UIAlertAction in
        }
        alert.addAction(update)
        alert.addAction(later)
        alert.addAction(cancel)
        DispatchQueue.main.async {
            view.present(alert, animated: true, completion: nil)
        }
    }
    func showAlertWithCompletion(title: String, msg: String, btnTitle: String, view: UIViewController, complete: @escaping (Bool) -> ()) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let btnAction = UIAlertAction(title: btnTitle, style: .default) { UIAlertAction in
            complete(true)
        }
        alert.addAction(btnAction)
        DispatchQueue.main.async {
            view.present(alert, animated: true, completion: nil)
        }
    }
    func showAlertWithAction(title: String, msg: String, btnTitle: String, style: UIAlertAction.Style, view: UIViewController, complete: @escaping (Bool) -> ()) {
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            let btnAction = UIAlertAction(title: btnTitle, style: style) { UIAlertAction in
                complete(true)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { UIAlertAction in
                complete(false)
            }
            alert.addAction(btnAction)
            alert.addAction(cancel)
            DispatchQueue.main.async {
                view.present(alert, animated: true, completion: nil)
            }
    }
    func showAlertSheet(title: String, msg: String, btnTitle1: String, btnTitle2: String, VC: UIViewController, complete: @escaping (Int) -> ()) {
        let alert = UIAlertController.init(title: title, message: msg, preferredStyle: .actionSheet)
        let btnAction1 = UIAlertAction(title: btnTitle1, style: .default) { UIAlertAction in
            complete(1)
        }
        let btnAction2 = UIAlertAction(title: btnTitle2, style: .default) { UIAlertAction in
            complete(2)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { UIAlertAction in
            complete(0)
        }
        alert.addAction(btnAction1)
        alert.addAction(btnAction2)
        alert.addAction(cancel)
        DispatchQueue.main.async {
            VC.present(alert, animated: true, completion: nil)
        }
    }
        
}
