/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/*! Produces 128-bit hash value using MD5 message-digest algorithm.
 @return String containing 128-bit hash value expressed as a 32 digit hexademical number.
 */
extern NSString *dwarf_md5(const char *data, uint32_t length);

/*! Produces 160-bit hash value using SHA-1 algorithm.
 @return String containing 160-bit hash value expressed as a 40 digit hexademical number.
 */
extern NSString *dwarf_sha1(const char *data, uint32_t length);

/*! Produces 224-bit hash value using SHA-224 algorithm.
 @return String containing 224-bit hash value expressed as a 56 digit hexademical number.
 */
extern NSString *dwarf_sha224(const char *data, uint32_t length);

/*! Produces 256-bit hash value using SHA-256 algorithm.
 @return String containing 256-bit hash value expressed as a 64 digit hexademical number.
 */
extern NSString *dwarf_sha256(const char *data, uint32_t length);

/*! Produces 384-bit hash value using SHA-384 algorithm.
 @return String containing 384-bit hash value expressed as a 96 digit hexademical number.
 */
extern NSString *dwarf_sha384(const char *data, uint32_t length);

/*! Produces 512-bit hash value using SHA-512 algorithm.
 @return String containing 512-bit hash value expressed as a 128 digit hexademical number.
 */
extern NSString *dwarf_sha512(const char *data, uint32_t length);