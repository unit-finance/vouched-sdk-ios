## Unit Vouched SDK Sample App

### Introduction
Customers of Unit can use this app to more easily implement the Vouched SDK. This project served as the source for all the examples used in the [Vocuhed SDK for iOS](../README.md).
The project includes all of the code, in great detail, with many comments.

### Files to notice

#### UNVouchedService
A service that uses Vouched SDK and intends to show the detection flow in a clear way. It holds `UNVouchedServiceDelegate` that is used to pass data to the `ViewController`.

#### ViewController
A controller that handles UI changes and holds a reference to a `UNVouchedService`. Conforms to the `UNVouchedServiceDelegate` delegate.
The controller demonstrates the following flow:
   - Capture an id
   - Capture a selfie
   - Print the result of the captures that was returned from Vouched

#### Vouch+DescriptiveText
An extension for Vouched Insight and Instruction enums. It shows a way to control the messages the user will receive on the different scenarios.

### Getting Started

- Clone the [vouched-sdk-ios](https://github.com/unit-finance/vocuhed-sdk-ios.git) repo
- install Pods
``` swift
pod install
```
- Open the project using the UnitVouchSampleApp.xcworkspace file
- Open the `UNConstants` file and fill the `publicKey` variable with your Vouched Public Key.
