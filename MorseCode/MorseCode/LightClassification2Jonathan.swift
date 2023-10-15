//
//  LightClassification2.swift
//  MorseCode
//
//  Created by Jonathan Huang on 10/14/23.
//
// Given a 3D array of binary thresholded values of 1s and 0s, figure out which one is part is flickering, read from that graph, and return a list of 1s and 0s.
import Foundation
import Vision

//output from Max plugs into here, imagine panes of 2D arrays

//
func detectFlicker(in array3D: [[[Int]]]) -> [Int]? {
    
    //makes sure that input is not null
    let depth = array3D.count
    guard depth > 0 else {
        return nil
    }
    
    //GENERAL GOALS:
    // Iterate through entire 2D array and procure time histories (Done through . Have a similarity threshold with surroundings with a cutoff. Ex: given two arrays that represent light history, how similar do they have to be (figured out through testing but can start with like 90% or something.


    // Group similar pixels. Out of y x y pixels, just average 1 and 0 by frame so if there are more 1s, the light source is on and vice versa
    // lightGroupings is a hashmap of all pixels organized into groups
    let lightGroupings = makeModemap(in: array3D)
    
    //Return is disabled for testing
    //return pickLightSource(in: lightGroupings)
    //
    return []
}


func kMeans(in array3D: [[[Int]]]) -> [Int] {
    let depth = array3D.count
    let rows = array3D[0].count
    let cols = array3D[0][0].count
    
    let numCenters = 2
    let maxIterations = 30
    
    var centers = [[Int]]()
    for _ in 0..<numCenters {
        let layer = Int.random(in: 0..<depth)
        let row = Int.random(in: 0..<rows)
        let col = Int.random(in: 0..<cols)
        centers.append([array3D[layer][row][col]])
    }
    
    var prevCenters = [[Int]]()
    var curriterations = 0
    
    while centers != prevCenters && curriterations < maxIterations {
        prevCenters = centers
        var clusters = Array(repeating: [[Int]](), count: numCenters)
        
        for row in 0..<rows {
            for col in 0..<cols {
                var lightHistory = [Int]()
                for layer in 0..<depth {
                    lightHistory.append(array3D[layer][row][col])
                }
                
                var minDistance = Int.max
                var clusterIndex = 0
                
                for (index, center) in centers.enumerated() {
                    let comparedArray = zip(lightHistory, center)
                    let computedArray = comparedArray.map { (a, b) in abs(a - b) }
                    let distance = computedArray.reduce(0, +)
                    
                    if distance < minDistance {
                        minDistance = distance
                        clusterIndex = index
                    }
                }
                
                clusters[clusterIndex].append(lightHistory)
            }
        }
        
        for (index, cluster) in clusters.enumerated() {
            if cluster.isEmpty {
                continue
            }
            var sumLightHistory = [Int](repeating: 0, count: depth)
            for row in cluster {
                sumLightHistory = zip(sumLightHistory, row).map { $0 + $1 }
            }
            
            centers[index] = sumLightHistory.map { $0 / cluster.count }
        }
        
        curriterations += 1
    }
    
    let sortByStdev = centers.sorted { (center1, center2) in
        return stDev(in: center1) > stDev(in: center2)
    }
    
    return organize(in: sortByStdev[0])
}

func stDev(in arr: [Int]) -> Double {
    let mean = Double(arr.reduce(0, +)) / Double(arr.count)
    let squaredDifferences = arr.map { pow(Double($0) - mean, 2.0) }
    let variance = squaredDifferences.reduce(0, +) / Double(arr.count)
    return sqrt(variance)
}

func organize(in arr: [Int]) -> [Int] {
    var new = [Int]()
    let mean = arr.reduce(0, +) / arr.count
    for index in arr {
        if index > mean {
            new.append(1)
        } else {
            new.append(0)
        }
    }
    return new
}








