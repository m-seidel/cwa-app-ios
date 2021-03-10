//
//  DummyContent.swift
//  UITestPlayground
//
//  Created by Carsten Knoblich on 10.03.21.
//

import Foundation
import LoremSwiftum


struct DummyContent {
    let sections: Int
    let rowsPerSection: [Int]

    let content: [Int: [String]]

    init() {
        sections = Int.random(in: 3...10)

        var rows = [Int](repeating: 0, count: sections)
        var content = [Int: [String]]()

        for i in 0..<sections {
            rows[i] = Int.random(in: 5...20)

            // content generation
            var stuff = [String](repeating: "", count: rows[i])
            for j in 0..<rows[i] {
                stuff[j] = Lorem.words(10...50)
            }
            content[i] = stuff
        }

        rowsPerSection = rows
        self.content = content

        print("Sections: \(sections), rows: \(rowsPerSection); total cells: \(rowsPerSection.reduce(0, +))")
    }
}
