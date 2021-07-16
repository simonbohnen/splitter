import UIKit
import VisionKit
import Vision
import PhotosUI

class DocumentScanningViewController: UIViewController {
    var receiptViewController: ReceiptViewController?
    var textRecognitionRequest = VNRecognizeTextRequest()

    override func viewDidLoad() {
        super.viewDidLoad()
        textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    DispatchQueue.main.async {
                        self.receiptViewController?.addPositions(fromObservations: requestResults)
                    }
                }
            }
        })
        // We want an accurate analysis
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
    }
    @IBAction func scanFromPhoto(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        pickerController.sourceType = .photoLibrary
        present(pickerController, animated: true)
    }
    
    @IBAction func scanReceipt(_ sender: UIControl) {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
    }
    
    func processImage(image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Failed to get cgimage from input image")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([textRecognitionRequest])
        } catch {
            print(error)
        }
    }
}

extension DocumentScanningViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        self.receiptViewController = storyboard?.instantiateViewController(withIdentifier: "receiptVC") as? ReceiptViewController
        
        controller.dismiss(animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                for pageNumber in 0 ..< scan.pageCount {
                    let image = scan.imageOfPage(at: pageNumber)
                    self.processImage(image: image)
                }
                DispatchQueue.main.async {
                    if let resultsVC = self.receiptViewController {
                        self.navigationController!.pushViewController(resultsVC, animated: true)
                    }
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.receiptViewController = storyboard?.instantiateViewController(withIdentifier: "receiptVC") as? ReceiptViewController
        
        picker.dismiss(animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                if let image = info[.editedImage] as? UIImage {
                    self.processImage(image: image)
                    
                    DispatchQueue.main.async {
                        if let resultsVC = self.receiptViewController {
                            self.navigationController!.pushViewController(resultsVC, animated: true)
                        }
                    }
                }
            }
        }
    }
}

extension DocumentScanningViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        self.receiptViewController = storyboard?.instantiateViewController(withIdentifier: "receiptVC") as? ReceiptViewController
        
        picker.dismiss(animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                let result = results.first!
                let itemProvider = result.itemProvider
                _ = itemProvider.loadObject(ofClass: UIImage.self) { [weak self] photo, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    if let uiImage = photo as? UIImage {
                        self?.processImage(image: uiImage)
                        
                        DispatchQueue.main.async {
                            if let resultsVC = self?.receiptViewController {
                                self?.navigationController!.pushViewController(resultsVC, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
}
