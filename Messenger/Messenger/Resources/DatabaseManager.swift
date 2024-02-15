//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Mahmud CIKRIK on 4.01.2024.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

// MARK: - Account Management

extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
        
    }
    
    /// Inserts new user to data base
    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
            
        ]) { error, _ in
            guard error == nil else {
                print("faild to write to database")
                completion(false)
                return
            }
            
            // ORNEK, Example:
            /*
             
             users => [
             [
             "name": "Mahmud"
             "safe_email": mahmud_gmail_com
             
             ],
             ]
             
             */
            
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // append to user dictionary
                    let newElement: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    usersCollection.append(contentsOf: newElement)
                    
                    self.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            return
                        }
                        
                        completion(true)
                    }
                    
                } else {
                    // create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            return
                        }
                        
                        completion(true)
                    }
                    
                }
            }
        }
    }
    
    public func getAllUsers(completion: @escaping(Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedtoFetch))
                return }
            
            completion(.success(value))
            
        }
        
        
        
    }
    
}

// MARK: - Sending messages / conversations

extension DatabaseManager {
    
    
    /*
     
     "converation_id" [
     "message": [
        "id": String
        "type": text, photo, video
        "content": String,
        "date": Date()
        "sender_email": String,
        "isRead": true/false,
     ]
     ]
     
     conversation => [
    [
     "conversation_id":
     "other_user_email":
     "latest_message": => [
     "date": Date()
     "latest_message": "message"
     "is_read": true/false
     ]
     
     ]
     ]
     
     */
    
    /// creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else { return }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText

            case .attributedText(_):
                break
                
            case .photo(_):
                break
                
            case .video(_):
                break
                
            case .location(_):
                break
                
            case .emoji(_):
                break
                
            case .audio(_):
                break
                
            case .contact(_):
                break
                
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_" + "\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email":otherUserEmail,
                "latest_messsage": [
                    "date": dateString,
                    "message": message,
                    "isRead": false
                ]
                
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                //you should append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("fatal error: \(error)")
                        return
                    }
                   // completion(true): önceden bu vardı.
                    self.finishCreatingConversation(conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                }
            }
            else {
                // conversation array does NOT exist, Create it
                userNode["conversations"] = [
                newConversationData
                ]
                
                ref.setValue(userNode) { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("fatal error: \(error)")
                        return
                    }
                    self.finishCreatingConversation(conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                }
            }
        }
        
    }
                
    private func finishCreatingConversation(conversationId: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
    
//        "id": String
//        "type": text, photo, video
//        "content": String,
//        "date": Date()
//        "sender_email": String,
//        "isRead": true/false,
        
        var messages = ""
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)

        
        switch firstMessage.kind {
            
        case .text(let messageText):
            messages = messageText

        case .attributedText(_):
            break
            
        case .photo(_):
            break
            
        case .video(_):
            break
            
        case .location(_):
            break
            
        case .emoji(_):
            break
            
        case .audio(_):
            break
            
        case .contact(_):
            break
            
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let unsafeEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: unsafeEmail)
        
        let collectionMessage: [String: Any] = [
        
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": messages,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
            
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        
        ]
        
        database.child("\(conversationId)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return }
            
            completion(true)
        }
        
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping(Result<String, Error>) -> Void) {
        
    }
    
    /// Gets all message for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
    
}


public enum DatabaseError: Error {
    case failedtoFetch
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        // Ornek: mahmud-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}
