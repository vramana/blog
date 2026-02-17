+++
title = "Improving how I review code"
date = 2026-02-17T10:03:29+05:30
tags = []
draft = false
layout = "post"
+++

I spend a lot of time reviewing code. It's one of my core responsibilities.

<!--more-->

GitHub PRs leave much to be desired. They are slow and sometimes unresponsive. Have you ever had a long-running PR with a lot of comments? It's frustrating to go to outstanding comments. The GitHub UI just hides them. Stacking PRs is still not a thing. I know it's coming but even if it lands, I am not holding my breath for how it will perform. Github has shipped good performance improvements to Issues and PRs but will they continue to do so?

GitHub has always severely underinvested in its core product. This is turning into a frustration with GitHub as a platform but let's leave that rant aside.

I normally review code on github.dev instead of github.com since it's a pain to read surrounding code. github.dev has been a godsend. But the workflow is annoying. I have always craved for something better. I am building it. Here is how.

The best part about github.dev is the GitHub PR extension and an editor-like experience.

It can show you the list of files that have changed. You can go to any file and read the whole file or you can also read the file with just the diffs. You can search the whole codebase. This is really important because you are going back and forth between files.

So what's lacking? Speed. Hover to get type info. Go to references. Almost a full editor experience. Yes. I can use GitHub PR extension in VS Code. Compared to using neovim, github.com (browser), it adds another tool that I have to invoke just for code reviews.

I have tried that workflow for some time but I kept going back to GitHub web for PR reviews. It's the workflow with the least friction. I don't have to stop what I'm working on. I can simply open a PR. Add a few comments and close it. With local code reviews, I have to switch branches. Sometimes it's simply not worth the hassle to switch branches.

One more thing happened to me last year. I started using Jujutsu (jj) as my version control system (VCS) instead of Git. This was a huge change. I used Magit from emacs as my primary way to interface with Git. Because jj is so different, jj CLI is the best interface. I know enough jj to be productive and do my work. But it really changed the way I treat commits. I stopped thinking in terms of branches. Everything is very malleable. I can move around commits with ease. I can rebase to my heart's content. Merge conflicts don't stop the world. You can continue working on something else and come back to them.

There are a lot of tools that build on top of Git. But since I am no longer in the Git world, I can't use them. I don't have time to build my own tools. So I worked with what I had until now. Yes, here is where story introduces AI in my life.

Over the winter break, a lot has changed in the world of software engineering. Opus 4.5 and GPT 5.2 are being used to build really complex software. Timelines and expectations are being rewritten. The definition of being a productive engineer is changing. I realized it's time to keep my head down and build. My philosophy is you learn when you ship.

My company is also encouraging and pushing to rethink the workflows. As a person leading multiple teams, if I am not shipping, I don't know what the bottlenecks are and how to fix them. I can't influence the policymaking at my company. So, I started to ship. I shipped stuff leaning into AI for code generation but always relying on reviews to complement the process.

Agents can write a lot of code. Code generation is no longer a bottleneck at all. Code reviews are the new bottleneck now. That's how I turned my attention to code reviews. I have been experimenting with both Codex and Claude Code. The time I spend in the terminal has increased significantly.

I wondered, can I have a github.dev-like diff experience in my terminal? In Neovim. The answer is yes, there's already a [plugin](https://github.com/sindrets/diffview.nvim) for it. I have been using this plugin for the last six months to split commits in jj. But I never knew it already supported what I need. I can see the diff from the main branch to the latest commit of the PR. Since it's a real editor, I can do any of the stuff that would be possible with an LSP enabled editor i.e, go to definition, go to references etc.,

The plugin kind of works in jj repositories as well because it has an underlying Git folder. But I still want a cheap way to review PRs i.e, not switching branches. Here is where I started to look towards jj workspaces, which are very similar to Git worktrees. But if I try to use this plugin in a jj workspace, it will no longer work because there is no backing Git folder. In the past, I would have given up. I searched for jj support in the plugin, but the plugin didn't have any commits in the past two years.

The plugin supports Git and Mercurial. Adding jj should be quite straightforward. I opened Codex and gave it a few prompts on what I wanted, describing which jj commands should be invoked to get the diff. Within 15 minutes, I have a working version of the plugin that works in jj workspaces, and I could see the diffs.

It's mind-blowing that I can just do this now. I can just build my custom tools to fit my workflow. Using Codex, I developed a short command to easily check out any PR into a new jj workspace.

```
$ jjco {pr_number} -w

# Pseudo-code:

# 1. Look up branch name from pr_number
# 2. Do a git fetch to fetch all the latest branches on github
# 3. Create a new workspace with this branch
# 4. cd into the branch
```

Once I am inside that workspace, I can open up Neovim and checkout the diff from main. I am not writing anyone's branch name ever again :D

I can't write any comments directly on the diff. But I can live with that. I have a much better experience reading through the code. I have only been playing with this for a couple of days. Who knows? Maybe I'll add GitHub comments into my workflow through nvim. I don't need to wait for someone to write a plugin. I can write my own plugins, and it's very cheap to do so.

I never read a line of code that is generated by Codex for this plugin, but it's fine. It's not mission critical, it's not used by anyone. Even if it breaks, it's just for me, and that's okay.

jj also supports a neat feature whereby it automatically generates branch names from the current revision. Using this feature, I have entirely stopped creating branch names. I have developed a short command to copy the current branch name into my clipboard. I can write `gh pr create -H` and then paste the branch name. Fill in a few more details, and I open my PR from my terminal. I can watch GitHub Actions status from CLI. I feel very alive. Maybe with a little more effort, I can even make an agent completely open my PRs.

If you have read all the way to the end, I hope I gave you some more inspiration to write your own tools.
