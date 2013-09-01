//
//  DFObjCExtenstions.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//


#define safe_cast(TYPE, object) \
({ \
   TYPE *dyn_cast_object = (TYPE*)(object); \
   [dyn_cast_object isKindOfClass:[TYPE class]] ? dyn_cast_object : nil; \
})
