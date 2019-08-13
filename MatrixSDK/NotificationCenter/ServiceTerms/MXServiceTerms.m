/*
 Copyright 2019 The Matrix.org Foundation C.I.C

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXServiceTerms.h"
#import "MXServiceTermsRestClient.h"

#import "MXRestClient.h"
#import "MXTools.h"


NSString *const kMXIntegrationManagerAPIPrefixPathV1 = @"_matrix/integrations/v1";

@interface MXServiceTerms()

@property (nonatomic, strong) MXServiceTermsRestClient *restClient;
@property (nonatomic, nullable) MXSession *mxSession;
@property (nonatomic, nullable) NSString *accessToken;

@end

@implementation MXServiceTerms

- (instancetype)initWithBaseUrl:(NSString*)baseUrl serviceType:(MXServiceType)serviceType matrixSession:(nullable MXSession *)mxSession accessToken:(nullable NSString *)accessToken
{
    self = [super init];
    if (self)
    {
        _baseUrl = [baseUrl copy];
        _serviceType = serviceType;
        _mxSession = mxSession;
        _accessToken = [accessToken copy];

        _restClient = [[MXServiceTermsRestClient alloc] initWithBaseUrl:self.termsBaseUrl accessToken:@"bobo"];//accessToken];
    }
    return self;
}

- (MXHTTPOperation*)terms:(void (^)(MXLoginTerms * _Nullable terms, NSArray<NSString*> * _Nullable alreadyAcceptedTermsUrls))success
                  failure:(nullable void (^)(NSError * _Nonnull))failure
{
    return [_restClient terms:^(MXLoginTerms * _Nullable terms) {
        success(terms, self.acceptedTerms);
    } failure:failure];
}

- (MXHTTPOperation *)agreeToTerms:(NSArray<NSString *> *)termsUrls
                          success:(void (^)(void))success
                          failure:(void (^)(NSError * _Nonnull))failure
{
    if (!_mxSession || !_accessToken)
    {
        if (failure)
        {
            MXError *error = [[MXError alloc] initWithErrorCode:kMXSDKErrCodeStringMissingParameters error:@"No Matrix session or no access token"];
            failure([error createNSError]);
        }
        return nil;
    }

    // First, send consents to the 3rd party server
    MXHTTPOperation *operation;
    MXWeakify(self);
    operation = [_restClient agreeToTerms:termsUrls success:^{
        MXStrongifyAndReturnIfNil(self);

        // Then, store consents to the user account data
        // Merge newly and previously accepted terms to store in account data
        NSSet *acceptedTermsUrls = [NSSet setWithArray:termsUrls];
        if (self.acceptedTerms)
        {
            acceptedTermsUrls = [acceptedTermsUrls setByAddingObjectsFromArray:self.acceptedTerms];
        }

        NSDictionary *accountDataAcceptedTerms = @{
                                                   kMXAccountDataTypeAcceptedTermsKey: acceptedTermsUrls.allObjects
                                                   };

        MXHTTPOperation *operation;
        operation = [self.mxSession setAccountData:accountDataAcceptedTerms forType:kMXAccountDataTypeAcceptedTerms success:success failure:failure];

    } failure:failure];

    return operation;
}

#pragma mark - Private methods

- (NSString*)termsBaseUrl
{
    NSString *termsBaseUrl;
    switch (_serviceType)
    {
        case MXServiceTypeIdentityService:
            termsBaseUrl = [NSString stringWithFormat:@"%@/%@", _baseUrl, kMXIdentityAPIPrefixPathV2];
            break;

        case MXServiceTypeIntegrationManager:
            termsBaseUrl = [NSString stringWithFormat:@"%@/%@", _baseUrl, kMXIntegrationManagerAPIPrefixPathV1];
            break;

        default:
            break;
    }

    return termsBaseUrl;
}


#pragma mark - Private methods

// Accepted terms in account data
- (nullable NSArray<NSString*> *)acceptedTerms
{
    NSArray<NSString*> *acceptedTerms;

    MXJSONModelSetArray(acceptedTerms,
                        [_mxSession.accountData accountDataForEventType:kMXAccountDataTypeAcceptedTerms][kMXAccountDataTypeAcceptedTermsKey]);

    return acceptedTerms;
}

@end
