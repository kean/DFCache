//
//  DFValueTransformer.h
//  DFCache
//
//  Created by Alexander Grebenyuk on 12/17/14.
//  Copyright (c) 2014 com.github.kean. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol DFValueTransforming <NSObject>

- (NSData *)transformedValue:(id)value;
- (id)reverseTransfomedValue:(NSData *)data;

@optional
/*! The cost that is associated with the value in the memory cache.
 */
- (NSUInteger)costForValue:(id)value;

@end


@interface DFValueTransformer : NSObject <DFValueTransforming>



@end
