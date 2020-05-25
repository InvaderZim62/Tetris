//
//  HighScoresViewController.swift
//  Tetris
//
//  Created by Phil Stern on 5/18/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//

import UIKit

class HighScoresViewController: UIViewController, UITextFieldDelegate {

    var highScores = [Int]()
    var highScoreInitials = [String]()
    
    @IBOutlet var highScoreLabels: [UILabel]!
    @IBOutlet var highScoreInitialsLabels: [UILabel]!
    @IBOutlet weak var initialsTextField: UITextField! {
        didSet {
            initialsTextField.delegate = self
            initialsTextField.autocapitalizationType = .allCharacters  // force caps
            initialsTextField.autocorrectionType = .no                 // don't suggest words while typing
            initialsTextField.smartInsertDeleteType = .no              // don't include spaces, if pasting
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // try reading high scores from UserDefaults
        let defaults = UserDefaults.standard
        if let scores = defaults.array(forKey: "highScores") as? [Int] {
            highScores = scores
            highScoreInitials = defaults.stringArray(forKey: "highScoreInitials")!
        } else {
            highScores = [Int](repeating: Constants.defaultScore, count: 10)
            highScoreInitials = [String](repeating: "TET", count: 10)
        }
        updateAllLabels()
    }
    
    // update top scores labels
    private func updateAllLabels() {
        // temporarily sort both arrays by highScore
        let combined = zip(highScores, highScoreInitials).sorted { $0.0 > $1.0 }  // returns tuple
        let highScoresSorted = combined.map { $0.0 }
        let highScoreInitialsSorted = combined.map { $0.1 }
        // update labels
        zip(highScoreLabels, highScoresSorted).forEach { $0.text = "\($1)" }
        zip(highScoreInitialsLabels, highScoreInitialsSorted).forEach { $0.text = $1 }
    }
    
    @IBAction func doneSelected(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITextFieldDelegate

    // called after user enters Return on keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        initialsTextField.resignFirstResponder()
        highScoreInitials[highScores.count - 1] = textField.text!  // replace name
        updateAllLabels()
        
        // save high scores to userDefaults
        let defaults = UserDefaults.standard
        defaults.set(highScores, forKey: "highScores")
        defaults.set(highScoreInitials, forKey: "highScoreInitials")

        return true
    }
    
    // limit input to three characters (in top scores view)
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= 3
    }
}
