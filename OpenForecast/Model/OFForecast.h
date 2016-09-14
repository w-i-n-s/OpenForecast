//
//  OFForecast.h
//  OpenForecast
//
//  Created by Sergey Vinogradov on 12.09.16.
//  Copyright © 2016 forecaster. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OFForecast : NSObject

@property (strong, nonatomic) NSString *idString;
@property (strong, nonatomic) NSString *iconName;
@property (strong, nonatomic) NSString *weather;
@property (strong, nonatomic) NSString *city;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
