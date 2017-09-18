//
//  ViewController.swift
//  TransObj11
//
//  Created by Mark Knopper on 6/6/17.
//  Copyright © 2017 Bulbous Ventures LLC. All rights reserved.
//

import UIKit
import Vision
import AVFoundation
import ImageIO
import CoreML

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, URLSessionDelegate, URLSessionDataDelegate {
    
    // UI display parts
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var languageSelector: UISegmentedControl!

    // Vision parts
    private var requests = [VNRequest]()
    private var classificationTagResults: [String]! = []
    
    // Translate parts
    private var responseData: Data! = nil
    private var translationLanguage: String!
    
    @IBAction func selectImageButtonPressed(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        if UIImagePickerController.isSourceTypeAvailable(.camera) { // just forget if no camera, eg. simulator.
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            picker.sourceType = .photoLibrary
        }
        self.present(picker, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        self.dismiss(animated: true)
        if let image = info[UIImagePickerControllerOriginalImage] as! UIImage? {
            self.imageView.image = image
            self.textView.text = "Recognizing..."
            setupVision() // Sets up classificationRequest.
            let cgImage = image.cgImage // *** Need to test for nil and use ciImage instead?
            let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: CGImagePropertyOrientation(rawValue: UInt32(Int32(UIDevice.current.orientation.rawValue)))!, options: [:])
            do {
                // tell VNImageRequestHandler to perform the [VNCoreMLRequest].
                try imageRequestHandler.perform(self.requests)
                // This will end up in the VNCoreMLRequest's completionHandler, which is handleClassifications.
            } catch {
                print(error)
            }
        }
    }
    
    func setupVision()
    {
        guard let visionModel = try? VNCoreMLModel(for: Inceptionv3().model)
            else { fatalError("can't load vision ML model")}
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleClassifications)
        classificationRequest.imageCropAndScaleOption = .centerCrop
        self.requests = [classificationRequest]
    }
    
    // handleClassifications: completion handler for the VNCoreMLRequest
    func handleClassifications(request: VNRequest, error: Error?) {
        guard let observations = request.results as! [VNClassificationObservation]?
            else { print("no results: \(error!)"); return }
        // Observations are all VNClassificationObservation which has an "identifier" property containing a comma delimited list of keywords relating to the classification.
        // VNClassificationObservation inherits from VNObservation which has a "confidence" property.
        // It also seems that the observations are sorted by confidence. Let's assume these two things for now.
        // Extract each of these tags from the first 5 observation results and add the strings to classificationTagResults
        self.classificationTagResults = [] // Start fresh.
        for index in 0...4 { // take 5 highest confidence items
            if let anObservation = observations[index] as VNClassificationObservation? {
                let observedTags = anObservation.identifier
                let tagComponents = observedTags.components(separatedBy: ", ") // string could have spaces like "crossword puzzle".
                self.classificationTagResults.append(contentsOf: tagComponents)
                DispatchQueue.main.async { // perform all UI updates on main queue
                    self.textView.text = "Classification: \n" + self.classificationTagResults.joined(separator: ", ")
                }
            }
        }
        // Got em all, now create a string to display on the UI
        DispatchQueue.main.async { // perform all UI updates on main queue
            self.textView.text = "Classification: \n" + self.classificationTagResults.joined(separator: ", ")
        }
        translateAndDisplayResults()
    }
    
    func translateAndDisplayResults() {
        switch self.languageSelector.selectedSegmentIndex {
        case 0:
            self.translationLanguage = "en-ja"
        case 1:
            self.translationLanguage = "en-ko"
        case 2:
            self.translationLanguage = "en-it"
        default:
            self.translationLanguage = "en-ja"
        }
        // Now send out each keyword for translation.
        // Loop through predicted concepts (tags), and display them on the screen.
        /*
         https://translate.yandex.net/api/v1.5/tr.json/translate ?
         key=<API key>
         & text=<text to translate>
         & lang=<translation direction>
         & [format=<text format>]
         & [options=<translation options>]
         & [callback=<name of the callback function>]
         */
        // Probably make these constants globally.
        let yandexURLPrefix = "https://translate.yandex.net/api/v1.5/tr.json/translate?"
        let yandelAPIKey = "trnsl.1.1.20170508T215556Z.b7fc78a4f209fe47.551130219ddea6ef38115ed1413e930e9f95e99e"
        var conceptListForURL = ""
        for concept in self.classificationTagResults {
            let stringToEncode = concept.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            conceptListForURL = conceptListForURL.appendingFormat("&text=%@", stringToEncode!)
        }
        // Send each tag to Yandex to translate to Japanese!
        let yandexURLWholeString =  String.init(format: "%@key=%@%@&lang=%@", yandexURLPrefix, yandelAPIKey, conceptListForURL, self.translationLanguage)
        let mySession = URLSession.init(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        let sessDataTask = mySession.dataTask(with: URL.init(string: yandexURLWholeString)!)
        self.responseData = Data()
        sessDataTask.resume()
    }
    
    @IBAction func changedLanguage(_ sender: Any) {
        translateAndDisplayResults()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("urlSession didCompleteWithError \(String(describing: error?.localizedDescription))")
        let jsonDict = try! JSONSerialization.jsonObject(with: self.responseData, options: []) as! NSDictionary
        if jsonDict.object(forKey: "code") as! Int == 200 {
            let otherLanguageTagNames = jsonDict.object(forKey: "text") as! [String]
            var tags: [String] = []
            for index in 0...self.classificationTagResults.count-1 {
                if self.translationLanguage == "en-it" {
                    tags.append(String.init(format: "%@ (%@)", self.classificationTagResults[index], otherLanguageTagNames[index]))
                } else {
                    tags.append(String.init(format: "%@ %@", self.classificationTagResults[index], otherLanguageTagNames[index]))
                }
            }
            DispatchQueue.main.async { // perform all UI updates on main queue
                self.textView.text = "Classification:\n" + tags.joined(separator: ", ")
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("urlSession didReceive data length \(data.count)")
        //self.responseData.append(data)
        self.responseData = data // Just assume that it all comes in at once. Above line got us into trouble when user went crazy on the segmented control.
    }
    
}
