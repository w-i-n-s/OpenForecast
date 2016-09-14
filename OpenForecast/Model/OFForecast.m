//
//  OFForecast.m
//  OpenForecast
//
//  Created by Sergey Vinogradov on 12.09.16.
//  Copyright © 2016 forecaster. All rights reserved.
//

#import "OFForecast.h"

@implementation OFForecast

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    

    if (self = [super init]) {
        self.idString = dictionary[@"id"];
        self.city     = dictionary[@"name"];
        
        NSDictionary *weatherDict = dictionary[@"weather"][0];
        self.iconName = weatherDict[@"icon"];
        self.weather  = weatherDict[@"description"];
    }
    
    return self;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@; ID = %@; city = %@; weather = %@;", [super description], self.idString, self.city, self.weather];
}

@end
