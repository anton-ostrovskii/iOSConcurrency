/**
 A playground showcasing different concurrency technics in iOS programming.
 */

import UIKit
import Foundation
import os
import Combine
import SwiftUI

/// Run async code on a main thread
func runAsyncCodeOnMainThread() {
  DispatchQueue.main.async {
    print("On a main thread")
  }
}

/// Run async code on a background thread
func runAsyncCodeOnBackgroundThread() {
  DispatchQueue.global(qos: .background).async {
    let _ = 100 * 100
  }
}

/**
 DispatchQueue is an object that manages the execution of tasks serially or concurrently on your app’s main thread or on a background thread.
 
 QoS (Quality of Service):
1. background — we can use this when a task is not time-sensitive or when the user can do some other interaction while this is happening. Like pre-fetching some images, loading, or processing some data in this background. This work takes significant time, seconds, minutes, and hours.
2. utility — long-running task. Some process what the user can see. For example, downloading some maps with indicators. When a task takes a couple of seconds and eventually a couple of minutes.
3. userInitiated — when the user starts some task from UI and waits for the result to continue interacting with the app. This task takes a couple of seconds or an instant.
4. userInteractive — when a user needs some task to be finished immediately to be able to proceed to the next interaction with the app. Instant task.
 */

/// Serial queue sample
func serialQueueSample() {
  let serialQueue = DispatchQueue(label: "serialQueueSample")
  serialQueue.async {
    print("serialQueueSample - 1")
  }
  serialQueue.async {
    sleep(1)
    print("serialQueueSample - 2")
  }
  serialQueue.sync {
    print("serialQueueSample - 3")
  }
  serialQueue.sync {
    print("serialQueueSample - 4")
  }
}
//serialQueueSample - 1
//serialQueueSample - 2
//serialQueueSample - 3
//serialQueueSample - 4

/// Concurrent queue sample
func concurrentQueueSample() {
  let concurrentQueue = DispatchQueue(label: "concurrentQueueSample", attributes: .concurrent)
  concurrentQueue.async {
    print("concurrentQueueSample - 1")
  }
  concurrentQueue.async {
    sleep(2)
    print("concurrentQueueSample - 2")
  }
  concurrentQueue.async {
    sleep(1)
    print("concurrentQueueSample - 3")
  }
  concurrentQueue.async {
    print("concurrentQueueSample - 4")
  }
} 
//concurrentQueueSample - 1
//concurrentQueueSample - 4
//concurrentQueueSample - 3
//concurrentQueueSample - 2

/**
 DispatchGroup - a group of tasks that you monitor as a single unit.
 */

/// DispatchGroup sample
func dispatchGroupSample() {
  func longTaskWithCompletion(_ completion: @escaping () -> ()) {
    DispatchQueue.global().async {
      sleep(UInt32.random(in: 1...3))
      completion()
    }
  }

  let group = DispatchGroup()

  group.enter()
  longTaskWithCompletion {
    print("dispatchGroupSample - 1")
    group.leave()
  }

  group.enter()
  longTaskWithCompletion {
    print("dispatchGroupSample - 2")
    group.leave()
  }

  print("dispatchGroupSample - pre-notify")
  let queue = DispatchQueue.global(qos: .userInitiated)
  group.notify(queue: queue) {
    print("dispatchGroupSample - notify")
  }
  print("dispatchGroupSample - post-notify")
}
//dispatchGroupSample - pre-notify
//dispatchGroupSample - post-notify
//dispatchGroupSample - 2
//dispatchGroupSample - 1
//dispatchGroupSample - notify

/**
 DispatchSemaphore - an object that controls access to a resource across multiple execution contexts through use of a traditional counting semaphore.
    - Call wait() every time accessing some shared resource.
    - Call signal() when we are ready to release the shared resource.
    - The value in DispatchSemaphore indicates the number of concurrent tasks.
 */
func dispatchSemaphoreSample() {
  let semaphore = DispatchSemaphore(value: 1)
  semaphore.wait()
  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    semaphore.signal()
  }
}

/**
 DispatchWorkItem - the work you want to perform, encapsulated in a way that lets you attach a completion handle or execution dependencies.
 
 For example - cancel search backend request if user typed a next symbol too fast
 */
func dispatchWorkItemSample() {
  class SearchManager {
    var workItem: DispatchWorkItem?
    
    func search(_ text: String) {
      workItem?.cancel()
      
      let networkItem = DispatchWorkItem {
        print("Making a backend call to search API")
      }
      
      self.workItem = networkItem
      DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(300), execute: networkItem)
    }
  }
}

