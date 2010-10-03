#ifndef BVH_EXT_H
#define BVH_EXT_H

#include "ruby.h"

#ifndef RARRAY_PTR
#define RARRAY_PTR(x) RArray(x)->ptr
#endif

#ifndef RARRAY_LEN
#define RARRAY_LEN(x) RArray(x)->len
#endif

extern void bvh_init_parser();

extern VALUE rb_cBvh;

#endif//BVH_EXT_H
