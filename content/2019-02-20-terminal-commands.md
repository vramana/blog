+++
title= "Most used Terminal Commands"
published = true
url = "/2019/02/20/terminal-commands"
date= "2019-02-20"
++++

Inspired by [this article][wincent-article], I set out to find which are my most used commands.

```
→ history 0 $HISTSIZE | awk '{a[$2]++}END{for(i in a){print a[i] " " i}}' | sort -rn | head

1520 git
616 cd
611 yarn
604 sudo
601 curl
349 rm
264 docker
232 heroku
220 npm
176 cat
```

It's a bit surprising the to see git at the top of the list given my heavy usage of [magit][magit]. It
would be nice to check what git subcommands I use the most. When I am working on any work related stuff.
I tend to stick to magit. It's a bit surprise to not find `v` (my alias for neovim) in here. I need to
debug this a bit more. `cat` is another surprise. I don't know when I used cat that much.


It would be nice to see how my terminal command usages changes with month and how many commands I perform
in a day and month. Silly things but I feel quite excited to do some more analysis this and generate graphs.


[wincent-article]: https://wincent.com/blog/frequently-used-terminal-commands
[magit]: https://magit.vc
