//
//  DFImageFetchManager.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/11/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageFetchManager.h"
#import "DFCache.h"


#pragma mark - _DFFetchWrapper -

@interface _DFFetchWrapper : NSObject

@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) DFImageFetchTask *task;
@property (nonatomic, strong) NSMutableArray *handlers;

- (id)initWithTask:(DFImageFetchTask *)task
          imageURL:(NSString *)imageURL
           handler:(DFImageFetchHandler *)handler;

- (void)prepareForReuse;

@end


@implementation _DFFetchWrapper

- (id)initWithTask:(DFImageFetchTask *)task
          imageURL:(NSString *)imageURL
           handler:(DFImageFetchHandler *)handler {
   if (self = [super init]) {
      _imageURL = imageURL;
      _task = task;
      _handlers = [NSMutableArray arrayWithObject:handler];
   }
   return self;
}


- (void)prepareForReuse {
   _imageURL = nil;
   _task = nil;
   [_handlers removeAllObjects];
}

@end



#pragma mark - MMImageFetchManager -

@implementation DFImageFetchManager {
   NSMutableDictionary *_wrappers;
   NSMutableArray *_reusableTasks;
   NSUInteger _maxReusableTaskCount;
}


+ (instancetype)shared {
   static DFImageFetchManager *shared = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      shared = [[self class] new];
      shared.cache = [[DFCache alloc] initWithName:@"df_shared_manager_cache"];
   });
   return shared;
}


- (id)initWithName:(NSString *)name {
   if (self = [super init]) {
      _name = name;
      _queue = [DFTaskQueue new];
      _wrappers = [NSMutableDictionary new];
      _reusableTasks = [NSMutableArray new];
      [self _setDefaults];
   }
   return self;
}


- (id)init {
   return [self initWithName:nil];
}


- (void)_setDefaults {
   _queue.maxConcurrentTaskCount = 3;
   _maxReusableTaskCount = 40;
}

#pragma mark - Fetching

- (DFImageFetchTask *)fetchImageWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler {
   if (imageURL == nil || handler == nil) {
      return nil;
   }
   
   _DFFetchWrapper *wrapper = [_wrappers objectForKey:imageURL];
   if (wrapper) {
      [wrapper.handlers addObject:handler];
      return wrapper.task;
   }
   else {
      DFImageFetchTask *task = [[DFImageFetchTask alloc] initWithURL:imageURL];
      task.cache = _cache;
      [task setCompletionBlock:^(DFTask *completedTask) {
         [self _handleTaskCompletion:(id)completedTask];
      }];
      
      _DFFetchWrapper *wrapper = [self _dequeueReusableWrapper];
      if (wrapper) {
         wrapper.task = task;
         wrapper.imageURL = imageURL;
         [wrapper.handlers addObject:handler];
      } else {
         wrapper = [[_DFFetchWrapper alloc] initWithTask:task imageURL:imageURL handler:handler];
      }
      [_wrappers setObject:wrapper forKey:imageURL];
      
      [_queue addTask:task];
      return task;
   }
}


- (void)cancelFetchingWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler {
   if (handler == nil || imageURL == nil) {
      return;
   }
   
   _DFFetchWrapper *wrapper = [_wrappers objectForKey:imageURL];
   if (wrapper == nil) {
      return;
   }
   
   [wrapper.handlers removeObject:handler];
   if (wrapper.handlers.count == 0 && ! wrapper.task.isExecuting) {
      [wrapper.task cancel];
      [wrapper.task setCompletionBlock:nil];
      [_wrappers removeObjectForKey:imageURL];
      [self _enqueueReusableWrapper:wrapper];
   }
}


- (void)prefetchImageWithURL:(NSString *)imageURL {
   [self fetchImageWithURL:imageURL handler:[DFImageFetchHandler new]];
}

#pragma mark - Reusing Tasks

- (_DFFetchWrapper *)_dequeueReusableWrapper {
   _DFFetchWrapper *wrapper;
   if (_reusableTasks.count > 0) {
      wrapper = [_reusableTasks lastObject];
      [_reusableTasks removeLastObject];
   }
   return wrapper;
}


- (void)_enqueueReusableWrapper:(_DFFetchWrapper *)wrapper {
   if (_reusableTasks.count < _maxReusableTaskCount) {
      [_reusableTasks addObject:wrapper];
      [wrapper prepareForReuse];
   }
}

#pragma mark - MMImageFetchTask Completion

- (void)_handleTaskCompletion:(DFImageFetchTask *)task {
   if (task.isCancelled) {
      return;
   }
   
   _DFFetchWrapper *wrapper = [_wrappers objectForKey:task.imageURL];
   
   // SUCCESS
   if (task.image) {
      for (DFImageFetchHandler *handler in wrapper.handlers) {
         if (handler.success) {
            handler.success(task.image, task.source);
         }
      }
   }
   
   // FAILURE
   else {
      for (DFImageFetchHandler *handler in wrapper.handlers) {
         if (handler.failure) {
            handler.failure(task.error);
         }
      }
   }
   
   [_wrappers removeObjectForKey:task.imageURL];
   [self _enqueueReusableWrapper:wrapper];
}

@end