//Take pixel history
//Return array of history arrays, not every pixel gets added
// Heuristic: numOnes/Length.
func makeModemap(in array3D: [[[Int]]]) -> [Int] {
    

    let depth = array3D.count
    let rows = array3D[0].count
    let cols = array3D[0][0].count
        
    var modeMap = [[Int]]()
    
    let minConstant = 0.3 // Is off too often
    let maxConstant = 0.7 // Is on too often
    
    
    for row in 0..<rows {
        for col in 0..<cols {
            var numOnes = 0
            var pixelHistory = [Int]()
            
            for layer in 0..<depth {
                pixelHistory.append(array3D[layer][row][col])
                if array3D[layer][row][col] == 1 {
                    numOnes += 1
                }
            }
            
            let ratio = Double(numOnes)/Double(depth)
            
            if (ratio > minConstant && ratio < maxConstant) {
                modeMap.append(pixelHistory)
            }
            
        }
    }
    let morseCodeArr = getAvg(in: modeMap)
    
    return morseCodeArr
}













//Deprecated Functions

func DEPRECATEDcomparePixels(in arr0: [Int], arr1: [Int]) -> Bool {

    let leniancy = 0.7 //How similar the light histories have to be with each other in order to satisfy grouping
    
    var same = 0.0
    for index in 0..<arr0.count {
        if (arr0[index] == arr1[index]) {
            same += 1.0
        }
    }
    
    let similarity = same / Double(arr0.count)

    return similarity > leniancy
}

// Gets the average of the array of 1D arrays that are grouped by flicker rate (2D array). Returns a 1D array of the avg
func getAvg(in array2D: [[Int]]) -> [Int] {
    let rows = array2D.count
    let cols = array2D[0].count
    
    var avgHistory = [Int]()

    
    for col in 0..<cols {
        var numOnes = 0
        var numZeros = 0
        for row in 0..<rows {
            if (array2D[row][col] == 1) {
                numOnes += 1
            } else {
                numZeros += 1
            }
        }
        if numZeros > numOnes {
            avgHistory.append(0)
        } else {
            avgHistory.append(1)
        }
    }
    
    return avgHistory
}


//Creates groups based off similarity
func DEPRECATEDmakeGroups(in array3D: [[[Int]]]) -> [String : [[[Int]]]] {
    let depth = array3D.count
    let rows = array3D[0].count
    let cols = array3D[0][0].count
    
    // LightGroupings: Key is a 1D light history array (in string format), Value is a 2D array that represents every pixel and their light histories
    var lightGroupings: [String : [[[Int]]]] = [:]
    
    // Iterate through rows and columns
    for row in 0..<rows {
        for col in 0..<cols {
            var lightHistory = [Int]() //int array
            
            // Populate lightHistory with data from array3D
            for layer in 0..<depth {
                lightHistory.append(array3D[layer][row][col])
            }
            let groups = lightGroupings.keys
            var foundGroup = false
            
            // Iterate through the existing groups
            for group in groups {
                // Need to convert string array to array and plug array form into comparePixel
                if DEPRECATEDcomparePixels(in: stringToArr(strArr: group), arr1: lightHistory) {
                    // Group below needs to be an array -> string
                    if var existingValue = lightGroupings[group] {
                        existingValue.append([lightHistory]) //dummy variable just to append to
                        lightGroupings.updateValue(existingValue, forKey: group)
                    }
                    foundGroup = true
                    break
                }
            }
            
            // If no matching group is found, create a new entry
            if !foundGroup {
                //lighthistory below needs to be a string for key and array for value
                lightGroupings[lightHistory.description] = [[lightHistory]]
            }
        }
    }
    
    // Update the keys to be the average of all lightHistories of that group
    var updatedLightGroupings: [String : [[[Int]]]] = [:]
    //lightGroupings below need to be an array
    for (_, value) in lightGroupings {
        let avgKey = getAvg(in: value.flatMap { $0 }) // Flatten the last two dimensions of the 3D array to make it 2D
        // avgKey below has to be a string
        updatedLightGroupings[avgKey.description] = value
    }
    print(updatedLightGroupings.count)
    return updatedLightGroupings
}


// A little bit cheap, but analyze the keys/averages of the groupings and see if there is a pattern of 3 bits and 1 bit for dashes/dots

//Intuition: create a hashmap per key that has key: frequency of occurrances, value: # of contiguous 1s. At the end, sort
// 1) one is arond 3x the difference of the other
// 2) you hit the end and you just take the best you can do

//Deleted pickLightSource

