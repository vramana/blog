---
layout: post
title: Too many broken efforts, let's unite
published: false
---

A little more than 2 weeks ago @vjuex posted a [challenge][challenge] to create    best prototyping javascript tool on his blog. It spurred a plethora of new projects/tools which address the posted challenge. A day later, @erricclemmons wrote an blog post titled [Javascript Fatigue][fatigue], which kind of sums up the problem and offers some solutions.

I was watching all this happening from the sidelines _aka_ twitter. I have felt similar pain many times. Even today when I want to try out something new I clone @dan_abramov's react-transform-boilerplate and setup everything from scratch. This was partly because I have been burned by a complex boilerplate and I couldn't understand why certain things are setup in the certain way. There was very little documentation and after a lot of frustration not being able to understand, I retreated to react-transform-boilerplate which I knew already how to use.

My first thought after these blog posts was "Why are we fighting tools with more tools? Shouldn't we fight them with more documentation and tutorials ?". Of course, this probably only solves part of the problem. I will talk about the other part a little later. I think this is the more important part that many people seems to not care so much about. Even if you have made the most amazing prototyping tool, it's users also need the official documentation and tutorials to use the underlying tools/libraries.

Services like egghead and Frontend Masters help a little but I don't think they are never a replacement for official documentation. Many people try to write blog posts and even books to fill this gap but they can quickly become outdated or explain things that reader doesn't really want to know. If somebody's blog post on a tutorial is outdated, even if want to update it I can't update it because sometimes it is on platform like medium, wordpress, etc., or even the blog is on github I personally would hold back about how much value it may have or the author may want to preserve it as it's written which I think is totally reasonable. But if it was official documentation or tutorial, most probably somebody will reported issue and somebody else may fix the issue once it's reported. The thing I want to say is official documentation is more maintainable than the others. I am not saying stop writing blogs or books etc., I know that they are very important. In fact, when I try to learn a new library/language, I often learn that from blog posts but when I have problem I refer to official documentation. So, please put some efforts into making the official documentation a bit better. I am putting my efforts as well I have included them at the end if you want to read or get motivated to so.     

Now let's talk about the other problem everybody is talking about. Since react is un-opinionated, you have a lot of freedom to make choices and making these choices every single time for a new project has become a pain (a tl;dr version). @vjuex was retweeting all these new projects which are coming up with innovative ideas to make the best JS prototyping tool. Among these, a few people are making cli apps that would make prototyping easier and some of these projects predate the challenge. After looking at a few of them, I felt that there are lots of individual efforts that were supported by people that believed in the project. I couldn't find one single project that trumped all others by a mile. Most of them have common functionality, only different in few design decisions. So, there is a lot of duplication in efforts. I wanted these projects to merge into single project and produce a higher quality work. But I never dared to write an issue due to multiple reasons.

Last week while I was idling on Reactiflux chat. I found a guy who was requesting a new channel for feedback on his new generator cli app. I tried to reason with guy to not work on a project all over again and tried to convince him to file an issue in one of the existing cli app and wait for the response of the repo's owner. If he is dissatisfied with the response, then do his own thing is what I told him. But he replied to me saying that it is the problem with JS community and everybody does their own thing. I said look at ember they make common decisions and stuff. He told ya, but it is the problem with JS community etc., The conversation went on and I tried my best to convince him but I couldn't. I was little sad that here goes some more efforts into the ocean of duplication.

So, what now ? is the question that has been bothering me for the past week. I have solution that may work.









[challenge]: http://blog.vjeux.com/2015/javascript/challenge-best-javascript-setup-for-quick-prototyping.html
[fatigue]: https://medium.com/@ericclemmons/javascript-fatigue-48d4011b6fc4
