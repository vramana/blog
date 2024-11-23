+++
title = "Don't use Terraform for everything"
date = 2024-11-22T11:10:21+05:30
tags = [
  "terraform",
  "devops",
  "gcp"
]
draft = false
layout = "post"
+++

I have been using Terraform at work for close to 2 years.
I absolutely hated it at first, but later I made peace with it.
Now I have changed the overall direction of how we use Terraform at work.

<!--more-->

## First encounter

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
Whenever we tried to deploy the application, it would fail because some obscure GCP service was not enabled.
Raise a PR, get it reviewed, deploy it, and it will fail again.

Another cardinal sin we committed was, if I may call it that, storing Terraform state in a Git repository.
The merge conflicts were hell.
Thankfully, we have moved on to storing state in Google Cloud Storage.

Do you want to deploy a cloud function? Great!
Run terraform locally to create a zip file of the cloud function code and upload it to Google Cloud Storage.
Use this GCS bucket object resource in a Cloud Function's resource block.
Then, this Cloud Function will be deployed using Terraform.

Essentially, there are no automated deployments for our code.
Other teams in our company use automated deployments with GitHub Actions.
The difference is night and day.

## Making peace with Terraform

This was a huge step backward.
It felt like pure madness to me.
Death by a thousand paper cuts, or whatever you want to call it.
We are a startup, and our biggest advantage is shipping and iterating fast.
Here we are squandering our biggest advantage.

I know where my CTO is coming from.
Our infrastructure is not documented clearly, and the GCP console gives too many knobs and dials to configure.
It's a nightmare to debug and maintain.
We need to bring order to this chaos.
I have simplified the actual history a bit, but the pain is real.

I had a strong belief that we were using Terraform the wrong way.
So, I tried to learn Terraform multiple times, but I gave up every time.
Every tutorial starts with: "Let's learn how to create a private VPC subnet.".
All my interest is lost at this point.
I don't care, I want to deploy my cloud function.
I want to enable the services that I need.
How can I do this without tearing my hair out?

I learned the bare minimum that allowed me to create resources and manage them in Terraform files.
I discovered Terraform modules along the way, which helped me organize Terraform resources in a way that made sense.

As we rolled out Terraform to more projects, our Terraform setup became more and more complex.
Teams that had automated deployments did not adopt Terraform for deployments.
Only IAM roles and a few other resources were managed by Terraform.
This was mostly managed by our CTO and our DevOps engineer.

## Moving to a better way

Recently, our DevOps engineer left the company.
One morning, my CTO sent me the following message:

> I've been thinking of a new DevOps strategy since X is leaving. We need simpler approaches. Any ideas? You usually have good ones. 😛

Certainly, I have a lot of thoughts on how we can improve the current situation.

There are three ways we use Terraform.

1. Manage permissions for users and resources
2. Manage configurations for resources (think about databases, buckets, etc.)
3. Deploy code

I hate only the last part; the rest is fine.
I have said this earlier: as a startup, our biggest advantage is shipping and iterating fast.
We don't frequently make PRs to change points 1 and 2.

In my opinion, any resource that changes frequently should be kept out of Terraform.
Manual deployments are error-prone and time-consuming.
We should use automated deployments for code.
Terraform should not be used as a revision control system for deployments.

This, in turn, reduces the permissions given to developers (principle of least privilege).
This is another huge win.
We need contingency plans for when we need to deploy something manually.
But we don't need to do that often.

I had a long chat with my CTO about this.
In the end, I was able to convince him that we should not use Terraform for everything.
Our conclusion was that deployments and observability should be owned by the teams.
Rest should be managed through Terraform.

My CTO took this seriously and went to work.
We have completely automated deployments for a critical project :heart:.
Shell scripts using the gcloud CLI are used to deploy Cloud Functions, Dataflow pipelines, and more.

Maybe there are downsides to this approach.
We will know it in due course.


















