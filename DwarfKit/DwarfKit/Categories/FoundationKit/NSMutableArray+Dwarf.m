//
//  NSMutableArray+Dwarf.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "NSMutableArray+Dwarf.h"

static const void * DFRetainNoOp(CFAllocatorRef allocator, const void *value) { return value; }
static void DFReleaseNoOp(CFAllocatorRef allocator, const void *value) { }


@implementation NSMutableArray (Dwarf)

+ (instancetype)nonRetainingArray {
   CFArrayCallBacks callbacks = kCFTypeArrayCallBacks;
   callbacks.retain = DFRetainNoOp;
   callbacks.release = DFReleaseNoOp;
   return (__bridge_transfer NSMutableArray *)CFArrayCreateMutable(nil, 0, &callbacks);
}

@end
