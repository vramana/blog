+++
title= "Week 31, 2020 Update"
date= 2020-08-10T18:28:57+05:30
tags = []
published = true
layout = "post"

+++

<!--more-->


I want to start writing weekly updates and track my progress. Hence the blog post.

- Started reading pacman source and translating it into rust. Feeling okay-ish
at reading C code. For now the rust nothing but a bunch of skeletons files.

- I also translated rpm's version comparision algorithm from C to Rust but it's
not idiomatic Rust at all. Also I had to use libc's `strcmp` function. Need to
port it rust and remove the `unsafe` code block.

