

## Create a React Native Project

```console
$ npx react-native init RnNativeGrpcClient
$ cd RnNativeGrpcClient
```

Compile so that everything gets linked properly

```
$ npx react-native run-ios
# or 
$ npm run ios
```

## Install Dependencies

Open project in Xcode.

```console
$ open ios/RnNativeGrpcClient.xcworkspace &
```

Open the `Podfile` and make changes:

Update to target version "14": 
```Podfile
platform :ios, '14.0'
```

Comment out `use_flipper!()` and add `use_frameworks!`
Add:
```Podfile
  pod 'gRPC-Swift', '~> 1.5.0' # Latest at the time of writing
  pod 'gRPC-Swift-Plugins'
```

Install pods

```console
$ cd ios
$ pod install
```

Generate the swift code for the gRPC client.
```console
$ protoc authService.proto \
      --grpc-swift_opt=Client=true,Server=false \
      --grpc-swift_out=ios/
$ protoc authService.proto \
      --proto_path=. \
      --swift_opt=Visibility=Public \
      --swift_out=ios/
```

Drag and drop `authClient.grpc.swift` into the Xcode project folder containing `Info.plist`

## Add gRPC Functions

In Xcode:

Create a new Swift File called `AuthClient`

Do create an Objective-C bridging header. This will be called `<project-name>-Bridging-Header.h`

Add this to `<project-name>-Bridging-Header.h`:
```objc
#import "React/RCTBridgeModule.h"
```

Edit `AuthClient.swift`:

notice how we handle `@objc` bindings and `RCTPromiseResolveBlock`.

```swift
import Foundation
import GRPC
import NIO

@objc(AuthClient)
class AuthClient: NSObject {
  var authServiceClient: AuthService_AuthServiceRoutesClient?
  let port: Int = 50051
  
  @objc static func requiresMainQueueSetup() -> Bool { return false }
  @objc override init() {
    // build a fountain of EventLoops
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    do {
      // open a channel to the gPRC server
      let channel = try GRPCChannelPool.with(
        target: .host("localhost", port: self.port),
        transportSecurity: .plaintext,
        eventLoopGroup: eventLoopGroup
      )
      // create a Client
      self.authServiceClient = AuthService_AuthServiceRoutesClient(channel: channel)
      print("gRPC connection initialized")
    } catch {
      print("Couldn’t connect to gRPC server")
    }
  }
  
  @objc func login(
    _ username: String,
    password: String,
    resolve: RCTPromiseResolveBlock,
    rejecter reject: RCTPromiseRejectBlock
  ) {
    print("Login: username=\(username)")
    // build the AccountCredentials object
    let accountCredentials: AuthService_AccountCredentials = .with {
      $0.username = username
      $0.password = password
    }
    // grab the login() method from the gRPC client
    let call = self.authServiceClient!.login(accountCredentials)
    do {
      let oauthCredentials = try call.response.wait()
      resolve([
        "token": oauthCredentials.token,
        "timeoutSeconds": oauthCredentials.timeoutSeconds
      ])
    } catch {
      print("RPC method ‘login’ failed: \(error)")
      let error = NSError(domain: "", code: 200, userInfo: nil)
      reject("0", "RPC method ‘login’ failed", error)
    }
  }
  
  @objc func logout(
    _ oauthToken: String,
    resolve: RCTPromiseResolveBlock,
    rejecter reject: RCTPromiseRejectBlock
  ) {
    print("Logout: token=\(oauthToken)")
    // build the OauthCredentials object
    let oauthCredentials: AuthService_OauthCredentials = .with {
      $0.token = oauthToken
    }
    // grab the logout() method from the gRPC client
    let call = self.authServiceClient!.logout(oauthCredentials)
    // execute the gRPC call and grab the result
    do {
      let logoutResult = try call.response.wait()
      print("Logged out")
      resolve(["token": logoutResult.token, "timeoutSeconds": logoutResult.timeoutSeconds])
    } catch {
      print("RPC method ‘logout’ failed: \(error)")
      let error = NSError(domain: "", code: 200, userInfo: nil)
      reject("0", "RPC method ‘logout’ failed", error)
    }
  }
}
```

## Expose the gRPC Features

Create a new Objective-C file, called `AuthClient.m`:

```objc
#import <Foundation/Foundation.h>
#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(AuthClient, NSObject)
  RCT_EXTERN_METHOD(init)
  RCT_EXTERN_METHOD(
    login: (NSString *)username
    password:(NSString *)password
    resolve: (RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject
  )
  RCT_EXTERN_METHOD(
    logout: (NSString *) oauthToken
    resolve: (RCTPromiseResolveBlock) resolve
    rejecter: (RCTPromiseRejectBlock) reject
  )
@end

```

Compile to test

## Build React Native Class

Mirror the functions in the `ios/AuthClient.swift` in Javascript.

In this case we will make a file called `utils/AuthClient.js`:

```javascript
import { NativeModules } from "react-native"
const { AuthClient } = NativeModules

export default class JsAuthClient {
    constructor () {
        this.nativeAuthClient = AuthClient
        this.nativeAuthClient.init()
    }
    async login (username, password) {
        return this.nativeAuthClient.login(username, password)
    }
    async logout (oauthToken) {
        return this.nativeAuthClient.logout(oauthToken)
    }
}
```

Let's try executing these methods from the UI:

Edit `App.js`:

```javascript
import React, { useRef, useState } from 'react'
import {
  Text,
  TextInput,
  Button
} from 'react-native'
import JsAuthClient from './utils/JsAuthClient

// ...

const Section = ({children, title}): Node => {
  const [username, setUsername] = useState('email@example.com')
  const [password, setPassword] = useState('password')
  const [oauthToken, setOauthToken] = useState('')
  const jsAuthClient = useRef(new JsAuthClient())

  const login = async (username, password) => {
    try {
      const oauthData = await jsAuthClient.current.login(username, password)
      setOauthToken(oauthData.token)
    } catch (error) {
      console.log(error)
      console.log(error.message)
    }
  }
  const logout = async (oauthToken) => {
    await jsAuthClient.current.logout(oauthToken)
    setOauthToken('')
  }

  // ...
  return (

      <TextInput
        type="email"
        placeholder="Email"
        autoCapitalize="none"
        value={username}
        onChangeText={setUsername}
      />
      <TextInput
        type="password"
        placeholder="Password"
        autoCapitalize="none"
        value={password}
        onChangeText={setPassword}
      />
      <Button
        title="Login"
        onPress={() => {
          login(username, password)
        }}
      />
      <Button
        title="Logout"
        onPress={() => {
          logout(oauthToken)
        }}
      />
      <Text>Oauth Token: {oauthToken}</Text>

  )
}
```