/**
 Dispatch Barrier - resolving the problem with a read/write lock. This makes sure that only this DispatchWorkItem will be executed.
 */
func dispatchBarrierSample() {
  let concurrentQueue = DispatchQueue(label: "dispatchBarrierSample", attributes: .concurrent)
  
  for a in 1...3 {
    concurrentQueue.async {
      print("dispatchBarrierSample - async - \(a)")
    }
  }
  for b in 4...6 {
    concurrentQueue.async(flags: .barrier) {
      print("dispatchBarrierSample - barrier - \(b)") /// only 1 dispatch block item executed at a time
    }
  }
  for c in 7...10 {
    concurrentQueue.sync {
      print("dispatchBarrierSample - sync - \(c)")
    }
  }
}
//dispatchBarrierSample - async - 2
//dispatchBarrierSample - async - 1
//dispatchBarrierSample - async - 3
//dispatchBarrierSample - barrier - 4
//dispatchBarrierSample - barrier - 5
//dispatchBarrierSample - barrier - 6
//dispatchBarrierSample - sync - 7
//dispatchBarrierSample - sync - 8
//dispatchBarrierSample - sync - 9
//dispatchBarrierSample - sync - 10

/// AsyncAfter - delay the execution of a dispatch block
func asyncAfterSample() {
  print("Entered asyncAfterSample")
  DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    print("printed after 2 seconds")
  }
}

/**
 Operation and OperationQueue - built on the top of GCD. Provides more user-friendly interface for Dependencies(executes a task in a specific order), it is Observable (KVO to observe properties), has Pause, Cancel, Resume, and Control (you can specify the number of tasks in a queue).
 */

/// Simple Operation Queue sample
func simpleOperationQueueSample() {
  let queue = OperationQueue()
  queue.addOperation {
    print("Printed from background - 1")
    OperationQueue.main.addOperation {
      print("Printed from main - 1")
    }
  }
  queue.addOperation {
    print("Printed from background - 2")
    OperationQueue.main.addOperation {
      print("Printed from main - 2")
    }
  }
}
//Printed from background - 1
//Printed from background - 2
//Printed from main - 1
//Printed from main - 2

/// Set `maxConcurrentOperationCount` to 1, so the operation queue would work like a serial queue
func serialQueueWithOperationQueueSample() {
  let task1 = BlockOperation {
    print("Task 1")
  }
  let task2 = BlockOperation {
    print("Task 2")
  }
  task1.addDependency(task2)
  let serialOperationQueue = OperationQueue()
  serialOperationQueue.maxConcurrentOperationCount = 1
  serialOperationQueue.addOperations([task1, task2], waitUntilFinished: false)
}
//Task 2
//Task 1

/// Work with OperationQueue like a concurent queue
func concurentOperationQueueSample() {
  let task1 = BlockOperation {
    print("Task 1")
  }
  let task2 = BlockOperation {
    print("Task 2")
  }
  let concurentOperationQueue = OperationQueue()
  concurentOperationQueue.maxConcurrentOperationCount = 2
  concurentOperationQueue.addOperations([task1, task2], waitUntilFinished: false)
}
//Task 1
//Task 2

/// DispatchGroup use case using OperationQueue
func dispatchGroupWithOperationQueueSample() {
  let task1 = BlockOperation {
    print("Task 1")
  }
  let task2 = BlockOperation {
    print("Task 2")
  }
  let combinedTask = BlockOperation {
    print("CombinedTask")
  }
  combinedTask.addDependency(task1)
  combinedTask.addDependency(task2)
  let operationQueue = OperationQueue()
  operationQueue.maxConcurrentOperationCount = 2
  operationQueue.addOperations([task1, task2, combinedTask], waitUntilFinished: false)
}
//Task 1
//Task 2
//CombinedTask

/**
 DispatchSource - used for detecting changes in files and folders.
 */
func dispatchSourceSample() {
  let urlPath = URL(fileURLWithPath: "/PathToYourFile/log.txt")
  do {
      let fileHandle: FileHandle = try FileHandle(forReadingFrom: urlPath)
      let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileHandle.fileDescriptor,
                                                             eventMask: .write, // .all, .rename, .delete ....
                                                             queue: .main) // .global, ...
      source.setEventHandler(handler: {
          print("Event")
      })
      source.resume()
  } catch {
      // Error
  }
}

