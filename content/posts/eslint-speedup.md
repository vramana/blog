+++
title = "How I thought I speed eslint but I didn't"
date = 2023-02-08T21:59:33+05:30
tags = ['eslint', 'build tools', 'performance']
draft = true
layout = "post"
+++


Inspired by [recent][speedup-1] [posts][speedup-2] of Marvin Hagemeister, I want to understand performace on build
tools and linters on my work codebase. Although I didn't ultimately find a speedup in eslint performance, I
degraded it, it was an interesting journey nonetheless. This is short version of my investigation.

<!--more-->


## The Setup

eslint has a simple way to profile which rules are taking the most of the time. Just prepend `TIMING=1`
environment variable before you eslint command. These are the results I got.

```sh
$ TIMING=1 eslint src
Rule                              | Time (ms) | Relative
:---------------------------------|----------:|--------:
import/no-cycle                   |   842.384 |    11.1%
import/order                      |   783.734 |    10.3%
import/no-relative-packages       |   522.584 |     6.9%
import/no-duplicates              |   453.092 |     6.0%
@typescript-eslint/no-unused-vars |   446.271 |     5.9%
import/no-self-import             |   435.846 |     5.7%
react/require-render-return       |   259.927 |     3.4%
react/jsx-fragments               |   222.337 |     2.9%
react/no-typos                    |   151.208 |     2.0%
react/prefer-exact-props          |   141.970 |     1.9%
```

It seems the slowest rules are from `eslint-plugin-import` plugin. At first, I didn't understand
why they are running, then I remembered they are probably running because we extend our eslint
configuration from AirBnB eslint config preset.

`import/no-cycle` is the slowest on the list so I started look at it's source code. I also
created a CPU Profile of eslint with the following command. And started exploring it in
[Speedscope](https://www.speedscope.app).

```sh
$ TIMING=1 node --cpu-prof node_modules/.bin/eslint src
```

This is the CPU Profile and I have narrowed it down to a function in the `import/no-cycle` code.

![](/eslint-before-cpu-profile.png)

A lot of spent time is the `resolve` function and inside resolve function a lot of time is being
spent in hashifyObject

![](/resolve.png)












[speedup-1]: https://marvinh.dev/blog/speeding-up-javascript-ecosystem/
[speedup-2]: https://marvinh.dev/blog/speeding-up-javascript-ecosystem-part-3/

