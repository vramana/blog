+++
title = "Balancing code review requests across my team using ChatGPT"
date = 2023-09-29T08:08:27+05:30
tags = [
    "programming",
    "code reviews",
    "pull requests",
    "reviews",
    "chatgpt",
    "github",
    "github actions"
]
draft = false
layout = "post"
+++

I manage the frontend team at Kisi. A new senior software engineer joined us in May.
He is totally up to speed, but we haven't assigned a lot of code review work to
him yet. I want to understand what is the distribution of code reviews and
balance them evenly across my team. You will see how I used ChatGPT as my coding assistant
to generate this data.

<!--more-->

## Problem

Let's dive a bit more deep into the problem statement and identify explicit goals
and non-goals.

We use GitHub at work. Therefore, we have access to pull request reviews data through its
API. We can write a program to summarize it and see the code reviews distribution. Problem solved?
Nope.

The numbers in code reviews distribution show a view of the situation. It doesn't explain
why does the problem exist in the first place or what situations led to those. If an engineer
is on a vacation or sick, they will do less code reviews. That's natural. There might be a
complicated PR and it took a lot of time for review and there was no time for others.
What else could be the cause?

If other engineers on the team
don't assign a new engineer as code reviewer, then also it will stay low. This is kind of
what's happening on my team. I felt it could be solved from both ends. PR authors and other reviewers
can assign/re-assign the review requests to the new engineer on team. The new engineer can ask
for more PR reviews to be assigned by checking his own review load. It's shows more ownership on
behalf of that engineer which is pretty nice.

Like sales quota, there is not going to be review quota that each engineer has to hit every week.
To me, in isolation these numbers don't mean anything. I don't want to put pressure on my team
using numbers that are devoid of all context. I want to find **outlier situations** using data
and act on them. Instead of looking at data for a single week, use the data generated over a
quarter to help myself and my team.

> There are three kinds of lies: lies, damn lies and statistics

### Solution

The easiest way to generate this data is through GitHub Actions. Since, actions have
a GitHub token, and we can read GitHub API using it. Here is the rough idea.

- Fetch all pull requests from last 3 months
- Filter the pull requests that were updated in the last week
- Fetch pull request reviews for each pull request that occurred in the last week
- Aggregate the review requests by reviewer, count reviews left and pull request count
- Print the aggregated data or push it to Slack/Discord

The path was clear, but I was feeling a bit lazy to write code 😅. So, I chose ChatGPT as my coding assistant.
After an hour of back and forth and testing the generated code, I have done it. Here is a link
to the [entire conversation](https://chat.openai.com/share/dc92fd96-676e-4600-b135-f0a842c04cc9).
I chose not to rely on external dependencies in script, so that the action can run as fast possible.

Code for the GitHub action itself

```yml
name: Repo Statastics
on:
  schedule:
    - cron: "0 0 * * 1"

permissions:
  pull-requests: read
  contents: read

env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Use Node.js
        uses: actions/setup-node@v3
        with:
          node-version: "18.x"

      - name: Fetch Review Statastics
        run: node scripts/reviewStats.js
```

Thanks for reading! Maybe I will write follow up after some months whether this was useful or not.
