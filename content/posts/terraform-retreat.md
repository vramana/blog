+++
title = "A retreat from Terraform for everything"
date = 2024-11-22T11:10:21+05:30
tags = []
draft = true
layout = "post"
+++

I have been using Terraform at work for close to 2 years.
I absolutely hated it at first, but later I made peace with it.
Now I have changed the overall direction of how we use Terraform at work.

<!--more-->

## Background / First encounter

At work, we use Google Cloud Platform (GCP) for our infrastructure.
Engineers are assigned IAM roles based on their seniority to manage resources in GCP.
We would configure the resources via the GCP Console.

One day, our CTO told us we had to track all new resources in GCP using Terraform.
We have to submit a pull request describing the new resources in Terraform.
The changes would be reviewed and applied by our DevOps engineer or our CTO.
Everyone on my team has viewer permissions, so we can't bypass the review process 😅

At the same time, we were developing a new application from scratch.
We had a staging environment where the application had already been deployed.
It was ready to be deployed in production.

It took us 2 or 3 days to deploy this application to production.
It was the most miserable experience I have ever had at work.
We would try to deploy the application, it would fail with some obscure GCP service not being enabled.
Raise a PR, get it reviewed, deploy it, it would fail again.

It felt like pure madness to me.
We are a startup, and our biggest advantage is shipping and iterating fast.
Here we are squandering our biggest advantage.


