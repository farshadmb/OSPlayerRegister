//
//  OSPlayerRegister.m
//  Pods
//
//  Created by Farshad Mousalou on 8/6/18.
//

#import "OSPlayerRegister.h"
#import <AFNetworking/AFNetworking.h>

#import <stdlib.h>
#import <stdio.h>
#import <sys/types.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>



#define SUBSCRIPTION_SETTING @"ONESIGNAL_SUBSCRIPTION_LAST"
#define EMAIL_USERID @"GT_EMAIL_PLAYER_ID"
#define USERID @"GT_PLAYER_ID"
#define USERID_LAST @"GT_PLAYER_ID_LAST"
#define DEVICE_TOKEN @"GT_DEVICE_TOKEN"
#define SUBSCRIPTION @"ONESIGNAL_SUBSCRIPTION"
#define PUSH_TOKEN @"GT_DEVICE_TOKEN_LAST"
#define ACCEPTED_PERMISSION @"ONESIGNAL_PERMISSION_ACCEPTED_LAST"

// Defines let and var in Objective-c for shorter code
// __auto_type is compatible with Xcode 8+
#if defined(__cplusplus)
#define let auto const
#else
#define let const __auto_type
#endif

#if defined(__cplusplus)
#define var auto
#else
#define var __auto_type
#endif

@interface OSPlayerRegister()

@property (nonatomic, strong, nullable) NSString *appId;

// @property (readonly, nonatomic) BOOL subscribed; // (yes only if userId, pushToken, and setSubscription exists / are true)
@property (readwrite, nonatomic) BOOL userSubscriptionSetting; // returns setSubscription state.
@property (readwrite, nonatomic) NSString* userId;    // AKA OneSignal PlayerId
@property (readwrite, nonatomic) NSString* pushToken;
@property (nonatomic) BOOL accpeted;

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end


@interface OSPlayerRegisterAppDelegate : NSObject

@end

@implementation OSPlayerRegister

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static OSPlayerRegister *staticInstance ;
    dispatch_once(&onceToken, ^{
        
        staticInstance = [[self alloc] init];
        
    });
    
    return staticInstance;
}

- (instancetype)init {
    
    if (self = [super init]) {
        [self loadLastSettings];
        self.sessionManager = [AFHTTPSessionManager manager];
        self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    
    return self;
}

/*!
 * @discription load last settings which saved
 */
- (void)loadLastSettings {
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    _userId = [userDefaults stringForKey:USERID_LAST];
    _pushToken = [userDefaults stringForKey:PUSH_TOKEN];
    _userSubscriptionSetting = [userDefaults objectForKey:SUBSCRIPTION_SETTING] == nil;
    _accpeted = [userDefaults boolForKey:ACCEPTED_PERMISSION];
    
}

/**
 * @discussion Persist OneSignal's Data needed for work later
 */
- (void)persistAsFrom {
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString* strUserSubscriptionSetting = nil;
    if (!_userSubscriptionSetting)
        strUserSubscriptionSetting = @"no";
    
    [userDefaults setObject:strUserSubscriptionSetting forKey:SUBSCRIPTION_SETTING];
    [userDefaults setObject:_userId forKey:USERID_LAST];
    [userDefaults setObject:_pushToken forKey:PUSH_TOKEN];
    [userDefaults setBool:_accpeted forKey:ACCEPTED_PERMISSION];
    
    [userDefaults synchronize];
    
}

- (void)registerAppId:(NSString *)appId deviceToken:(NSString *)deviceToken url:(NSURL *)url completion:(OSPlayerRegisterRegistrationCompletion)completion{
    
    // check url is empty or not
    // url must be http or https url
    if (url == nil || !([url.scheme containsString:@"http"] || [url.scheme containsString:@"https"])) {
        completion(false,nil,[[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{NSLocalizedDescriptionKey : @"bad URL"}]);
        return;
    }
    
    // define userDefaults
    let userDefaults = [NSUserDefaults standardUserDefaults];
    
    // build default paramteres
    let parameters = [self defaultParamateres];
    
    // set onesignal appId
    parameters[@"app_id"] = appId;
    
    // set deviceToken
    parameters[@"identifier"] = deviceToken;
    
    if (self.userId) {
        [self put:url playerId:self.userId parameters:parameters completion:completion];
    }else{
        [self post:url parameters:parameters completion:completion];
    }
    
}

- (void)post:(NSURL *)url parameters:(NSDictionary *)parameters completion:(OSPlayerRegisterRegistrationCompletion)completion {
    // execute request to register player
    __weak typeof(self) _weakSelf = self;
    [self.sessionManager POST:url.absoluteString
                   parameters:parameters
                     progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                          
                          __strong typeof(self) __strongSelf = _weakSelf;
                          // update last session Date for onesignal
                          [__strongSelf updateLastSessionDateTime];
                          
                          
                          let json = (NSDictionary *)responseObject;
                          
                          // parse response
                          let success = [json[@"success"] boolValue];
                          let userId = json[@"id"];
                          
                          // check response has a valid userId otherwise
                          // fire completion with BadServerResponseError
                          if (userId && userId && [userId length] > 0){
                              
                              __strongSelf.userId = userId;
                              __strongSelf.accpeted = true;
                              __strongSelf.pushToken = deviceToken;
                              
                              // persist data from server and device token
                              [__strongSelf persistAsFrom];
                              
                              completion(success,userId,nil);
                          }else {
                              completion(false,nil,[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:@{NSLocalizedDescriptionKey : @"Server Bad response"}]);
                          }
                          
                          
                      } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                          completion(false,nil,error);
                      }];
}

