+++
title = "Improving how I review code"
date = 2026-02-14T10:03:29+05:30
tags = []
draft = true
layout = "post"
+++

I spend a lot of time reviewing code. It's one of my core responsibilities. GitHub PRs leave much to be desired. They are slow. Sometimes unresponsive. Have you ever had a long running PR with a lot of comments? It sucks to go to outstanding comments. Github UI just hides them. Stacking PRs is still not a thing. I know it's coming but even if it lands, I am not holding my breath for how it will perform. Github team has shipped good performance improvements to Issues and PRs but will they continue to do so?

GitHub has always severely under invested in it's core product. This is turning into a frustration with GitHub as a platform but let's leave and come back to topic at hand.

<!--more-->

I normally review code on github.dev instead github.com since it's a pain to read surrounding code. github.dev has been god-send. But the workflow is annoying. I have always craved for something better. I think I got it. Here is how:

The best part about github.dev is the GitHub PR extension and full blown editor experience.

It can show you the list of files that have changed. You can go to any file and read the whole file or you can also read the file with just the diffs. You can search the whole codebase. This is really important because you are going back and forth between files.

So what's lacking? Speed. Hover to get type info. Go to references. Almost a full editor experience. Yes. I can use GitHub PR extension in VS Code. Apart using neovim, GitHub web, it adds another tool that I have to invoke just for code reviews.

I have tried that workflow for sometime but I kept going back to GitHub web for PR reviews. It's the workflow with least friction. I don't have to stop what I am working. I can simply open a PR. Add a few comments and close it. With local code reviews, I have to switch branches. Sometimes it's simply not worth the hassle to switch branches.

One more thing happened to me last year. I started using jujustu (jj) as my version control system (VCS) instead of Git. This was a huge change. I used Magit from emacs as my primary way to interface with Git. jj being just so different, jj cli is the best interface. I know enough jj to be productive and do my work. But it really changed the way I treat commits. I stopped worry about commits, branches. Everything is very malleable. I can move around commits with ease. I can rebase to my hearts content. Merge Conflicts don't stop the world. You can continue working on something else and come back to them.

There is a lot of tools that build on top of Git. But since I am not longer in the Git world, I can't participate in it. I don't have time to build my own tools. So I just work with what I have until now.

Yes, here is where story introduces the AI in my life.

Over the winter break, a lot has changed. Opus 4.5 and GPT 5.2 are being used to build real complex software. As I started work in January, it seems like there is a lot changing in the world of software engineering. Timelines and rxpectations are being re-written. The definition of being a productive engineer is changing. I realized it's time to keep my head down and build. My philosophy is you learn when you ship.

 My company is also encouraging and pushing to rethink the workflows. As a person leading multiple teams, if I am not shipping, I don't know what are the bottlenecks for my teammates. I can't influence the policy making at my company. So, I started to ship. I shipped stuff partially mixing AI tools and my own judgement and decision making.

Agents can write a lot of code. Code generation is no longer a bottleneck at all. Code reviews are the new bottleneck now. That's how I turned my attention to code reviews.

I wondered, can I have a GitHub-like diff experience in my terminal? In Neovim. The answer is yes, there's already a plugin for it, and I have been using this plugin for the last six months to split commits in jj. It supports exactly what I need. I can see the diff from the main branch to the latest commit on the pair, and I can jump across files, I can jump to any file. Since it's a real editor, I can do any of the stuff that would be possible with an LSP enabled editor i.e, Go to definition, Go to references etc.,

The plug-in kind of works in Jj repositories as well because it has an underlying Git folder. But I still want a cheap way to review PRs. Here is where I started to look towards Jj workspaces, which are very similar to Git worktree. But if I try to use this plugin in a Git worktree, it will no longer work because there is no Git. In the past, I would have given up and just went back to my usual ways. I searched for Jj support in the plugin, but the plugin didn't have any commits in the past two years.

I thought how hard it would it be to add support for Jj workspaces in this plugin. The plugin supports Git and Mercurial. Adding Jj should be Quite straightforward, I opened Codex and gave it prompts, describing how which JJ command should be invoked to get the diff. Within 15 minutes, I have a working version of the plug-in that works in JJ workspaces, and I could see the diffs.

It's mind-blowing that I can just do this now. I can just build my custom tools to fit my workflow. Using Codex, I developed a short command to easily check out any PR into a new Jj workspace. Once I am inside that workspace, I can open up VIM and I can open up the Diff view.

```
$ jjco {pr_number} -w
```

This command will use ghcli underneath it and it will find the branch for that PR number. It will locally do a git fetch, check out that branch, and then cd into that jj workspace for me.

I can't write any comments directly on the DefU, but still, I know exactly where things are, and I can live with that. I have much better experience reading through the code. I have only been playing with this for a couple of days. Who knows? Maybe I'll add GitHub comments into my workflow through VIM. I don't need to wait for someone to write a plugin. I can write my own plugins, and it's very cheap to do so.

I never read a line of code that is generated by Codex, but it's fine. It's not mission critical, it's not used by anyone. It's only if it breaks, it's just for me, and that's okay.


JJ supports a neat feature Whereby it automatically generates branch names or bookmarks in its terms from the revision. Using this feature, I have entirely stopped creating branch names. And I open my PRs from GitHub. Usually, it's a pain to copy this branch name and paste it. But now I have a command to automatically copy this branch name into my clipboard. I can write `gh pr create -H` and then paste the branch name. Fill in a few more details, and I open my PR from my terminal.

Maybe with a little more effort, I can even make an agent completely open my PR. 
