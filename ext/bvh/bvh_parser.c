#include "bvh.h"

static VALUE rb_fParseChannelData(VALUE self, VALUE channels, VALUE bone);

static VALUE rb_cBvhParser = Qnil;
static VALUE rb_cMotion = Qnil;
static VALUE rb_cChannelData = Qnil;

void bvh_init_parser()
{
    rb_cBvhParser = rb_define_class_under(rb_cBvh, "Parser", rb_cObject);
    rb_cMotion = rb_define_class_under(rb_cBvh, "Motion", rb_cObject);
    rb_cChannelData = rb_define_class_under(rb_cMotion, "ChannelData", rb_cHash);

    rb_define_private_method(rb_cBvhParser, "channel_data", rb_fParseChannelData, 2);
}

static void debug(const char *text)
{
    rb_funcall(rb_cObject, rb_intern("puts"), rb_str_new2(text));
}

static VALUE rb_fParseChannelData(VALUE self, VALUE channels, VALUE bone)
{
    char buf[256];
    
    VALUE data;
    //struct RArray *rchannels, *joints;
    VALUE rchannels, joints;
    long i;
    VALUE channel, joint;
    VALUE r = rb_ary_new();

    // return [] unless bone.respond_to? :channels
    if (!rb_respond_to(bone, rb_intern("channels")))
        return r;

    // data = Bvh::Motion::ChannelData.new(bone)
    data = rb_funcall(rb_cChannelData, rb_intern("new"), 1, bone);

    // bone.channels.each { |channel| data[channel] = channels.shift }
    //rchannels = RARRAY(rb_funcall(bone, rb_intern("channels"), 0));
    rchannels = rb_funcall(bone, rb_intern("channels"), 0);
    for (i = 0; i < RARRAY_LEN(rchannels); i++)
    {
        channel = *(RARRAY_PTR(rchannels)+i);
        //... data[channel] = channels.shift ...
        rb_hash_aset(data, channel, rb_funcall(channels, rb_intern("shift"), 0));
    }

    // r = [data]
    rb_ary_push(r, data);

    // bone.joints.each { |joint| r.concat channel_data(channels, joint) }
    joints = rb_funcall(bone, rb_intern("joints"), 0);
    for (i = 0; i < RARRAY_LEN(joints); i++)
    {
        joint = *(RARRAY_PTR(joints)+i);
        // ... r.concat(channel_data(channels, joint)) ...
        rb_funcall(r, rb_intern("concat"), 1, rb_fParseChannelData(self, channels, joint));
    }

    // r
    return r;
}
