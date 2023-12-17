import UIKit
import FirebaseAuth

class ChangePasswordViewController: UIViewController {

    let currentPasswordTextField = UITextField()
    let newPasswordTextField = UITextField()
    let confirmNewPasswordTextField = UITextField()
    let confirmButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray

        setupTitleLabel()
        setupTextField(currentPasswordTextField, placeholder: "Current Password", topAnchor: view.safeAreaLayoutGuide.topAnchor, constant: 70)
        setupTextField(newPasswordTextField, placeholder: "New Password", topAnchor: currentPasswordTextField.bottomAnchor, constant: 25)
        setupTextField(confirmNewPasswordTextField, placeholder: "Confirm New Password", topAnchor: newPasswordTextField.bottomAnchor, constant: 25)
        setupConfirmButton()
    }

    private func setupTitleLabel() {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Change Password"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupTextField(_ textField: UITextField, placeholder: String, centerYOffset: CGFloat = 0, topAnchor: NSLayoutYAxisAnchor? = nil, constant: CGFloat = 0) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .gray
        container.layer.borderColor = UIColor(red: 52/255, green: 103/255, blue: 235/255, alpha: 1).cgColor
        container.layer.borderWidth = 1
        container.layer.cornerRadius = 20
        view.addSubview(container)

        textField.placeholder = placeholder
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textField)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            textField.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])

        if let topAnchor = topAnchor {
            container.topAnchor.constraint(equalTo: topAnchor, constant: constant).isActive = true
        } else {
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: centerYOffset).isActive = true
        }
    }

    private func setupConfirmButton() {
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.backgroundColor = UIColor(red: 52/255, green: 103/255, blue: 235/255, alpha: 1)
        confirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        confirmButton.layer.cornerRadius = 20
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(confirmButton)
        
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            confirmButton.topAnchor.constraint(equalTo: confirmNewPasswordTextField.bottomAnchor, constant: 25),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func confirmButtonTapped() {
        guard let currentPassword = currentPasswordTextField.text,
              let newPassword = newPasswordTextField.text,
              let confirmNewPassword = confirmNewPasswordTextField.text,
              !currentPassword.isEmpty,
              !newPassword.isEmpty,
              !confirmNewPassword.isEmpty else {
            presentAlert("Error", "Please fill in all the fields")
            return
        }

        if !String.isPasswordValid(newPassword) {
            presentAlert("Invalid password", "Password must be at least 8 characters long, include a lowercase letter, and a special character.")
            return
        }

        if newPassword != confirmNewPassword {
            presentAlert("Password Mismatch", "New Password Fields Don't Match")
            return
        }

        guard let user = Auth.auth().currentUser, let email = user.email else {
            presentAlert("Error", "Unable to get user details.")
            return
        }

        // Re-authenticate the user with the current password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                self?.presentAlert("Authentication Failed", "Invalid Current Password")
                return
            }

            
            // Update the password
            user.updatePassword(to: newPassword) { [weak self] error in
                if let error = error {
                    self?.presentAlert("Update Failed", error.localizedDescription)
                } else {
                    self?.presentAlert("Success", "Password updated successfully") { [weak self] in
                        self?.dismiss(animated: true, completion: nil)
                    }
                }
            }

        }
    }



    private func presentAlert(_ title: String, _ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }

}

extension String {
    static func isPasswordValid(_ password: String) -> Bool {
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }
}

