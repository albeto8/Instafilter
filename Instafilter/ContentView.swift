//
//  ContentView.swift
//  Instafilter
//
//  Created by Mario Alberto Barragán Espinosa on 30/11/19.
//  Copyright © 2019 Mario Alberto Barragán Espinosa. All rights reserved.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    
    @State private var image: Image?
    @State private var filterIntensity = 0.5
    @State private var filterScale = 0.5
    @State private var filterRadius = 0.5
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    @State var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    @State private var showingFilterSheet = false
    @State private var processedImage: UIImage?
    @State private var showErrorAlert = false
    @State private var alertErrorMessage = ""
    @State private var showIntensitySlider = true
    @State private var showScaleSlider = false
    @State private var showRadiusSlider = false

    
    var body: some View {
        let intensity = Binding<Double>(
            get: {
                self.filterIntensity
            },
            set: {
                self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        let scale = Binding<Double>(
            get: {
                self.filterScale
            },
            set: {
                self.filterScale = $0
                self.applyProcessing()
            }
        )
        let radius = Binding<Double>(
            get: {
                self.filterRadius
            },
            set: {
                self.filterRadius = $0
                self.applyProcessing()
            }
        )
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)

                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    self.showingImagePicker = true
                }

                VStack {
                    Text("Intensity")
                    Slider(value: intensity).disabled(!showIntensitySlider)
                    Text("Radius")
                    Slider(value: radius).disabled(!showRadiusSlider)
                    Text("Scale")
                    Slider(value: scale).disabled(!showScaleSlider)
                }.padding(.vertical)

                HStack {
                    Button(self.currentFilter.name) {
                        self.showingFilterSheet = true
                    }

                    Spacer()

                    Button("Save") {
                        guard let processedImage = self.processedImage else {
                          self.showErrorAlert = true
                          self.alertErrorMessage = "No image selected"
                          return
                      }

                        let imageSaver = ImageSaver()

                        imageSaver.successHandler = {
                            print("Success!")
                        }

                        imageSaver.errorHandler = {
                            print("Oops: \($0.localizedDescription)")
                        }

                        imageSaver.writeToPhotoAlbum(image: processedImage)
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text("Crystallize")) { self.setFilter(CIFilter.crystallize()) },
                    .default(Text("Edges")) { self.setFilter(CIFilter.edges()) },
                    .default(Text("Gaussian Blur")) { self.setFilter(CIFilter.gaussianBlur()) },
                    .default(Text("Pixellate")) { self.setFilter(CIFilter.pixellate()) },
                    .default(Text("Sepia Tone")) { self.setFilter(CIFilter.sepiaTone()) },
                    .default(Text("Unsharp Mask")) { self.setFilter(CIFilter.unsharpMask()) },
                    .default(Text("Vignette")) { self.setFilter(CIFilter.vignette()) },
                    .cancel()
                ])
            }
            .alert(isPresented: $showErrorAlert) { () -> Alert in
              Alert(title: Text("Error"), message: Text(self.alertErrorMessage), dismissButton: .default(Text("OK")))
          }
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }

        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }

    func setFilterValues() {
      let inputKeys = currentFilter.inputKeys
      if inputKeys.contains(kCIInputIntensityKey) {
        currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        self.showIntensitySlider = true
      } else {
        self.showIntensitySlider = false
      }
      if inputKeys.contains(kCIInputRadiusKey) {
        self.showRadiusSlider = true
        currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey)
      } else {
        self.showRadiusSlider = false
      }
      if inputKeys.contains(kCIInputScaleKey) {
        self.showScaleSlider = true
        currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey)
      } else {
        self.showScaleSlider = false
      }
    }
    
    func applyProcessing() {
        setFilterValues()
        guard let outputImage = currentFilter.outputImage else { return }

        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        setFilterValues()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
