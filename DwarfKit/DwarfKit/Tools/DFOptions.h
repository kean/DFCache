/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
