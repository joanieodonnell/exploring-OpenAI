//
//  ContentView.swift
//  Quiz4
//
//  Created by Joanie O'Donnell on 4/10/23.
//

import SwiftUI
import OpenAIKit
import NaturalLanguage

// ViewModel to handle API calls for Image Generation and Sentence Completion
final class ViewModel: ObservableObject {
    private var openai: OpenAI?

    // Setup the OpenAI API configuration
    func setup() {
        openai = OpenAI(Configuration(organizationId: "Personal", apiKey: "your_api_key"))
    }

    // Image Generation
    func generateImage(prompt: String) async -> UIImage? {
        guard let openai = openai else {
            return nil
        }

        do {
            // Setup the image parameters and make the API call
            let params = ImageParameters(prompt: prompt, resolution: .medium, responseFormat: .base64Json)
            let result = try await openai.createImage(parameters: params)

            // Decode the base64-encoded image data and return as UIImage
            let data = result.data[0].image
            let image = try openai.decodeBase64Image(data)
            return image
        } catch {
            print(String(describing: error))
            return nil
        }
    }

    // Sentence Completion
    func generateText(prompt: String) async -> String? {
        guard let openai = openai else {
            return nil
        }

        do {
            // Setup the completion parameters and make the API call
            let params = CompletionParameters(model: "text-davinci-002", prompt: [prompt], maxTokens: 20, temperature: 0.98)
            let result = try await openai.generateCompletion(parameters: params)

            // Format and return the generated text
            let data = result.choices[0].text.replacingOccurrences(of: "\n", with: " ")
            return data
        } catch {
            print(String(describing: error))
            return nil
        }
    }
}

// ImageGeneratorView for generating images based on a user's text input
struct ImageGeneratorView: View {
    @ObservedObject var viewModel: ViewModel
    @State var text = ""
    @State var image: UIImage?

    var body: some View {
        VStack {
            // Display the generated image or a placeholder text
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
            } else {
                Text("Type prompt to generate image!")
            }

            // Text input field for the image generation prompt
            TextField("Type prompt here...", text: $text)
                .padding()

            // Button to generate the image
            Button("Generate!") {
                Task {
                    if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                        Task {
                            let result = await viewModel.generateImage(prompt: text)
                            self.image = result
                            if result == nil {
                                print("failed to get image")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Image Generator")
    }
}

// SentenceCompletionView for completing a user's input sentence
struct SentenceCompletionView: View {
    @ObservedObject var viewModel: ViewModel
    @State var userInput: String = ""
    @State var output: String?

    var body: some View {
        VStack {
            // Display the completed sentence or a placeholder text
            if let output = output {
                Text(output)
            } else {
                Text("Type prompt to complete sentence")
            }

            // Text input field for the sentence prompt
            TextField("Type sentence prompt here...", text: $userInput)
                .padding(20)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Button to generate the completed sentence
            Button("Generate Complete Sentence") {
                if !userInput.trimmingCharacters(in: .whitespaces).isEmpty {
                    Task {
                        let result = await viewModel.generateText(prompt: userInput)
                        if result == nil {
                            print("Failed Generating Sentence, Try Again")
                        }
                        self.output = result
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Sentence Completion")
    }
}

// SentimentAnalyzerView for analyzing the sentiment of a user's input sentence
struct SentimentAnalyzerView: View {
    @State private var sentence = ""
    @State private var sentiment = ""

    var body: some View {
        VStack {
            TextField("Enter a sentence", text: $sentence)
                .padding()

            Button(action: analyzeSentiment) {
                Text("Analyze")
            }
            .padding()

            Text(sentiment)
                .font(.title)
        }
        .padding()
        .navigationTitle("Sentiment Analyzer")
    }

    private func analyzeSentiment() {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = sentence

        let (sentiment, _) = tagger.tag(at: sentence.startIndex, unit: .paragraph, scheme: .sentimentScore)

        let sentimentScore = Double(sentiment?.rawValue ?? "0") ?? 0.0

        if sentimentScore > 0.0 {
            self.sentiment = "Positive"
        } else if sentimentScore < 0.0 {
            self.sentiment = "Negative"
        } else {
            self.sentiment = "Neutral"
        }
    }
}

// ContentView with a TabView including all three features
struct ContentView: View {
    @StateObject var viewModel = ViewModel()

    var body: some View {
        TabView {
            NavigationView {
                ImageGeneratorView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "photo")
                Text("Image Generator")
            }

            NavigationView {
                SentenceCompletionView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "text.bubble")
                Text("Sentence Completion")
            }

            NavigationView {
                SentimentAnalyzerView()
            }
            .tabItem {
                Image(systemName: "face.smiling")
                Text("Sentiment Analyzer")
            }
        }
        .onAppear {
            viewModel.setup()
        }
    }
}

// ContentView_Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
