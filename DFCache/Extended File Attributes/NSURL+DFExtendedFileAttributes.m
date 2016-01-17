// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "NSURL+DFExtendedFileAttributes.h"
#import <sys/xattr.h>

@implementation NSURL (DFExtendedFileAttributes)

- (int)df_setExtendedAttributeValue:(id<NSCoding>)value forKey:(NSString *)key {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
    return [self df_setExtendedAttributeData:data forKey:key options:0];
}

- (int)df_setExtendedAttributeData:(NSData *)data forKey:(NSString *)key options:(int)options {
    int error = setxattr(self.path.fileSystemRepresentation, [key UTF8String], [data bytes], [data length], 0, options);
    return !error ? 0 : errno;
}

- (id)df_extendedAttributeValueForKey:(NSString *)key error:(int *)error {
    NSData *data = [self df_extendedAttributeDataForKey:key error:error options:0];
    return key ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
}

- (NSData *)df_extendedAttributeDataForKey:(NSString *)k error:(int *)error options:(int)options {
    const char *path = self.path.fileSystemRepresentation;
    const char *key = [k UTF8String];
    void *buffer;
    ssize_t size = getxattr(path, key, NULL, SIZE_T_MAX, 0, options);
    if (size == -1) {
        goto handle_error;
    }
    buffer = calloc(1, size);
    size = getxattr(path, key, buffer, size, 0, options);
    if (size == -1) {
        free(buffer);
        goto handle_error;
    }
    return [NSData dataWithBytesNoCopy:buffer length:size];
    
handle_error:
    if (error) {
        *error = errno;
    }
    return nil;
}

- (int)df_removeExtendedAttributeForKey:(NSString *)key {
    return [self df_removeExtendedAttributeForKey:key options:0];
}

- (int)df_removeExtendedAttributeForKey:(NSString *)key options:(int)options {
    int error = removexattr(self.path.fileSystemRepresentation, [key UTF8String], options);
    return !error ? 0 : errno;
}

- (NSArray *)df_extendedAttributesList:(int *)error {
    return [self df_extendedAttributesList:error options:0];
}

- (NSArray *)df_extendedAttributesList:(int *)error options:(int)options {
    const char *path = self.path.fileSystemRepresentation;
    char *buffer;
    ssize_t size = listxattr(path, NULL, SIZE_T_MAX, options);
    if (size == -1) {
        goto handle_error;
    }
    if (size == 0) {
        return nil;
    }
    buffer = calloc(1, size);
    size = listxattr(path, (void *)buffer, size, options);
    if (size == -1) {
        free(buffer);
        goto  handle_error;
    }
    if (size == 0) {
        free(buffer);
        return nil;
    }
    return [self _namesFromBuffer:buffer withSize:size freeWhenDone:YES];
    
handle_error:
    if (error) {
        *error = errno;
    }
    return nil;
}

- (NSArray *)_namesFromBuffer:(char *)buffer withSize:(ssize_t)size freeWhenDone:(BOOL)freeWhenDone {
    NSMutableArray *names = [NSMutableArray new];
    char *name_start = buffer;
    for (char *ptr = buffer; ptr < (buffer + size); ptr++) {
        if (*ptr == '\0') {
            NSString *name = [[NSString alloc] initWithUTF8String:name_start];
            [names addObject:name];
            name_start = ptr + 1;
        }
    }
    if (freeWhenDone) {
        free(buffer);
    }
    return names;
}

@end
