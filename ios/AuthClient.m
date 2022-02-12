//
//  AuthClient.m
//  rnnativegrpcclient
//
//  Created by Adonis Gaitatzis on 10/26/21.
//

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
