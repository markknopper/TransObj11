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
import StoreKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, URLSessionDelegate, URLSessionDataDelegate {
    
    // UI display parts
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var languageSelector: UISegmentedControl!
    @IBOutlet weak var changeableContainerView: UIView!
    @IBOutlet weak var trailingC: NSLayoutConstraint!
    @IBOutlet weak var leadingC: NSLayoutConstraint!
    
    // Vision parts
    private var requests = [VNRequest]()
    private var classificationTagResults: [String]! = []
    private var visionModel: VNCoreMLModel? = nil
    
    // Translate parts
    private var responseData: Data! = nil
    private var translationLanguage: String!
    private var yandexAPIKey = "trnsl.1.1.20170508T215556Z.b7fc78a4f209fe47.551130219ddea6ef38115ed1413e930e9f95e99e"

    // Purchasing state
    var products = [SKProduct]()

    // Hamburger menu
    var hamburgerMenuIsVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // should only appear in test_for_source_control branch.
        // Add title with icon to titleView centered on top. ***Hopefully this can be the destination of an animation from the splash screen.
        // First create a label containing attributed text with app title and icon as NSTextAttachment.
        let lemonImage = UIImage(named:"icon 42 transparent")
        self.navigationItem.titleView = UIImageView(image: lemonImage)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handlePurchaseNotification(_:)), name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification), object: nil)
        // Get list of products for sale, as soon as view loads.
        LemonProducts.store.requestProducts{success, products in
            if success {
                self.products = products!
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Make top bar white.
        self.navigationController?.navigationBar.isTranslucent = false
        super.viewWillAppear(animated)
        /* if product is already purchased, get the big languages menu and put it up. Also delete the More Languages buying button. Else just leave the segmented control as is.*** */
        let productIsPurchased = LemonProducts.store.isProductPurchased(LemonProducts.LanguagesURI)
        if productIsPurchased == true   {
            print("replace seg control with big languages menu, or start getting languages menu if it's not here yet")
        }
        
    }
    
    @IBAction func hamburgerButtonTapped(_ sender: Any) { // ハンバーガー
        //if the hamburger menu is NOT visible, then move the ubeView back to where it used to be
        if !hamburgerMenuIsVisible {
            leadingC.constant = 250 //150
            //this constant is NEGATIVE because we are moving it 150 points OUTWARD and that means -150
            trailingC.constant = -250 //-150
            //1
            hamburgerMenuIsVisible = true
        } else {
            //if the hamburger menu IS visible, then move the ubeView back to its original position
            leadingC.constant = 0
            trailingC.constant = 0
            //2
            hamburgerMenuIsVisible = false
        }
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) { (animationComplete) in
            // nada
        }

    }
    
    @objc func handlePurchaseNotification(_ notification: Notification) {
        guard let productID = notification.object as? String else { return }
        
        //for (index, product) in products.enumerated() {
        for product in products {

            guard product.productIdentifier == productID else { continue }
            
           // *** tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }

    func replaceLanguagesSelectorWithBigList() {
        let innerView = self.changeableContainerView.subviews[0]
        if innerView is UISegmentedControl {
            // Only do if not already done! But if it's already done that's weird because we already checked and the user hasn't bought the language pack. Oh well.
            let cannedLanguageList = ["Japanese","Korean","Italian"]
            // Save currently selected language.
            let selectedLanguage = languageSelector.selectedSegmentIndex
           /*
 https://tech.yandex.com/translate/
 https://translate.yandex.net/api/v1.5/tr.json/getLangs ?
 key=<API key>
 & [ui=<language code>]
 & [callback=<name of the callback function>]
*/
            
            
            /*
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
*/
            let yandexURLPrefix = "https://translate.yandex.net/api/v1.5/tr.json/getLangs?ui=en&key="
            // not sure the point of having ui=en but maybe it's nec.
            let yandexURLWholeString = String.init(format: "%@%@",yandexURLPrefix,yandexAPIKey)
            let mySession = URLSession.init(configuration: .ephemeral, delegate: self, delegateQueue: nil)
            let sessDataTask = mySession.dataTask(with: URL.init(string: yandexURLWholeString)!)
            sessDataTask.taskDescription = "getLangs"
            self.responseData = Data()
            sessDataTask.resume()
            // results processor needs to put whole list of language in UI.
            
            
        }
    }
    
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
        // *** Seems slow after tapping Use Photo. Use with Instruments here ***
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
        if visionModel == nil {
            //guard let visionModel = try? VNCoreMLModel(for: Inceptionv3().model)
            // MobileNet is default now.
            self.visionModel = try! VNCoreMLModel(for: MobileNet().model)
               // else { fatalError("can't load vision ML model")}
        }
        let classificationRequest = VNCoreMLRequest(model: self.visionModel!, completionHandler: handleClassifications)
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
        var conceptListForURL = ""
        for concept in self.classificationTagResults {
            let stringToEncode = concept.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            conceptListForURL = conceptListForURL.appendingFormat("&text=%@", stringToEncode!)
        }
        // Send each tag to Yandex to translate to Japanese!
        let yandexURLPrefix = "https://translate.yandex.net/api/v1.5/tr.json/translate?"
        let yandexURLWholeString =  String.init(format: "%@key=%@%@&lang=%@", yandexURLPrefix, yandexAPIKey, conceptListForURL, self.translationLanguage)
        let mySession = URLSession.init(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        let sessDataTask = mySession.dataTask(with: URL.init(string: yandexURLWholeString)!)
        sessDataTask.taskDescription = "translate"
        self.responseData = Data()
        sessDataTask.resume()
    }
    
    @IBAction func changedLanguage(_ sender: Any) {
        translateAndDisplayResults()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        //print("urlSession didCompleteWithError \(String(describing: error?.localizedDescription))")
        if task.taskDescription == "translate" {
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
        } else if task.taskDescription == "getLangs" {
            let jsonLanguagesDict = try! JSONSerialization.jsonObject(with: self.responseData, options: []) as! NSDictionary
            //if jsonLanguagesDict.object(forKey: "langs")
            let langs = jsonLanguagesDict.object(forKey: "langs")!
            print("thin")
/*
 (lldb) po langs as! NSDictionary
 ▿ 94 elements
 ▿ 0 : 2 elements
 - key : uk
 - value : Ukrainian
 ▿ 1 : 2 elements
 - key : no
 - value : Norwegian
 ▿ 2 : 2 elements
 - key : be
 - value : Belarusian
 ▿ 3 : 2 elements
 - key : ta
 - value : Tamil
             
             ...
             
 (lldb) po (langs as! NSDictionary).value(forKey: "ba")!
 Bashkir

             (lldb) po (langs as! NSDictionary).allValues
             ▿ 94 elements
             - 0 : Ukrainian
             - 1 : Norwegian
             - 2 : Belarusian
             - 3 : Tamil
*/
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        //print("urlSession didReceive data length \(data.count)")
        //self.responseData.append(data)
        self.responseData = data // Just assume that it all comes in at once. Above line got us into trouble when user went crazy on the segmented control.
        // Goes to urlSession:didCompleteWithError next.
    }
    
    @IBAction func buyLanguages(_ sender: Any) {
        // Maybe create a new class here. *** But for now put the code here.
        // Since there is a button here, there must be something to buy or at least attempt to buy. Bring up a dialog alert thingy.
        let productIsPurchased = LemonProducts.store.isProductPurchased(LemonProducts.LanguagesURI)
        if productIsPurchased == true {
            let buyAlert = UIAlertController(title: "You have already purchased the language pack.", message: nil, preferredStyle: .actionSheet)
            buyAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(buyAlert, animated: true, completion: nil)
        } else { // haven't purchased.
            let buyAlert = UIAlertController(title: "Buy Languages", message: "Want to buy some languages for $0.99?", preferredStyle: .actionSheet )
            buyAlert.addAction(UIAlertAction(title: "Buy", style: .default, handler: { action in
                print("how to buy?")
                // *** Need to do buying stuff. Not this until purchase happens.
                // Start up the url session task to request the list of languages.
                self.replaceLanguagesSelectorWithBigList()
                // *** anything here? Need to dismiss the alert? Segmented control should just magically change to pull down menu or maybe a button for a picker view.
            }))
            buyAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(buyAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func mlModelSelect(_ sender: Any) {
        let mlModelAlert = UIAlertController(title: "Select Machine Learning Model", message: nil, preferredStyle: .actionSheet)
        mlModelAlert.addAction(UIAlertAction(title: "MobileNet", style: .default, handler: { action in
            self.visionModel = try! VNCoreMLModel(for: MobileNet().model)
        }))
        mlModelAlert.addAction(UIAlertAction(title: "Inceptionv3", style: .default, handler: { action in
            self.visionModel = try! VNCoreMLModel(for: Inceptionv3().model)
            }))
        mlModelAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(mlModelAlert, animated: true, completion: nil)
    }
}
