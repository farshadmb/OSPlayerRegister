//
//  OSPlayerRegister.h
//  Pods
//
//  Created by Farshad Mousalou on 8/6/18.
//

#import <Foundation/Foundation.h>


typedef void (^OSPlayerRegisterRegistrationCompletion)(bool result,NSString *__nullable userId, NSError * __nullable error);

@interface OSPlayerRegister : NSObject

/**
 singleton instace of @c@b OSPlayerRegister

 @return instance of OSPlayerRegister
 */
+ (nonnull instancetype)sharedInstance NS_SWIFT_NAME(share());


+ (nonnull instancetype)new __attribute__((unavailable("You cannot create a @OSPlayerRegister instance through +new - please use +sharedInstance")));

- (nonnull instancetype)init __attribute__((unavailable("You cannot create a @OSPlayerRegister instance through -init - please use +sharedInstance")));

/**
 register onesignal player id through your server side

 @param appId OneSignal AppId
 @param deviceToken Application Device Token
 @param url your server side url
 @param completion callback delegate @c OSPlayerRegisterRegistrationCompletion
 */
- (void)registerAppId:(nonnull NSString *)appId
          deviceToken:(nonnull NSString *)deviceToken
                  url:(nonnull NSURL *)url
           completion:(nonnull OSPlayerRegisterRegistrationCompletion)completion;


@end
