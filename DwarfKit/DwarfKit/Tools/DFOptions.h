//
//  DFOptions.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#define DF_OPTIONS_ENABLE(mask, option)       ((mask) |= (option))
#define DF_OPTIONS_DISABLE(mask, option)      ((mask) &= (~(option)))
#define DF_OPTIONS_IS_ENABLED(mask, option)   ((mask) & (option))

#define DF_OPTIONS_SET(mask, option, enabled) \
({ \
   if (enabled) { \
      DF_OPTIONS_ENABLE(mask, option); \
   } else { \
      DF_OPTIONS_DISABLE(mask, option); \
   } \
})

#define DF_OPTIONS_STRING(mask) \
({ \
   NSMutableString *str = [NSMutableString string]; \
   for (NSInteger i = 0; i < (sizeof(mask) * 8) ; i++) { \
      [str insertString:((mask & (1 << i)) ? @"1" : @"0") atIndex:0]; \
   }  \
   str; \
}) \
