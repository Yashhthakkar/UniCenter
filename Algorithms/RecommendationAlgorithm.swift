//  RecommendationAlgorithm.swift
//
//  Created by Yash Thakkar on 8/17/23.
//

import Foundation
import Firebase
import FirebaseFirestore


class RecommendationAlgorithm {
    
    // User Profile structure

    struct UserProfile: Hashable {
        var bio: String
        var categories: [String]
        var dietPreference: String
        var searchHistory: [String]
        var dob: Date
        var firstname: String
        var fitnessLevel: String
        var gender: String
        var lastname: String
        var profilePictureURL: String
        var race: String
        var religion: String
        var uid: String
        var year: Int
        
        init?(dictionary: [String: Any]) {
            guard let uid = dictionary["uid"] as? String,
                  let firstname = dictionary["firstname"] as? String,
                  let lastname = dictionary["lastname"] as? String else {
                return nil
            }
            
            self.uid = uid
            self.firstname = firstname
            self.lastname = lastname
            self.bio = dictionary["bio"] as? String ?? ""
            self.dietPreference = dictionary["dietPreference"] as? String ?? ""
            self.fitnessLevel = dictionary["fitnessLevel"] as? String ?? ""
            self.searchHistory = dictionary["searchHistory"] as? [String] ?? []
            self.gender = dictionary["gender"] as? String ?? ""
            self.profilePictureURL = dictionary["profilePictureURL"] as? String ?? ""
            self.race = dictionary["race"] as? String ?? ""
            self.religion = dictionary["religion"] as? String ?? ""
            self.year = dictionary["year"] as? Int ?? 0
            
            if let dobTimestamp = dictionary["dob"] as? Timestamp {
                self.dob = dobTimestamp.dateValue()
            } else {
                self.dob = Date()
            }
            
            if let categories = dictionary["categories"] as? [String] {
                self.categories = categories
            } else {
                self.categories = []
            }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(uid)
        }

