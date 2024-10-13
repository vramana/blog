+++
title = "How I decreased a background sync job time from 3 hours to 1 hour"
date = 2024-10-14T01:11:50+05:30
tags = [
  "javascript",
  "typescript",
  "cloud functions"
]
draft = false
layout = "post"
+++

<!--more-->

### Context

I am working on a background job that synchronizes users from an external API into Kisi's API (Kisi is where I work).
There is one customer whose size is 1000x the average size of the other customer.
The users are organized into groups.
Instead of a single job that synchronizes all users, we run sync jobs per group.

The jobs are executed using Google Cloud Pub/Sub and Cloud Functions.
Cloud Function background jobs have a time limit of 9 mins.
Since there is a time limit, we choose to run sync one group per job.
One advantage is if there is failure to sync a job, only that group will be retried.

The sync job algorithm is as follows:

1. Fetch all user data from Kisi API
2. Fetch a page of users from the group
3. Sync users from the page
4. If there are more pages left, go to step 2 to fetch the next page

The actual algorithm is a bit more involved.
The sync job algorithm looks obvious in its design.
There are a lot of design decisions that went into it.
Those details are irrelevant to this post.

The entire job for this customer takes about 3 hours when we run each job sequentially.
Duh! Why not parallelize it?
It was running in parallelly when first put it into production.
Then we ran into rate limits with Kisi API and the job would never finish.
So I **painstakingly** made these jobs to run sequentially.
The process of making sequential may be worth another post.
It dramatically increased the reliability and rate limit errors are gone.

Since there is no parallelism magic wand on the table, we must optimize the sync jobs themselves.

### Observations from production

First step before you do any optimization is to measure where your programs spends time.

Fetching data from Kisi API takes 4 mins and rest of syncing process takes about 1 min.
It might take longer to sync if there is a lot of data to be synced.

I didn't foresee that fetching data from API is where the bottleneck will be.
It's hard to fix as there is no work around available other fetching all the data that's necessary.

### Key Insights

The data we fetch for every job from Kisi API is the same.
It will not change much during between jobs.
Only the source of truth needs to be as fresh as possible when we sync.
We can account for staleness of any data on Kisi API side.
I am hand-waving this part for the sake of brevity.

My key insight is we still have 4 mins left in the job.
I can speculatively execute more jobs reusing the same data in the remaining time.

Here is the pseudocode

```js

let groups = [...]; // Som

let totalTime = 500 * 1000; // Five hundred seconds
let minimumTimeRemaining = 100 * 1000 // Hundred seconds

let start = Date.now()

let kisiUsers = await fetchKisiUsers()

let duration = Date.now() - start;

let remainingDuration = totalTime - duration;
let groupIndex = 0;

while (remainingDuration < minimumTimeRemaining && groupIndex < groups.length) {
    start = Date.now();
    const group = groups[groupIndex];
    await syncUsers(kisiUsers, group);
    duration = Date.now() - start;

    remainingDuration -= duration;
    groupIndex++;
}
```

We keep track of remaining time and check if we have any more groups to sync.
We don't use the full 9 mins duration available to us on purpose.
As there might be lingering promises that might go on to resolved after we cross 500 seconds.
So we need to leave sufficient headroom to complete the job cleanly.

It's a trivial optimization. But it saves a lot of time.

In my first test run, I was able to sync 5 groups in a single job.
This completely validated my approach.

### Is it worth it?

Usually developer time is more expensive than CPU time.
So it's always worth asking a question if this is worth it.
It took me roughly 2 hours to do this.
It's not a lot of time.
In my first pass, I forgot to add the index bounds check.
Once I noticed the error in production, I was able to fix it quickly.

I know that this customer will quadruple their groups in the next 2 months.
12 hours for a sync job can actually cause problems for our customer.
The future savings are much larger in this case.
So yeah, it's totally worth it.

> This is a trivial optimization to write about.
>
> I haven't written a blog post in long time.
> This gives me an opportunity to write about something that created meaningful impact at work.



