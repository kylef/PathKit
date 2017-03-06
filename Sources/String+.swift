//
//  String+.swift
//  Hourly
//
//  Created by Jacob Williams on 12/19/16.
//
//

import Foundation

extension String {
    /**
     Checks if a string ends with a specified string
     - Parameter string: The string to test against
     - Returns: A Boolean indicating whether or not the string ends in the specified parameter string
    */
    public func ends(with string: String) -> Bool {
        if string.characters.count > self.characters.count {
            return false
        }
        let ending = self.substring(from: index(self.endIndex, offsetBy: string.characters.count * -1))
        return ending == string
    }

    /**
     Checks if a string starts with a specified string
     - Parameter string: The string to test against
     - Returns: A Boolean indicating whether or not the string starts in the specified parameter string
     */
    public func starts(with string: String) -> Bool {
        if string.characters.count > self.characters.count {
            return false
        }
        let beginning = self.substring(to: index(self.startIndex, offsetBy: string.characters.count))
        return beginning == string
    }
}