        static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
            return lhs.uid == rhs.uid
        }
    }

    
    struct Post {
        var imagePostURL: String
        var postTime: Date
        var uid: String
        
        init?(dictionary: [String: Any]) {
            guard let imagePostURL = dictionary["imagePostURL"] as? String,
                  let uid = dictionary["uid"] as? String else {
                return nil
            }
            
            if let postTimestamp = dictionary["postTime"] as? Timestamp {
                self.postTime = postTimestamp.dateValue()
            } else {
                return nil
            }
            
            self.imagePostURL = imagePostURL
            self.uid = uid
        }
    }

    
    let db = Firestore.firestore()
    
    func fetchAllUsers(completion: @escaping ([UserProfile]) -> Void) {
        db.collection("users").getDocuments { (snapshot, error) in
            if let error = error {
                completion([])
                return
            }
            
            if let snapshotDocuments = snapshot?.documents, !snapshotDocuments.isEmpty {
                print("Successfully fetched \(snapshotDocuments.count) users.")
            } else {
                print("No users found or empty collection.")
            }
            
            var users: [UserProfile] = []
            
            for document in snapshot!.documents {
                if let user = UserProfile(dictionary: document.data()) {
                    print("[fetchAllUsers] Fetched user: \(user.uid)")
                    users.append(user)
                } else {
                    print("[fetchAllUsers] Failed to initialize UserProfile object from: \(document.data())")
                }
            }

            
            completion(users)
        }
    }
    
    func fetchLatestPostsForUser(_ uid: String, completion: @escaping ([Post]) -> Void) {
        let oneHundredTwentyDaysAgo = Calendar.current.date(byAdding: .day, value: -120, to: Date())!
        
        db.collection("posts").whereField("uid", isEqualTo: uid)
            .whereField("postTime", isGreaterThan: Timestamp(date: oneHundredTwentyDaysAgo))
            .order(by: "postTime", descending: true)
            .limit(to: 5)
            .getDocuments { (snapshot, error) in
                
                if let error = error {
                    print("[Debug] Error fetching posts for user \(uid): \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                if let snapshotDocuments = snapshot?.documents, !snapshotDocuments.isEmpty {
                    print("[Debug] Successfully fetched \(snapshotDocuments.count) posts for \(uid).")
                } else {
                    print("[Debug] No posts found or empty collection for \(uid).")
                }
                
                var posts: [Post] = []
                
                for document in snapshot!.documents {
                    if let post = Post(dictionary: document.data()) {
                        print("[fetchLatestPostsForUser] Fetched post for user \(uid): \(post.imagePostURL)")
                        posts.append(post)
                    } else {
                        print("[fetchLatestPostsForUser] Failed to initialize Post object from: \(document.data())")
                    }
                }
                
                completion(posts)
            }
    }


    
    func updateUserCategories(_ user: UserProfile) {
        let newCategories = categorizeUserBasedOnBio(user)
        
        let usersRef = Firestore.firestore().collection("users")
        
        usersRef.whereField("uid", isEqualTo: user.uid).getDocuments { (snapshot, err) in
            if let err = err {
                print("[Category Update] Error fetching document for user \(user.uid): \(err)")
            } else {
                for document in snapshot!.documents {
                    let docID = document.documentID
                    let existingCategories = document.get("categories") as? [String] ?? []
                    
                    let combinedCategories = Array(Set(existingCategories).union(Set(newCategories)))
                    
                    usersRef.document(docID).updateData([
                        "categories": combinedCategories
                    ]) { err in
                        if let err = err {
                            print("[Category Update] Error updating categories for user \(user.uid): \(err)")
                        } else {
                            print("[Category Update] Successfully updated categories for user \(user.uid)")
                        }
                    }
                }
            }
        }
    }
    
    func categorizeUserBasedOnBio(_ user: UserProfile) -> [String] {
        let bioText = user.bio.lowercased()
        
        var categories: [String] = []
        
        let sportsKeywords = ["soccer", "basketball", "football", "sports"]
        let techKeywords = ["coding", "programmer", "tech", "developer"]
        let foodKeywords = ["foodie", "cooking", "chef", "bake"]
        let schoolKeywords = ["studying"]
        
        if sportsKeywords.contains(where: bioText.contains) {
            categories.append("Sports")
        }
        
        if techKeywords.contains(where: bioText.contains) {
            categories.append("Technology")
        }
        
        if foodKeywords.contains(where: bioText.contains) {
            categories.append("Food")
        }
        
        if schoolKeywords.contains(where: bioText.contains) {
            categories.append("School")
        }
        
        return categories
    }
    
    
    func vectorizeUserProfile(_ user: UserProfile) -> [Double] {
        var vector: [Double] = []
        
        // Gender: Male = 0, Female = 1, Other = 2
        switch user.gender {
        case "Male": vector.append(0)
        case "Female": vector.append(1)
        default: vector.append(2)
        }
        
        // Fitness Level: Not Active = 0, Slightly Active = 1, Active = 2, Very Active = 3
        switch user.fitnessLevel {
        case "Not Active": vector.append(0)
        case "Slightly Active": vector.append(1)
        case "Active": vector.append(2)
        default: vector.append(3)
        }
        
        let raceMapping: [String: Double] = [
            "Hispanic/Latino": 0,
            "American Indian/Alaskan Native": 1,
            "Asian": 2,
            "African-American": 3,
            "Native Hawaiian/Pacific Islander": 4,
            "White": 5
        ]
        vector.append(raceMapping[user.race] ?? 6)  // 6 for Other
        
        let religionMapping: [String: Double] = [
            "Christian": 0,
            "Jewish": 1,
            "Hindu": 2,
            "Muslim": 3,
            "Sikh": 4,
            "Atheist": 5,
            "Other": 6
        ]
        vector.append(religionMapping[user.religion] ?? 7)  // 7 for Other
        
        let yearMapping: [Int: Double] = [
            1: 0, // Freshman
            2: 1, // Sophomore
            3: 2, // Junior
            4: 3  // Senior
        ]
        vector.append(yearMapping[user.year] ?? 4)
        
        let dietMapping: [String: Double] = [
            "non-vegetarian": 0,
            "vegetarian": 1,
            "vegan": 2,
            "Pescatarian": 3,
            "Halal": 4,
            "Kosher": 5
        ]
        vector.append(dietMapping[user.dietPreference] ?? 6)  // 6 for Other
        
        let allCategories = ["Sports", "Technology", "Food", "School"]
        let categoriesVector = allCategories.map { user.categories.contains($0) ? 1.0 : 0.0 }
        vector.append(contentsOf: categoriesVector)
        

        if user.bio.contains("sports") {
            vector.append(1)
        } else {
            vector.append(0)
        }
        
        return vector
    }

    
    
    
    func cosineSimilarity(vecA: [Double], vecB: [Double]) -> Double {
        var dotProduct = 0.0
        var normA = 0.0
        var normB = 0.0
        for i in 0..<vecA.count {
            dotProduct += vecA[i] * vecB[i]
            normA += pow(vecA[i], 2)
            normB += pow(vecB[i], 2)
        }
        let similarity = dotProduct / (sqrt(normA) * sqrt(normB))
        return similarity
    }
    
    func recommendProfiles(for user: UserProfile, from allUsers: [UserProfile]) -> [UserProfile] {
        var recommendations: [(user: UserProfile, similarity: Double)] = []
        
        let userVector = vectorizeUserProfile(user)
        
        for otherUser in allUsers {
            if user.uid == otherUser.uid || user.searchHistory.contains(otherUser.uid) {
                continue // Skip the current user and any user in the search history
            }
            let otherUserVector = vectorizeUserProfile(otherUser)
            let similarity = cosineSimilarity(vecA: userVector, vecB: otherUserVector)
            if similarity > 0.5 { // Assuming 0.5 is our threshold for similarity
                recommendations.append((user: otherUser, similarity: similarity))
            }
        }
        
        recommendations.sort { $0.similarity > $1.similarity }
        
        // Filter out users with similarity below the threshold
        let recommendedUsers = recommendations.filter { $0.similarity > 0.5 }.map { $0.user }
        
        
        return recommendedUsers
    }

    
    // Fetch latest 7-10 posts for a given user and recommend them
    func recommendPostsForUser(_ uid: String, completion: @escaping ([Post]) -> Void) {
            let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
            db.collection("posts").whereField("uid", isEqualTo: uid)
                .order(by: "postTime", descending: true)
                .limit(to: 5)
                .getDocuments { (snapshot, error) in
                    var posts: [Post] = []
                    
                    if let error = error {
                        completion([])
                        return
                    }
                    
                    for document in snapshot!.documents {
                        if let post = Post(dictionary: document.data()) {
                            posts.append(post)
                        }
                    }
                    
                    if posts.count < 7 {
                        completion(posts)
                    } else {
                        posts.shuffle()
                        let range = min(posts.count, 10)
                        let recommendedPosts = Array(posts.prefix(range))
                        completion(recommendedPosts)
                    }
                }
        }
    
    func fetchAndRecommendPosts(for recommendedUsers: [UserProfile]) {
            for user in recommendedUsers {
                print("[fetchAndRecommendPosts] Fetching posts for user: \(user.uid)")
                recommendPostsForUser(user.uid) { recommendedPosts in
                    print("[fetchAndRecommendPosts] Recommended posts for user \(user.uid): \(recommendedPosts.map { $0.imagePostURL })")
                }
            }
        }
    }
