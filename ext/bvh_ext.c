#include "bvh_ext.h"

VALUE rb_cBvh = Qnil;

void Init_bvh_ext()
{
    rb_cBvh = rb_define_class("Bvh", rb_cObject);

    bvh_init_parser();
}
