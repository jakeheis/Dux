# Dux

[![Build Status](https://github.com/jakeheis/Dux/workflows/Build/badge.svg)](https://github.com/jakeheis/SwiftCLI/actions)

Guide users through your SwiftUI app with coach marks.

<img src=".github/Screenshot.png" width="240">

## Pre-release note

`Dux` has not hit `1.0.0` yet and is undergoing active development which means APIs are unstable and may change.

## Installation

In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jakeheis/Dux", .upToNextMajor(from: "0.0.1"))
]
```

## Usage

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            DuxContainerView {
                MyView()
            }
        }
    }
}

struct MyView: View {
    enum Tags: DuxTags {
        case hello
        
        func makeCallout() -> Callout {
            .text("This is a message saying hello")
        }
    }
    
    var body: some View {
        VStack {
            Text("Hello world")
                .duxTag(Tags.hello)
        }
        .dux(isActive: true, tags: Tags.self)
    }
}
```

See the `Examples` directory for more examples of how to use `Dux`.

## Attributions

Inspired by https://github.com/ephread/Instructions
