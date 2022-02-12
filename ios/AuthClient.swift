//
//  AuthClient.swift
//  rnnativegrpcclient
//
//  Created by Adonis Gaitatzis on 10/26/21.
//

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
