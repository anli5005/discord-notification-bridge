//
//  ContactPicker.swift
//  Discord Notification Bridge
//
//  Created by Anthony Li on 12/25/21.
//

import SwiftUI
import UIKit
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onSelectContact: (CNContact) -> Void
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ContactPicker>) -> UIViewController {
        let controller = UIViewController()
        updateUIViewController(controller, context: context)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<ContactPicker>) {
        if isPresented {
            if let contactPicker = uiViewController.presentedViewController {
                (contactPicker as? CNContactPickerViewController)?.delegate = context.coordinator
            } else {
                let picker = CNContactPickerViewController()
                picker.delegate = context.coordinator
                uiViewController.present(picker, animated: true, completion: nil)
            }
        } else {
            if uiViewController.presentedViewController != nil {
                uiViewController.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onSelectContact(contact)
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.isPresented = false
        }
    }
}
