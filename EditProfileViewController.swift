//  EditProfileViewController.swift

import UIKit
import Firebase
import FirebaseFirestore

class EditProfileViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    var userDocumentId: String?
    
    let firstNameTextField = UITextField()
    let lastNameTextField = UITextField()
    let dobTextField = UITextField()
    let dobPicker = UIDatePicker()
    let genderTextField = UITextField()
    let genderPicker = UIPickerView()
    let bioTextField = UITextField()
    let genderOptions = [" ", "Male", "Female", "Other"]
    
    let dietPreferenceTextField = UITextField()
    let fitnessLevelTextField = UITextField()
    let raceTextField = UITextField()
    let religionTextField = UITextField()
    let yearTextField = UITextField()
    
    let dietPreferencePicker = UIPickerView()
    let fitnessLevelPicker = UIPickerView()
    let racePicker = UIPickerView()
    let religionPicker = UIPickerView()
    let yearPicker = UIPickerView()
    
    let dietPreferenceOptions = [" ", "Non-Vegetarian", "Vegetarian", "Vegan", "Pescatarian", "Halal", "Kosher"]
    let fitnessLevelOptions = [" ", "Not Active", "Slightly Active", "Active", "Very Active"]
    let raceOptions = [" ", "Hispanic/Latino", "American Indian/Alaskan Native", "Asian", "African-American", "Native Hawaiian/Pacific Islander", "White"]
    let religionOptions = ["", "Christian", "Jewish", "Hindu", "Muslim", "Sikh", "Atheist", "Other"]
    let yearOptions = ["", "Freshman", "Sophomore", "Junior", "Senior"]
    
    
    
    let deleteAccountButton = UIButton(type: .system)
    
    let changePasswordButton = UIButton(type: .system)

    
    let segmentedControl = UISegmentedControl(items: ["Public", "Private"])
    
    var horizontalLines = [UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        setUpElements()
        
        // Save Button
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Done", for: .normal)
        saveButton.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        view.addSubview(saveButton)
        
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Fetch User Details
        fetchUserDetails()
        
        // Segmented Control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        // Existing Fields
        /*firstNameTextField.placeholder = "First Name"
        lastNameTextField.placeholder = "Last Name"
        dobTextField.placeholder = "Date of Birth"
        genderTextField.placeholder = "Gender"
        bioTextField.placeholder = "Bio (max 100 characters)"
        
        dietPreferenceTextField.placeholder = "Diet Preference"
        fitnessLevelTextField.placeholder = "Fitness Level"
        raceTextField.placeholder = "Race"
        religionTextField.placeholder = "Religion"
        yearTextField.placeholder = "Year"*/
        
        dobTextField.delegate = self
        genderTextField.delegate = self
        
        // Limit Bio Characters
        bioTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        // Add Fields to View
        view.addSubview(firstNameTextField)
        view.addSubview(lastNameTextField)
        view.addSubview(dobTextField)
        view.addSubview(genderTextField)
        view.addSubview(bioTextField)
        
        view.addSubview(dietPreferenceTextField)
        view.addSubview(fitnessLevelTextField)
        view.addSubview(raceTextField)
        view.addSubview(religionTextField)
        view.addSubview(yearTextField)
        
        setupConstraints()
        
        dobPicker.preferredDatePickerStyle = .inline
        dobPicker.datePickerMode = .date
        dobPicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        dobTextField.inputView = dobPicker
        
        genderPicker.delegate = self
        genderPicker.dataSource = self
        genderTextField.inputView = genderPicker
        
        dietPreferencePicker.delegate = self
        dietPreferencePicker.dataSource = self
        dietPreferenceTextField.inputView = dietPreferencePicker
        
        fitnessLevelPicker.delegate = self
        fitnessLevelPicker.dataSource = self
        fitnessLevelTextField.inputView = fitnessLevelPicker
        
        racePicker.delegate = self
        racePicker.dataSource = self
        raceTextField.inputView = racePicker
        
        religionPicker.delegate = self
        religionPicker.dataSource = self
        religionTextField.inputView = religionPicker
        
        yearPicker.delegate = self
        yearPicker.dataSource = self
        yearTextField.inputView = yearPicker
        
        // Toolbar for dob
        let dobToolBar = UIToolbar()
        dobToolBar.sizeToFit()
        let dobDoneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dobDonePressed))
        dobToolBar.setItems([dobDoneButton], animated: false)
        dobTextField.inputAccessoryView = dobToolBar
        
        // Toolbar for gender
        let genderToolBar = UIToolbar()
        genderToolBar.sizeToFit()
        let genderDoneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(genderDonePressed))
        genderToolBar.setItems([genderDoneButton], animated: false)
        genderTextField.inputAccessoryView = genderToolBar
        
        // New Field Toolbars
        let dietPreferenceToolBar = UIToolbar()
        dietPreferenceToolBar.sizeToFit()
        let dietPreferenceDoneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dietPreferenceDonePressed))
        dietPreferenceToolBar.setItems([dietPreferenceDoneButton], animated: false)
        dietPreferenceTextField.inputAccessoryView = dietPreferenceToolBar
        
        let fitnessLevelToolBar = UIToolbar()
        fitnessLevelToolBar.sizeToFit()
        let fitnessLevelDoneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(fitnessLevelDonePressed))
        fitnessLevelToolBar.setItems([fitnessLevelDoneButton], animated: false)
        fitnessLevelTextField.inputAccessoryView = fitnessLevelToolBar
        
        let raceToolBar = UIToolbar()
        raceToolBar.sizeToFit()
        let raceDoneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(raceDonePressed))
        raceToolBar.setItems([raceDoneButton], animated: false)
        raceTextField.inputAccessoryView = raceToolBar
        
        let religionToolBar = UIToolbar()
        religionToolBar.sizeToFit()
        let religionDoneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(religionDonePressed))
        religionToolBar.setItems([religionDoneButton], animated: false)
        religionTextField.inputAccessoryView = religionToolBar
        
        let yearToolBar = UIToolbar()
        yearToolBar.sizeToFit()
        let yearDoneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(yearDonePressed))
        yearToolBar.setItems([yearDoneButton], animated: false)
        yearTextField.inputAccessoryView = yearToolBar
        
        
        deleteAccountButton.setTitle("Delete Account", for: .normal)
        deleteAccountButton.setTitleColor(.black, for: .normal)
        deleteAccountButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        deleteAccountButton.backgroundColor = .red
        deleteAccountButton.layer.cornerRadius = 20
        deleteAccountButton.addTarget(self, action: #selector(deleteAccountButtonTapped), for: .touchUpInside)
        view.addSubview(deleteAccountButton)
        
        
        setupChangePasswordButton()
        
        
        addHorizontalLine(to: view, below: firstNameTextField)
        addHorizontalLine(to: view, below: lastNameTextField)
        addHorizontalLine(to: view, below: dobTextField)
        addHorizontalLine(to: view, below: genderTextField)
        addHorizontalLine(to: view, below: bioTextField)
        
        addHorizontalLine(to: view, below: dietPreferenceTextField)
        addHorizontalLine(to: view, below: fitnessLevelTextField)
        addHorizontalLine(to: view, below: raceTextField)
        addHorizontalLine(to: view, below: religionTextField)
        
        
        
        segmentChanged()
    }
    
    
    func setUpElements() {
        styleTextFieldWithCustomColors(firstNameTextField, placeholderText: "First Name")
        styleTextFieldWithCustomColors(lastNameTextField, placeholderText: "Last Name")
        styleTextFieldWithCustomColors(dobTextField, placeholderText: "Date of Birth")
        styleTextFieldWithCustomColors(genderTextField, placeholderText: "Gender")
        styleTextFieldWithCustomColors(bioTextField, placeholderText: "Bio (max 100 characters)")
        styleTextFieldWithCustomColors(dietPreferenceTextField, placeholderText: "Diet Preference")
        styleTextFieldWithCustomColors(fitnessLevelTextField, placeholderText: "Fitness Level")
        styleTextFieldWithCustomColors(raceTextField, placeholderText: "Race")
        styleTextFieldWithCustomColors(religionTextField, placeholderText: "Religion")
        styleTextFieldWithCustomColors(yearTextField, placeholderText: "Year")
        
        
        let boldFont = UIFont.boldSystemFont(ofSize: 16)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.gray,
            .font: boldFont
        ]

        segmentedControl.setTitleTextAttributes(textAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(textAttributes, for: .selected)

        segmentedControl.layer.borderWidth = 1.0
        segmentedControl.layer.borderColor = UIColor.gray.cgColor
        segmentedControl.layer.cornerRadius = 4.0
        segmentedControl.clipsToBounds = true
    }

    
    func styleTextFieldWithCustomColors(_ textField: UITextField, placeholderText: String) {
        textField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        textField.textColor = UIColor.white
    }

    
    
    func addTitleLabel(text: String) -> UILabel {
        let titleLabel = UILabel()
        titleLabel.text = text
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .black
        titleLabel.backgroundColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        return titleLabel
    }

    
    
    func addHorizontalLine(to view: UIView, below textField: UITextField) {
        let lineView = UIView()
        lineView.backgroundColor = .white
        view.addSubview(lineView)
        
        lineView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 4),
            lineView.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            lineView.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            lineView.heightAnchor.constraint(equalToConstant: 1)
        ])
        horizontalLines.append(lineView)
    }

    
    // Helper method to hide the horizontal lines
    func hideLines() {
        for line in horizontalLines {
            line.isHidden = true
        }
    }

    // Helper method to show the horizontal lines
    func showLines() {
        for line in horizontalLines {
            line.isHidden = false
        }
    }
    
    
    
    
    private func setupChangePasswordButton() {
        changePasswordButton.setTitle("Change Password", for: .normal)
        changePasswordButton.setTitleColor(.white, for: .normal)
        changePasswordButton.backgroundColor = UIColor(red: 52/255, green: 103/255, blue: 235/255, alpha: 1)
        changePasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        changePasswordButton.layer.cornerRadius = 20
        changePasswordButton.addTarget(self, action: #selector(changePasswordButtonTapped), for: .touchUpInside)
        view.addSubview(changePasswordButton)

        setupChangePasswordButtonConstraints()
    }
    
    @objc private func changePasswordButtonTapped() {
        let changePasswordVC = ChangePasswordViewController()
        changePasswordVC.modalPresentationStyle = .popover // or .overFullScreen for transparency
        self.present(changePasswordVC, animated: true, completion: nil)
    }

    private func setupChangePasswordButtonConstraints() {
        changePasswordButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            changePasswordButton.bottomAnchor.constraint(equalTo: deleteAccountButton.topAnchor, constant: -30),
            changePasswordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            changePasswordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            changePasswordButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    
    
    
    
    
    func deleteUserDataAndPosts(uid: String) {
        print("Starting deletion process for user: \(uid)")
        let db = Firestore.firestore()

        db.collection("posts").whereField("uid", isEqualTo: uid).getDocuments { [weak self] (querySnapshot, error) in
            if let error = error {
                print("Error fetching user posts: \(error.localizedDescription)")
                return
            }

            let batch = db.batch()
            for document in querySnapshot?.documents ?? [] {
                print("Deleting post document: \(document.reference.path)")
                batch.deleteDocument(document.reference)
            }

            batch.commit { error in
                if let error = error {
                    print("Error in batch deletion of posts: \(error.localizedDescription)")
                    return
                }
                print("All posts deleted successfully")

                self?.deleteUserDocument(uid: uid)
            }
        }
    }

    func deleteUserDocument(uid: String) {
        let db = Firestore.firestore()

        db.collection("users").whereField("uid", isEqualTo: uid).getDocuments { [weak self] (querySnapshot, error) in
            if let error = error {
                print("Error finding user document: \(error.localizedDescription)")
                return
            }

            guard let document = querySnapshot?.documents.first else {
                print("No user document found with UID: \(uid)")
                return
            }

            print("Found user document with UID: \(uid), attempting to delete")

            document.reference.delete { error in
                if let error = error {
                    print("Error deleting user document: \(error.localizedDescription)")
                    return
                }
                print("User document deleted successfully")
                self?.deleteUserAccount(uid: uid)
            }
        }
    }

    func deleteUserAccount(uid: String) {
        print("Deleting user account for UID: \(uid)")
        let user = Auth.auth().currentUser
        if user?.uid == uid {
            user?.delete { [weak self] error in
                if let error = error {
                    print("Error deleting user account: \(error.localizedDescription)")
                    return
                }
                print("User account deleted successfully")
                DispatchQueue.main.async {
                    self?.redirectToWelcomeVC()
                }
            }
        } else {
            print("Error: Current user UID does not match the UID to be deleted.")
        }
    }
    

    func redirectToWelcomeVC() {
        print("Redirecting to WelcomeViewController")
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
                print("Error: Key window not found")
                return
            }

            if let welcomeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeVC") as? WelcomeViewController {
                let navigationController = UINavigationController(rootViewController: welcomeVC)
                navigationController.modalPresentationStyle = .fullScreen

                window.rootViewController = navigationController
                window.makeKeyAndVisible()

                let alert = UIAlertController(title: "Account Deleted", message: "Your account and data has been deleted from UniCenter.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                navigationController.present(alert, animated: true, completion: nil)
            } else {
                print("Error: Could not instantiate WelcomeVC")
            }
        }
    }


    @objc func deleteAccountButtonTapped() {
        let firstAlertController = UIAlertController(
            title: "Delete Account",
            message: "This action will delete your account, posts, and all associated data. It cannot be reversed.",
            preferredStyle: .alert
        )

        firstAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        firstAlertController.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            self?.presentSecondConfirmationAlert()
        })

        present(firstAlertController, animated: true, completion: nil)
    }

    func presentSecondConfirmationAlert() {
        let secondAlertController = UIAlertController(
            title: "Are you sure?",
            message: "This action cannot be reversed.",
            preferredStyle: .alert
        )

        secondAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        secondAlertController.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            
            if let user = Auth.auth().currentUser {
                self?.deleteUserDataAndPosts(uid: user.uid)
            }
        })

        present(secondAlertController, animated: true, completion: nil)
    }

    
    @objc func segmentChanged() {
        let isPublic = segmentedControl.selectedSegmentIndex == 0
        firstNameTextField.isHidden = !isPublic
        lastNameTextField.isHidden = !isPublic
        dobTextField.isHidden = !isPublic
        genderTextField.isHidden = !isPublic
        bioTextField.isHidden = !isPublic

        dietPreferenceTextField.isHidden = !isPublic
        fitnessLevelTextField.isHidden = !isPublic
        raceTextField.isHidden = !isPublic
        religionTextField.isHidden = !isPublic
        yearTextField.isHidden = !isPublic

        if isPublic {
            showLines()
        } else {
            hideLines()
        }

        let buttonY = 5 * view.frame.height / 6 - deleteAccountButton.frame.height / 2
        
        deleteAccountButton.frame = CGRect(x: 30, y: buttonY, width: view.frame.width - 60, height: 40)
        
        changePasswordButton.isHidden = isPublic
        deleteAccountButton.isHidden = isPublic
    }


    
    @objc func dateChanged() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        dobTextField.text = formatter.string(from: dobPicker.date)
    }
    
    @objc func dobDonePressed() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        dobTextField.text = formatter.string(from: dobPicker.date)
        view.endEditing(true)
    }
    
    @objc func genderDonePressed() {
        let selectedRow = genderPicker.selectedRow(inComponent: 0)
        genderTextField.text = selectedRow == 0 ? "" : genderOptions[selectedRow]
        view.endEditing(true)
    }

    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, text.count > 100 {
            textField.text = String(text.prefix(100))
        }
    }
    
    @objc func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid,
              let documentId = userDocumentId else {
            print("Error: No UID or document ID found.")
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(documentId)

        var updateData: [String: Any] = [:]

        if let newFirstName = firstNameTextField.text {
            updateData["firstname"] = newFirstName
        }

        if let newLastName = lastNameTextField.text {
            updateData["lastname"] = newLastName
        }
        
        updateData["dob"] = Timestamp(date: dobPicker.date)

        if let newGender = genderTextField.text {
            updateData["gender"] = newGender
        }
        
        if let newBio = bioTextField.text {
            updateData["bio"] = newBio
        }
        
        if let newDietPreference = dietPreferenceTextField.text {
            updateData["dietPreference"] = newDietPreference
        }
        
        if let newFitnessLevel = fitnessLevelTextField.text {
            updateData["fitnessLevel"] = newFitnessLevel
        }
        
        if let newRace = raceTextField.text {
            updateData["race"] = newRace
        }
        
        if let newReligion = religionTextField.text {
            updateData["religion"] = newReligion
        }
        
        if let newYear = yearTextField.text {
            updateData["year"] = newYear
        }

        updateData["uid"] = uid

        userRef.updateData(updateData) { [weak self] error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Profile successfully updated!")

                let recommendationAlgorithm = RecommendationAlgorithm()

                if let updatedUserProfile = RecommendationAlgorithm.UserProfile(dictionary: updateData) {
                    recommendationAlgorithm.updateUserCategories(updatedUserProfile)
                }

                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func setupConstraints() {
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        firstNameTextField.translatesAutoresizingMaskIntoConstraints = false
        lastNameTextField.translatesAutoresizingMaskIntoConstraints = false
        dobTextField.translatesAutoresizingMaskIntoConstraints = false
        genderTextField.translatesAutoresizingMaskIntoConstraints = false
        bioTextField.translatesAutoresizingMaskIntoConstraints = false
        
        dietPreferenceTextField.translatesAutoresizingMaskIntoConstraints = false
        fitnessLevelTextField.translatesAutoresizingMaskIntoConstraints = false
        raceTextField.translatesAutoresizingMaskIntoConstraints = false
        religionTextField.translatesAutoresizingMaskIntoConstraints = false
        yearTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 96),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -96),
            
            firstNameTextField.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            firstNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            firstNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            lastNameTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 16),
            lastNameTextField.leadingAnchor.constraint(equalTo: firstNameTextField.leadingAnchor),
            lastNameTextField.trailingAnchor.constraint(equalTo: firstNameTextField.trailingAnchor),
            
            dobTextField.topAnchor.constraint(equalTo: lastNameTextField.bottomAnchor, constant: 16),
            dobTextField.leadingAnchor.constraint(equalTo: firstNameTextField.leadingAnchor),
            dobTextField.trailingAnchor.constraint(equalTo: firstNameTextField.trailingAnchor),
            
            genderTextField.topAnchor.constraint(equalTo: dobTextField.bottomAnchor, constant: 16),
            genderTextField.leadingAnchor.constraint(equalTo: firstNameTextField.leadingAnchor),
            genderTextField.trailingAnchor.constraint(equalTo: firstNameTextField.trailingAnchor),
            
            bioTextField.topAnchor.constraint(equalTo: genderTextField.bottomAnchor, constant: 16),
            bioTextField.leadingAnchor.constraint(equalTo: firstNameTextField.leadingAnchor),
            bioTextField.trailingAnchor.constraint(equalTo: firstNameTextField.trailingAnchor),
            
            dietPreferenceTextField.topAnchor.constraint(equalTo: bioTextField.bottomAnchor, constant: 16),
            dietPreferenceTextField.leadingAnchor.constraint(equalTo: firstNameTextField.leadingAnchor),
            dietPreferenceTextField.trailingAnchor.constraint(equalTo: firstNameTextField.trailingAnchor),
            
            fitnessLevelTextField.topAnchor.constraint(equalTo: dietPreferenceTextField.bottomAnchor, constant: 16),
            fitnessLevelTextField.leadingAnchor.constraint(equalTo: firstNameTextField.leadingAnchor),
            fitnessLevelTextField.trailingAnchor.constraint(equalTo: firstNameTextField.trailingAnchor),
            
            raceTextField.topAnchor.constraint(equalTo: fitnessLevelTextField.bottomAnchor, constant: 16),
            raceTextField.leadingAnchor.constraint(equalTo: firstNameTextField.leadingAnchor),
            raceTextField.trailingAnchor.constraint(equalTo: firstNameTextField.trailingAnchor),
            
            religionTextField.topAnchor.constraint(equalTo: raceTextField.bottomAnchor, constant: 16),
            religionTextField.leadingAnchor.constraint(equalTo: firstNameTextField.leadingAnchor),
            religionTextField.trailingAnchor.constraint(equalTo: firstNameTextField.trailingAnchor),
            
            yearTextField.topAnchor.constraint(equalTo: religionTextField.bottomAnchor, constant: 16),
            yearTextField.leadingAnchor.constraint(equalTo: firstNameTextField.leadingAnchor),
            yearTextField.trailingAnchor.constraint(equalTo: firstNameTextField.trailingAnchor)
        ])
    }
    
    private func fetchUserDetails() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: No UID found.")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").whereField("uid", isEqualTo: uid)
        
        userRef.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                print("No documents found for this user or error: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            self.userDocumentId = documents[0].documentID
            
            let userData = documents[0].data()
            
            if let firstName = userData["firstname"] as? String {
                self.firstNameTextField.text = firstName
            }
            
            if let lastName = userData["lastname"] as? String {
                self.lastNameTextField.text = lastName
            }
            
            if let dobTimestamp = userData["dob"] as? Timestamp {
                let dobDate = dobTimestamp.dateValue()
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy"
                self.dobTextField.text = formatter.string(from: dobDate)
            }
            
            if let gender = userData["gender"] as? String {
                self.genderTextField.text = gender
            }
            
            if let bio = userData["bio"] as? String {
                self.bioTextField.text = bio
            }
            
            if let dietPreference = userData["dietPreference"] as? String {
                self.dietPreferenceTextField.text = dietPreference
            }
            
            if let fitnessLevel = userData["fitnessLevel"] as? String {
                self.fitnessLevelTextField.text = fitnessLevel
            }
            
            if let race = userData["race"] as? String {
                self.raceTextField.text = race
            }
            
            if let religion = userData["religion"] as? String {
                self.religionTextField.text = religion
            }
            
            if let year = userData["year"] as? String {
                self.yearTextField.text = year
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case genderPicker:
            return genderOptions.count
        case dietPreferencePicker:
            return dietPreferenceOptions.count
        case fitnessLevelPicker:
            return fitnessLevelOptions.count
        case racePicker:
            return raceOptions.count
        case religionPicker:
            return religionOptions.count
        case yearPicker:
            return yearOptions.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case genderPicker:
            return genderOptions[row]
        case dietPreferencePicker:
            return dietPreferenceOptions[row]
        case fitnessLevelPicker:
            return fitnessLevelOptions[row]
        case racePicker:
            return raceOptions[row]
        case religionPicker:
            return religionOptions[row]
        case yearPicker:
            return yearOptions[row]
        default:
            return nil
        }
    }
    
    @objc func dietPreferenceDonePressed() {
        let selectedRow = dietPreferencePicker.selectedRow(inComponent: 0)
        dietPreferenceTextField.text = selectedRow == 0 ? "" : dietPreferenceOptions[selectedRow]
        view.endEditing(true)
    }

    @objc func fitnessLevelDonePressed() {
        let selectedRow = fitnessLevelPicker.selectedRow(inComponent: 0)
        fitnessLevelTextField.text = selectedRow == 0 ? "" : fitnessLevelOptions[selectedRow]
        view.endEditing(true)
    }

    @objc func raceDonePressed() {
        let selectedRow = racePicker.selectedRow(inComponent: 0)
        raceTextField.text = selectedRow == 0 ? "" : raceOptions[selectedRow]
        view.endEditing(true)
    }

    @objc func religionDonePressed() {
        let selectedRow = religionPicker.selectedRow(inComponent: 0)
        religionTextField.text = selectedRow == 0 ? "" : religionOptions[selectedRow]
        view.endEditing(true)
    }

    @objc func yearDonePressed() {
        let selectedRow = yearPicker.selectedRow(inComponent: 0)
        yearTextField.text = selectedRow == 0 ? "" : yearOptions[selectedRow]
        view.endEditing(true)
    }

}


