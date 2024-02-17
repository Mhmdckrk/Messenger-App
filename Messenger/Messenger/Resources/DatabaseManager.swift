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

extension DatabaseManager {
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedtoFetch))
                return }
            completion(.success(value))
            
        }
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
    public func createNewConversation(with otherUserEmail: String, receiverName: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String
        else { return }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
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
                "receiver_name": receiverName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
                
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email":safeEmail,
                "receiver_name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
                
            ]
            
            
            // Update recipient conversation entry
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else {
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            
            // Update current user conversation entry
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
                    self?.finishCreatingConversation(conversationId: conversationId, firstMessage: firstMessage, receiverName: receiverName, completion: completion)
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
                    self?.finishCreatingConversation(conversationId: conversationId, firstMessage: firstMessage, receiverName: receiverName, completion: completion)
                }
            }
        }
        
    }
    
    private func finishCreatingConversation(conversationId: String, firstMessage: Message, receiverName: String, completion: @escaping (Bool) -> Void) {
        
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
            "receiver_name": receiverName,
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
    public func getAllConversations(for email: String, completion: @escaping(Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedtoFetch))
                return
            }
            
            //            print(value)
            
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool,
                      let message = latestMessage["message"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let receiverName = dictionary["receiver_name"] as? String
                else {
                    return nil
                }
                
                
                let latestMessageObject = LatestMessage(date: date, message: message, isRead: isRead)
                let result = Conversation(id: conversationId, reciverName: receiverName, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
                return result
            }
            completion(.success(conversations))
        }
        
    }
    
    /// Gets all message for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedtoFetch))
                return
            }
            
            //            print(value)
            
            let messages: [Message] = value.compactMap { dictionary in
                guard let content = dictionary["content"] as? String,
                      let id = dictionary["id"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let type = dictionary["type"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let receiverName = dictionary["receiver_name"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else { return nil }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: receiverName)
                
                let result = Message(sender: sender, messageId: id, sentDate: date, kind: .text(content))
                return result
            }
            completion(.success(messages))
        }
        
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversationId: String, otherUserEmail: String, receiverName: String, message: Message, completion: @escaping (Bool) -> Void) {
        // add new message to messages
        // update latest sender message
        // update latest recipient latest message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else { completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        database.child("\(conversationId)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            var messages = ""
            
            let messageDate = message.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            
            switch message.kind {
                
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
            
            let newMessageEntry: [String: Any] = [
                
                "id": message.messageId,
                "type": message.kind.messageKindString,
                "content": messages,
                "receiver_name": receiverName,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false
                
            ]
            
            currentMessages.append(newMessageEntry)
            self.database.child("\(conversationId)/messages").setValue(currentMessages) { (error,_ ) in
                guard error == nil else {
                    completion(false)
                    return }
                
                self.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": messages
                    ]
                    
                    var targetConversation: [String: Any]?
                    
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversationId {
                            targetConversation = conversationDictionary
                            break
                        }
                        
                        position += 1
                        
                    }
                    
                    targetConversation?["latest_message"] = updatedValue
                    
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return }
                    currentUserConversations[position] = finalConversation
                    self.database.child("\(currentEmail)/conversations").setValue(currentUserConversations) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return }
                        
                        
                        // update receiver latest message
                        
                        self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot  in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                     
                            //
                            
                            let updatedValue: [String: Any] = [
                                "date":dateString,
                                "is_read": false,
                                "message": messages
                            ]
                            
                            var targetConversation: [String: Any]?
                            
                            var position = 0
                            
                            for conversationDictionary in otherUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversationId {
                                    targetConversation = conversationDictionary
                                    break
                                }
                                
                                position += 1
                                
                            }
                            
                            targetConversation?["latest_message"] = updatedValue
                            
                            guard let finalConversation = targetConversation else {
                                completion(false)
                                return }
                            otherUserConversations[position] = finalConversation
                            self.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return }
                                
                                completion(true)
                            }
                            
                        }
                    }
                    
                }
            }
        }
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
