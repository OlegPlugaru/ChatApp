//
//  ViewController.swift
//  ChatApp
//
//  Created by Oleg Plugaru on 03.08.2024.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
   
    
    
    @IBOutlet weak var docViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    let db = Firestore.firestore()
    var messagesArray: [String] = [String]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.messageTableView.delegate = self
        self.messageTableView.dataSource = self
        
        // Set self as the delegate for the textfield
        self.messageTextField.delegate = self
        
        // Add a tap gesture recognizer to the textfield
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tableViewTapped))
        self.messageTableView.addGestureRecognizer(tapGesture)
        
        // Retrieve messages from Firestore
        self.retrieveMessages()
    }
    
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        Task { @MainActor in
            // Send button is tapped
            
            // Call the end editing method for the text field
            self.messageTextField.endEditing(true)
            
            // Disable the send button and textfield
            self.messageTextField.isEnabled = false
            self.sendButton.isEnabled = false
            
            do {
                let ref = try await db.collection("Message").addDocument(data: [
                    "text": self.messageTextField.text ?? "",
                    "timestamp": Date()
                   
                    
                ])
                self.retrieveMessages()
                print("Document added with ID: \(ref.documentID)")
            } catch {
                print("Error adding document: \(error)")
            }
            
            // Enable the textfield and send button
            self.sendButton.isEnabled = true
            self.messageTextField.isEnabled = true
            self.messageTextField.text = ""
            
        }
    }
    
    func retrieveMessages() {
        db.collection("Message").order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            
            self.messagesArray = documents.map { $0["text"] as? String ?? "" }
            self.messageTableView.reloadData()
        }
    }
    
    @objc func tableViewTapped() {
     
        // Force the textfield to end editing
        self.messageTextField.endEditing(true)
        
    }
    
    // MARK: TextField Delegate Methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        // Perform an animation to grow the dockview
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, animations: {
            
            self.docViewHeightConstraint.constant = 360
            self.view.layoutIfNeeded()
           
        })
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Perfom an animation to grow the dockview
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5) {
            self.docViewHeightConstraint.constant = 60
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: TableView Delegate Methods
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.messageTableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        cell.textLabel?.text = messagesArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArray.count
    }
}

