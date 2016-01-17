// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*! Extended attributes extend the basic attributes associated with files and directories in the file system. They are stored as name:data pairs associated with file system objects (files, directories, symlinks, etc). See setxattr(2).
 */
@interface NSURL (DFExtendedFileAttributes)

/*! Sets encoded attribute value for the given key.
 @return 0 on success or error code on failure. For the list of errors see setxattr(2).
 */
- (int)df_setExtendedAttributeValue:(id<NSCoding>)value forKey:(NSString *)key;

/*! Associates key and data together as an attribute of the file.
 @discussion Follows symbolic links. Creates attribute if it doesn't exist. Replaces attribute if it already exists.
 @param data Attribute data.
 @param options For the list of available options see setxattr(2).
 @return 0 on success or error code on failure. For the list of errors see setxattr(2).
 */
- (int)df_setExtendedAttributeData:(NSData *)data forKey:(NSString *)key options:(int)options;

/*! Retrieves decoded attribute value for given key.
 @param error Error code is set on failure. You may specify NULL for this parameter. For the list of errors see getxattr(2).
 @throws Raises an NSInvalidArgumentException if data is not a valid archive.
 */
- (id)df_extendedAttributeValueForKey:(NSString *)key error:(int *__nullable)error;

/*! Retrieves data from the extended attribute identified by the given key.
 @param error Error code is set on failure. You may specify NULL for this parameter. For the list of errors see getxattr(2).
 @param options For the list of available options see getxattr(2).
 */
- (nullable NSData *)df_extendedAttributeDataForKey:(NSString *)key error:(int *__nullable)error options:(int)options;

/*! Removes the extended attribute for the given key.
 @return 0 on success or error code on failure. For the list of errors see removexattr(2).
 */
- (int)df_removeExtendedAttributeForKey:(NSString *)key;

/*! Removes the extended attribute for the given key.
 @param options For the list of available options see removexattr(2).
 @return 0 on success or error code on failure. For the list of errors see removexattr(2).
 */
- (int)df_removeExtendedAttributeForKey:(NSString *)key options:(int)options;

/*! Retrieves a list of names of extended attributes.
 @param error Error code is set on failure. You may specify NULL for this parameter. For the list of errors see listxattr(2).
 */
- (nullable NSArray *)df_extendedAttributesList:(int *__nullable)error;

/*! Retrieves a list of names of extended attributes.
 @param error Error code is set on failure. You may specify NULL for this parameter. For the list of errors see listxattr(2).
 @param options For the list of available options see listxattr(2).
 */
- (nullable NSArray *)df_extendedAttributesList:(int *__nullable)error options:(int)options;

@end

NS_ASSUME_NONNULL_END
