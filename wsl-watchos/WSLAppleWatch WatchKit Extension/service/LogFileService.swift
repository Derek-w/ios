//
//  LogFileService.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Chris O'Malley on 3/10/20.
//  Copyright © 2020 World Surf League. All rights reserved.
//

import CocoaLumberjack
import WatchKit
import RxSwift

class LogFileService {
    
    private var fileLoggerManager : DDLogFileManagerDefault
    private var fileLogger : DDFileLogger
    private var wslPushService: WSLPushService
    private var disposeBag = DisposeBag()
    private let deviceName = WKInterfaceDevice.current().name
    
    init() {
        self.wslPushService = SwinjectUtil.sharedInstance.container.resolve(WSLPushService.self)!
        
        //Configure Filelogger with Max File size 1 MB and a rolling frequency of 10 Minutes
        self.fileLoggerManager = DDLogFileManagerDefault()
        self.fileLogger = DDFileLogger.init(logFileManager: fileLoggerManager)
        self.fileLogger.maximumFileSize  = 1024 * 1000 * 10 // 10 MB
        self.fileLogger.rollingFrequency =   0   //Disabling rolling frequency
        fileLogger.logFileManager.maximumNumberOfLogFiles = 100
        
        DDLog.add(DDOSLogger.sharedInstance)
        DDLog.add(DDTTYLogger.sharedInstance)
        DDLog.add(fileLogger)
    }
    
    func processExistingLogFiles() -> Observable<[Bool]>  {
        let fileManager = FileManager.default
        let logFiles = self.getLogFileInfo()
        let logFileObservables = logFiles.map {(fileName, filePath, fileContents) -> (Observable<Bool>) in
            //Prepend device name to file and get rid of white space in the file name since it will be part of URL path
            return Observable<Bool>.create { (observer) -> Disposable in
                let fullFileName = "\(self.deviceName)-\(fileName)".replacingOccurrences(of: " ", with: "")
                return self.wslPushService.uploadLogFiles(fullFileName, fileContents: fileContents).subscribe { event in
                    if let apiError = event.error {
                        DDLogError("sendLogFiles api error: \(apiError.localizedDescription)")
                        observer.onError(apiError)
                    } else if event.isCompleted {
                        DDLogInfo("Success")
                        do {
                            try fileManager.removeItem(atPath: filePath)
                            print("Successfully deleted \(filePath)")
                        } catch {
                            print("Unable to delete \(filePath)")
                        }
                        observer.onNext(true)
                        observer.onCompleted()
                    }
                }
            }
        }
        return Observable.zip(logFileObservables)
    }
        
    /**
        Returns log files as an array of tuples Strings(filename, filepath, filecontents)
     */
    private func getLogFileInfo() -> [(String, String, String)] {
        
        if (self.fileLoggerManager.sortedLogFilePaths.count == 0) {
            return []
        }
                
        return self.fileLoggerManager.sortedLogFilePaths.map { (filePath) -> (String, String, String) in
            do {
                let longFileName = filePath.components(separatedBy: "/").last!
                let shortFileName = longFileName.components(separatedBy: " ").last!
                return try (shortFileName, filePath, String(contentsOfFile: filePath, encoding: .utf8))
            } catch {
                return (filePath, filePath, "")
            }
        }
    
    }
    
}
