+++
title = "Hello World Scheme"
date = 2023-06-15T00:40:03+05:30
tags = ["scheme", "chibi-scheme"]
layout = "post"
+++

Recently, I wanted to learn the Scheme language. Let's see how to print "Hello World" using [chibi-scheme](http://synthcode.com/wiki/chibi-scheme).

<!--more-->

I wanted to use the fastest Scheme compiler because, why not?  According to [awesome-scheme](https://github.com/schemedoc/awesome-scheme), it's [Chez scheme](https://cisco.github.io/ChezScheme/)[^1].
Chez Scheme doesn't yet support ARM based Macs. So, I picked chibi-scheme as my scheme compiler.
The [documentation](http://synthcode.com/scheme/chibi/) is so sparse that there is not even "Hello World" example.

I had to look through the source code of chibi-Scheme on [its github repository](https://github.com/ashinn/chibi-scheme/) to
cobble together our "Hello World" example.


```scheme
; hello-world.scm

(import (Scheme base) (scheme write))

(display "Hello World!")
(newline)
```

You can the file as `chibi-Scheme hello-world.scm`. You can use either `.scm` or `.ss` as scheme file extensions.


### Why scheme?

I've wanted to experiment with Lisp-like language for a lot of time. I feel I broke through my mental
barrier to write Lisp sometime ago. So I am just trying out Scheme now. May be I'll switch to Racket
or Clojure after while, but for now, I am starting my journey with Scheme.

Currently I am working through [The Little Schemer](https://mitpress.mit.edu/9780262560993/the-little-schemer/) book.
It's quite a dry book. but it's full of code examples. They teach Scheme by making you write lots of little programs.
Since I have experience with functional programming language likes Haskell and Scala, understanding recursion
has been easy so far.


