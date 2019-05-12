+++
title= "Rust Debugging Paper Cuts"
published = true
url = "/2018/09/30/rust-debugging"
date= "2018-09-20"
+++

These are some of the pain points I have felt while trying debug Rust code in GDB. Some of them
may be already solved problems but I don't know the solution yet.

<!--more-->

**Don't step in to standard library source code**

This is a major issue step accidentally into rust std source code. Then do `next` command for few times
till get out of it. More generally it would be nice to have command that will omit stepping into a few
selected crates.

While writing this post, I discovered `finish` which steps out the current stackframe. That is a neat
workaround for now.

**Enable gdb history by default for rust-gdb**

I thought it's really weird that gdb does have history of commands of the last run. After typing the same
commands again and again, I simply googled and found that gdb infact has history but it's just disabled
by default.

**Inspect return value of functions with expression as return value**

I am usually at the end of the function defintion but I don't know how I can print the return value of the function.
According to SO, again `finish` comes to the rescue. When you run it, it also gives the values returned by the
last stack frame. The problem with this approach is we can't look at the locals variables and return value at the same time

**The try operator dance**

When the result of expression with try operator fails, then as you run `next` command first you jump to
`}` at the end of function and then back to the `?` mark and then again back `}`.
