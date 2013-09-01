//
//  DwarfDefines.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 14.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#define DWARF_UNUSED        __attribute__((unused))

#if OS_OBJECT_USE_OBJC
#define DWARF_DISPATCH_RETAIN(object)
#define DWARF_DISPATCH_RELEASE(object)
#else
#define DWARF_DISPATCH_RETAIN(object) (dispatch_retain(object))
#define DWARF_DISPATCH_RELEASE(object) (dispatch_release(object))
#endif