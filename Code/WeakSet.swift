//
//  Created by Adam Preble on 2/19/15.
//

import Foundation

/// Weak, unordered collection of objects.
struct WeakSet<T> where T: AnyObject, T: Hashable {
  typealias Element = T

  /// Maps Element hashValues to arrays of Entry objects.
  /// Invalid Entry instances are culled as a side effect of add() and remove()
  /// when they touch an object with the same hashValue.
  fileprivate var contents: [Int: [Entry<Element>]] = [:]

  init(_ objects: T...) {
    self.init(objects)
  }

  init(_ objects: [T]) {
    for object in objects {
      insert(object)
    }
  }

  init(_ objects: Set<T>) {
    for object in objects {
      insert(object)
    }
  }

  /// Add an element to the set.
  mutating func insert(_ newElement: Element) {
    var entriesAtHash = validEntriesAtHash(newElement.hashValue)
    var found = false
    for entry in entriesAtHash {
      if let existingElement = entry.element {
        if existingElement == newElement {
          found = true
          break
        }
      }
    }
    if found {
      return
    }
    let entry = Entry(element: newElement)
    entriesAtHash.append(entry)
    contents[newElement.hashValue] = entriesAtHash
  }

  /// Remove an element from the set.
  mutating func remove(_ removeElement: Element) {
    let entriesAtHash = validEntriesAtHash(removeElement.hashValue)
    let entriesMinusElement = entriesAtHash.filter { $0.element != removeElement }
    if entriesMinusElement.isEmpty {
      contents[removeElement.hashValue] = nil
    }
    else {
      contents[removeElement.hashValue] = entriesMinusElement
    }
  }

  // Does the set contain this element?
  func contains(_ element: Element) -> Bool {
    let entriesAtHash = validEntriesAtHash(element.hashValue)
    for entry in entriesAtHash {
      if entry.element == element {
        return true
      }
    }
    return false
  }

  private func validEntriesAtHash(_ hashValue: Int) -> [Entry<Element>] {
    if let entries = contents[hashValue] {
      return entries.filter {
        $0.element != nil
      }
    }
    else {
      return []
    }
  }
}

private struct Entry<T> where T: AnyObject, T: Hashable {
  typealias Element = T
  weak var element: Element?
}


// MARK: SequenceType

extension WeakSet : Sequence {
  typealias Iterator = AnyIterator<T>

  /// Creates a generator for the items of the set.
  func makeIterator() -> Iterator {
    // This is not straightforward because we need to iterate over the arrays and then their contents.
    var contentsGenerator = contents.values.makeIterator()         // generates arrays of entities
    var entryGenerator = contentsGenerator.next()?.makeIterator()  // generates entries
    return AnyIterator {
      // Note: If entryGenerator is nil, the party is over. No more.
      if let element = entryGenerator?.next()?.element {
        return element
      }
      else { // Ran out of entities in this array. Get the next one, if there is one.
        entryGenerator = contentsGenerator.next()?.makeIterator()
        return entryGenerator?.next()?.element
      }
    }
  }
}
