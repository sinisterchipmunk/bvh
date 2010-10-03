#include "bvh.h"

VALUE rb_cBvh = Qnil;

void Init_bvh_c()
{
    rb_cBvh = rb_define_class("Bvh", rb_cObject);

    bvh_init_parser();
}
