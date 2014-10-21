//
//  DCTBasicAuthAccount.m
//  DCTAuth
//
//  Created by Daniel Tull on 29/08/2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTBasicAuthAccount.h"
#import "DCTAuthAccountSubclass.h"
#import "DCTBasicAuthCredential.h"
#import "DCTAuthRequest.h"

static const struct DCTBasicAuthAccountProperties {
	__unsafe_unretained NSString *authenticationURL;
} DCTBasicAuthAccountProperties;

static const struct DCTBasicAuthAccountProperties DCTBasicAuthAccountProperties = {
	.authenticationURL = @"authenticationURL"
};

@interface DCTBasicAuthAccount () <DCTAuthAccountSubclass>
@property (nonatomic) NSURL *authenticationURL;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;
@end

@implementation DCTBasicAuthAccount

#pragma mark - DCTBasicAuthAccount

- (instancetype)initWithType:(NSString *)type
		   authenticationURL:(NSURL *)authenticationURL
					username:(NSString *)username
					password:(NSString *)password {

	self = [self initWithType:type];
	if (!self) return nil;

	_authenticationURL = [authenticationURL copy];
	_username = [username copy];
	_password = [password copy];
	
	return self;
}

- (NSString *)username {

	if (_username) {
		return _username;
	}

	DCTBasicAuthCredential *credential = self.credential;
	return credential.username;
}

- (NSString *)password {

	if (_password) {
		return _password;
	}

	DCTBasicAuthCredential *credential = self.credential;
	return credential.password;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (!self) return nil;
	_authenticationURL = [coder decodeObjectOfClass:[NSURL class] forKey:DCTBasicAuthAccountProperties.authenticationURL];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:self.authenticationURL forKey:DCTBasicAuthAccountProperties.authenticationURL];
}

#pragma mark - DCTAuthAccount

- (void)authenticateWithHandler:(void(^)(NSArray *responses, NSError *error))handler {

	DCTAuthRequest *request = [[DCTAuthRequest alloc] initWithRequestMethod:DCTAuthRequestMethodGET
																		URL:self.authenticationURL
																 parameters:nil];

	DCTBasicAuthCredential *credential = [[DCTBasicAuthCredential alloc] initWithUsername:self.username password:self.password];
	NSString *authorizationHeader = credential.authorizationHeader;
	if (authorizationHeader) {
		request.HTTPHeaders = @{ @"Authorization" : authorizationHeader };
	}

	[request performRequestWithHandler:^(DCTAuthResponse *response, NSError *error) {

		if (response.statusCode == 200)
			self.credential = credential;

		NSArray *array = response ? @[response] : nil;
		if (handler != NULL) handler(array, error);
	}];
}

#pragma mark - DCTAuthAccountSubclass

- (void)signURLRequest:(NSMutableURLRequest *)request forAuthRequest:(DCTAuthRequest *)oauthRequest {

	DCTBasicAuthCredential *credential = self.credential;
	if (!credential) {
		credential = [[DCTBasicAuthCredential alloc] initWithUsername:self.username password:self.password];
	}

	NSString *authorizationHeader = credential.authorizationHeader;
	if (authorizationHeader) {
		[request addValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
	}
}

@end
