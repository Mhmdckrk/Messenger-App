//
//  StorageManager.swift
//  Messenger
//
//  Created by Mahmud CIKRIK on 1.02.2024.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    // Direk String eklemiyoruz çünkü upload esnasında sorun olabilir. typealias yaptık çünkü okunabilir olsun diye. escaping yaptık işlem farklı queue da devam etsin diye.
    
    /// Upload picture to firebase and returns completion with url string to Download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion ) {
        
        storage.child("images/\(fileName)").putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                // failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
                
            }
            
        }
        
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        let reference = storage.child(path)
        
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {  completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            // escaping: yani yukarıdaki işlem sırasından kaçıp asenkron oluyor. Sıradan senkronluktan kaçma manasında escaping deniyor.
            completion(.success(url))
            
        }
        
    }
    
}