/**
 Deadlock - situation when two tasks can wait for each other to finish. This is called Deadlock. The task will never be executed and will block the app
 */
func deadLockSample() {
  let serialQueue = DispatchQueue(label: "serialQueueSample")
  serialQueue.sync {
     serialQueue.sync {
        print("Deadlock")
     }
  }
}

/**
 Useful debug commands from a terminal:
 > po Thread.isMainThread
 > po Thread.isMultiThreaded()
 > po Thread.current
 > po Thread.main
 */

/**
 Async / Await - way to run asynchronous code without completion handlers 
 */
struct AsyncAwaitSimpleSample {
  func make() async -> Bool {
    sleep(2)
    return true
  }
  
  func asyncAwaitSample() {
    print("asyncAwaitSample - 1")
    Task {
      let val = await make()
      print("asyncAwaitSample - 2, val is \(val)")
    }
    print("asyncAwaitSample - 3")
  }
}
//asyncAwaitSample - 1
//asyncAwaitSample - 3
//asyncAwaitSample - 2, val is true

/**
 Additional useful functions for tasks:
 > Task.isCancelled
 > Task.init(priority: .background) {}
 > Task.detached(priority: .userInitiated) {}
 > Task.cancel()
 */

/**
 TaskGroup - is similar to DispatchGroup for async/await.
 */
func taskGroupSample() async {
  let string = await withTaskGroup(of: String.self) { group -> String in
    group.addTask { "Hello" }
    group.addTask { "From" }
    group.addTask { "A" }
    group.addTask { "Task" }
    group.addTask { "Group" }

    var collected = [String]()

    for await value in group {
        collected.append(value)
    }

    return collected.joined(separator: " ")
  }

  print(string)
}
//Hello From A Task Group

/// Transforming callbacks to structured concurency
struct CallbacksToStructuredConcurencySample {
  func ofDownloaderOld(from url: URL, completion: @escaping (Result<Data, Error>) -> ()) {
      URLSession.shared.dataTask(with: url) { data, _, error in
          if let data = data {
              completion(.success(data))
          }
          completion(.failure(error!))
      }
  }
  func scDownloaderNew(from url: URL) async -> Result<Data, Error> {
      await withUnsafeContinuation({ continuation in
          ofDownloaderOld(from: url) { result in
              continuation.resume(returning: result)
          }
      })
  }
}

/** @MainActor - the way to tell that some code / properties has to be accessed on a main thread only (like UI) */
actor MainIsolatedActor {
  let syncAccessibleProperty = "Howdy"
  @MainActor var asyncAccessibleProperty: String
  init(_ str: String) {
    asyncAccessibleProperty = str
  }
  @MainActor func changeStringTo(_ str: String) {
    asyncAccessibleProperty = str
  }
}

/** Task yielding - allowing other tasks to run (adding a small pause) */
func tyTaskYielding() {
  Task {
    for i in 0..<Int.max {
      await Task.yield()    // wait a bit at the beginning of a next iteration to let other tasks run
      print(i)
    }
  }
}

/** Cancelling a task. It is a good idea to check in the task if it was cancelled to react accordingly */
func cancellingTaskFSD() throws {
  let cancellingTask = Task {
    for i in 0..<Int.max where !Task.isCancelled {
      try await Task.sleep(nanoseconds: 1)
      print(i)
    }
  }
  Task {
    try await Task.sleep(nanoseconds: 10)
    cancellingTask.cancel()
  }
}

/**
 Actor - classes, reference types that are thread-safe. They handle data race and concurrency issues. As you can see below, accessing the property of the actor is done with await keyword.
 */
actor TemperatureLogger {
  let label: String
  var measurements: [Int]
  private(set) var max: Int

  init(label: String, measurement: Int) {
      self.label = label
      self.measurements = [measurement]
      self.max = measurement
  }
}
//let logger = TemperatureLogger(label: "Outdoors", measurement: 25)
//Task { print(await logger.max) // Access with await }
//25

/** Nonisolated - the way to tell compiler that some function might be called without await (if it doesn't access any internal var properties */
actor niwActor {
    nonisolated func sayHi() -> String { "Hi" } // can be called without await
}

/// Threads - the most low level way to access the multi-threading goals. Could cause leaks, and harder to maintain
class SimpleThreadsSample {
  func craeteThread() {
    let thread = Thread(target: self, selector: #selector(threadFunc), object: nil)
    thread.start()
  }
  
  @objc func threadFunc() {
    print("Thread loop running")
  }
}
/// Thread loop running