-(void)put:(NSURL *)url playerId:(NSString *)playerId parameters:(NSDictionary *)parameters completion:(OSPlayerRegisterRegistrationCompletion)completion {
    
    var requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"/%@",playerId] relativeToURL:url];
    
    __weak typeof(self) _weakSelf = self;
    [self.sessionManager PUT:requestURL parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        __strong typeof(self) __strongSelf = _weakSelf;
        
        let json = (NSDictionary *)responseObject;
        
        // parse response
        let statusCode = [(NSHTTPURLResponse *)[task response] statusCode];
        let success = (statusCode >= 200 && statusCode <= 300);
        
        let userId = json[@"id"];
        
        
        // persist data from server and device token
        [__strongSelf persistAsFrom];
        
        completion(success,userId,nil);
        
     } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         completion(false,nil,error);
     }];
}

/*!
 * @discription Persist and update last session date time
 * @discussion persist last session date time
 */
- (void)updateLastSessionDateTime {
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    [[NSUserDefaults standardUserDefaults] setDouble:now forKey:@"GT_LAST_CLOSED_TIME"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

/**
 * @discription build default parameters for onesignal
 * @discussion such as device model app bundle id and etc.
 
 * @return a mutable dictionary contains device info and application info
 */
- (NSMutableDictionary *)defaultParamateres{
    
    let infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString* build = infoDictionary[(NSString*)kCFBundleVersionKey];
    
    struct utsname systemInfo;
    uname(&systemInfo);
    let deviceModel = [NSString stringWithCString:systemInfo.machine
                                         encoding:NSUTF8StringEncoding];
    
    let dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                   [[UIDevice currentDevice] systemVersion], @"device_os",
                   [NSNumber numberWithInt:(int)[[NSTimeZone localTimeZone] secondsFromGMT]], @"timezone",
                   [NSNumber numberWithInt:0], @"device_type",
                   [[[UIDevice currentDevice] identifierForVendor] UUIDString],@"ad_id",
                   nil];
    
    if (build)
        dataDic[@"game_version"] = build;
    
    if (deviceModel)
        dataDic[@"device_model"] = deviceModel;
    
    if (!self.userId) {
        dataDic[@"ios_bundle"] = [[NSBundle mainBundle] bundleIdentifier];
    }
    
    let preferredLanguages = [NSLocale preferredLanguages];
    if (preferredLanguages && preferredLanguages.count > 0)
        dataDic[@"language"] = [preferredLanguages objectAtIndex:0];
    
    let ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        id asIdManager = [ASIdentifierManagerClass valueForKey:@"sharedManager"];
        if ([[asIdManager valueForKey:@"advertisingTrackingEnabled"] isEqual:[NSNumber numberWithInt:1]])
            dataDic[@"as_id"] = [[asIdManager valueForKey:@"advertisingIdentifier"] UUIDString];
        else
            dataDic[@"as_id"] = @"OptedOut";
    }
    
    let CTTelephonyNetworkInfoClass = NSClassFromString(@"CTTelephonyNetworkInfo");
    if (CTTelephonyNetworkInfoClass) {
        id instance = [[CTTelephonyNetworkInfoClass alloc] init];
        let carrierName = (NSString *)[[instance valueForKey:@"subscriberCellularProvider"] valueForKey:@"carrierName"];
        
        if (carrierName) {
            dataDic[@"carrier"] = carrierName;
        }
    }
    
    dataDic[@"country"] = @"IR";
    
    return dataDic;
}

@end


