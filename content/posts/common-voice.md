+++
title = "My journey self-hosting common-voice! What a wild ride!"
date = 2024-02-04T17:56:23+05:30
tags = [
    "docker",
    "javascript",
    "node",
    "react",
    "nginx"
]
draft = false
layout = "post"
+++

My friend Ranjith asked me if I can help out implementing an alternate authentication system for Common Voice.
Common Voice is a platform for collecting voice dataset for languages other than English.
[Swecha](https://swecha.org), a local organization, wanted to collect voice samples for my native language Telugu through
their own self-hosted version of Common Voice.
They will use voice sample to train LLM models.

It sounded like nice challenge and a good cause.
So, I agreed and went down a deep rabbit hole.
I will write down all things I encountered as I tried to self-host this application.

<!--more-->

## Problem

Common Voice uses Auth0 as it's authentication platform.
Auth0 has a limit for number of free users.
The expected users of the self-hosted instance to be at least 3x the provided free limit.

My friend asked if I can look into any authentication system like LDAP or [Keycloak](https://www.keycloak.org/).
My first reaction was like _What? Why?_
Why do you need any authentication platform when you have a bunch of platforms that already support OAuth?
I told him I will see if I can integrate the application with either their self-hosted GitLab or Mattermost instance.

I browsed through common-voice repository to take a look at how hard it would be change authentication platform.
It's an express server with passport.js handling the authentication strategy.
This is a pretty good sign since if I find GitLab passport strategy changing and testing it would be pretty straight forward.
After a few minutes of googling and reading through passport.js website, I landed on passport-gitlab2.

Perfect! It's a solvable problem without much effort.

## DX Hell

There is a docker-compose.yaml file in the repository.
Good sign, I can hit `docker compose up` and focus on solving the problem.
_Nope, not so fast_.
Running `docker-compose up` fails.
The mysql docker image version used by the project doesn't have ARM64 image for macOS.
I read through their documentation for development it suggests using compatible mariadb version.

Now I have the application running locally.
How do I make the changes and see them?

I don't use either docker or docker compose for development regularly, but I have bits and pieces of knowledge.
Long way of saying I am docker noob.
I have experience with use VS Code DevContainers.
Nothing of that sort is configured for this project.

I thought I would use VS Code to develop from within the container environment.
_Nope!_ You can't login into this container permission denied!
I tried to open a bash shell in the same container by using `docker exec`.
It's the same result again.

```dockerfile
# Prepare for nonroot user
RUN groupadd -g $GID app; \
    useradd -g $GID -u $UID -m -d /code -s /usr/sbin/nologin app
```

I found these suspicious lines.
Okay! **Deep breath!**
All I want to do is make some changes and see how they work.
The documentation is scarce.

Do I have `docker compose up` and `docker compose down` every time I make change?
It takes like 4 minutes to build the containers from scratch.
**My heart screamed in agony**.
There must be a better way.

I remembered that volumes in docker allows share files between host and container.
I tried to understand how the build commands are configured in `package.json`.
They are configured with watch mode for `tsc` and `webpack`.

May be, just may be, I can make change in my editor locally and changes are reflected automatically.
Yep! I can confirm it by checking logs in docker compose.

All of this is my inexperience working with docker & docker-compose.
Nothing to do with project.
But on the bright side, I will not run into these problems again.

Adding GitLab as the authentication provider was pretty easy after that.

- Install the relevant package `passport-gitlab2`
- Comment out the Auth0 passport strategy lines
- Copy sample code from `passport-gitlab2`
- Add a few environment variables
- Copy the configuration for a sample OAuth application and place them in .env file

That's it! I am able to log in to the application with GitLab.

## A bigger and interesting challenge

Once I informed my friend that I have successfully completed the task.
He was super happy and told me that he will assign someone else to look into scaling issues with the app.
Apparently the app crashes if 50 users are using it concurrently.

**Scaling issues**, that sounded like music to my ears.
I don't encounter much scaling issues in my day job.
I want a piece of that action.
Performance optimization is topic close to my heart.

I asked him if I can help him on the issue, he said sure.

He shared me access to AWS EC2 instance where they have already hosted the application.
They configured domain and all the other stuff too.
Since I have my GitLab patch ready, I thought I would tweak the application a little and get to the problem.

**Wrong!**

I am tried to log in to the application and nothing worked.
More issues to the fact that I did not understand how docker & docker-compose works.
Some of the issues are with the configuration setup by the engineer who set it up.
There were already some changes made to the code at the time of self-hosting.
None of them are documented properly.

I don't have the energy to write all the issues I encountered.
I wasted an entire afternoon trying to make things work but nothing worked.

So, that brings me to this weekend where I tried to solve all the problems I encountered step by step.

## Self-hosting Adventure

This is my XY problem now.
I want to solve performance issue, but I am stuck with solving self-hosting issue.
Now let's dive into the title of blog post. _Haha, haha_

> Yes, After 900+ words I am writing about the title of this blog post.

I have put some music and started working the problem.

I rebased my patch on the latest commit of the main branch.
`git reset --hard` the repo on the EC2 instance.
I did `docker compose up`.

Before I go any further, we are going to take a little detour.

I needed to improve the EC2 instance shell.
I am running a small subset of commands repeatedly, and I don't want to type them again and again.
[atuin](https://atuin.sh/) is literally magical at improving this experience.
I have installed it and configured it in `.bashrc`. Imported all the history by running `atuin import auto`.

_Problem solved? Nope_
`atuin` doesn't save my commands into its history.
`bash` seems to hijack the history.
I tried reading relevant github issues where other people complained about the same issue and experiment with `.bashrc` a little.
I just could not solve it.

Chuck it. I am going to install `zsh` and call it day.
It worked on the first try.
The default prompt was a bit too ugly for me.
So, I also added [Starship](https://starship.rs/) for a good-looking terminal prompt.
Now back to the main story.

### Oh no, Docker, not you again!

I did all my development on my MacBook Air.
`docker compose up` ran fine.
When I ran the same command on EC2 Ubuntu instance, the containers were built but refused to start.
The problem was incorrect permissions for node_modules when `npm` was running a command.
Permission denied.
Remember the few lines I mentioned above, they strike again.

I stripped all the permission related stuff from Dockerfiles and started one container at a time.
Everything works!

I noticed something werd that's causing huge build times.

`bundler/Dockerfile` contains the following lines

```dockerfile
# Install dependencies
RUN npm ci

COPY --chown=node ./ ./

RUN npm run build
```

`docker-compose.yml` contains the following lines

```yaml
bundler:
  build:
    context: ./bundler
    dockerfile: Dockerfile
  container_name: bundler
  links:
    - db
    - redis
    - storage
  volumes:
    - ./bundler:/home/node/code
  networks:
    - voice-web
  ports:
    - 9001:9001
  command: bash -c "npm ci && npm run build && npm start"
```

Why are `npm ci` & `npm run build` included multiples times?
Installing all the dependencies and copying them Docker build context.
Also, mounting a volume on the same path.
Maybe it's for the ease of contributors who like me are poor at docker.
Always create an up-to date environment by doing them everywhere.
I just don't understand this madness.

I wrote a separate docker-compose file, mostly mirroring the original removing this mad/rad strategy.
Now I had faster builds.

### Content-Security-Policy

When I run the application in production mode, the application shows a black screen in the browser.
Reason? CSP is not configured correctly.
A bunch hard-coded SHA sums are added for script tags sent in the index.html.
The easiest solution to this problem for now is change the header to `Content-Security-Policy-Report-Only`.

I am not shipping this production. So it's okay. No harm done yet!
Why the hell SHA sums are hard coded into the source code?
Well, I did the same thing in an app I maintain.
It's the path of least work.
I sympathize with who ever did this.
It must have been revolting to do this, but it had to be done.

I can open the web application in browser.
I tried to log in to the application, and it doesn't work again.
_Sigh!_

### Hack it, till it works!

I switched to development mode, and this time I can log in to the application.
_Phew!_ I can save my profile and browse the application in signed in state.

Just one problem, I can't add my native language to list of languages I want to contribute.
Only Indonesian was available for some reason.
Till now, I haven't read anything specific relevant to actual application.

I inspect the requests in DevTools Network panel and I find the relevant request.

```json
{
  "id": 172,
  "name": "te",
  "target_sentence_count": 5000,
  "native_name": "తెలుగు",
  "is_contributable": 0,
  "is_translated": 1,
  "text_direction": "LTR"
}
```

Now I grep (rg) my way in the code base and to find the relevant file using `is_contributable`.
`server/src/lib/model/db/import-locales.ts` is what I was looking for.

After spending some time to understanding it, I understood that 5000 short sentences in Telugu.
But I don't have them at had.
The repository thankfully has 250+ sentences.

Instead of relying upon any code changes, I can hack the database and change the relevant columns.
I changed `is_contributable` to 1 and `target_sentence_count` to 200.
I went to profile page and checked again.
_Nope!_ Telugu still doesn't appear as a contributable language.

There is another additional check, there has to 200 sentences (with the updated limit) in the sentences table.
There is not much documentation on how to import sentences into the documentation.
Nothing in GitHub issues as well.
I found a [file](https://github.com/vramana/common-voice/blob/gitlab/server/src/lib/model/db/import-sentences.ts) that can import sentences into the database.
But strangely, this file is not used anywhere in the project.

It exports a single function.

```js
export async function importSentences(pool: any) {
  // ...
}
```

All it needs is a database pool instance. No problemo.
I added the following lines.

```js
getMySQLInstance()
  .getPool()
  .then(importSentences)
  .then(() => getMySQLInstance().endConnection());
```

It started to import a bazillion locales.
The repository has huge corpus of text.
I don't have time for all of that, so I sneaked in the following [line](https://github.com/vramana/common-voice/blob/gitlab/server/src/lib/model/db/import-sentences.ts#L158)

```js
    .filter(name => name === 'te')
```

Only import Telugu sentences and it was quick.
Telugu now shows up as a contributable language. Hooray!!

### Production Hell

Now it's time to face my nightmare again.
Production environment of application doesn't send the session cookie upon login success.
But why? Why is production broken in such a bizzare manner?
Do you have any guesses?

I, metaphorically, rolled up my sleeves and started reading the source of `passpost-gitlab2`.
Maybe it has a bug, I don't know.
I searched for the code which was setting the cookie.

There is nothing here, so I move one layer down `passport-oauth2`.
There is nothing here as well, so I move one layer down `passport`.
There is nothing here as well, so I move one layer down `express-session`.

There is a lot of code and I found out where session cookie is being set from.
I still don't have any idea why is it not working.
Luckily for me there a lot of [debug](https://npm.im/debug) logs spread throughout the code.

> Thank you TJ for debug! And for all your early work in Node.js. I am still amazed by how your early is pervasive.

I have added `DEBUG=express-session` and I see logs of `not secured`.
Bam! We have suspect.
It's a short function you can read it to guess what might be the problem.

```js
function issecure(req, trustProxy) {
  // socket is https server
  if (req.connection && req.connection.encrypted) {
    return true;
  }

  // do not trust proxy
  if (trustProxy === false) {
    return false;
  }

  // no explicit trust; try req.secure from express
  if (trustProxy !== true) {
    return req.secure === true;
  }

  // read the proto from x-forwarded-proto header
  var header = req.headers["x-forwarded-proto"] || "";
  var index = header.indexOf(",");
  var proto =
    index !== -1
      ? header.substr(0, index).toLowerCase().trim()
      : header.toLowerCase().trim();

  return proto === "https";
}
```

We are running a HTTP express server in docker container and using NGINX as reverse proxy.
NGINX handle HTTPS connections and our server handles an unencrypted connection.
This is totally fine.
But our server is expecting `x-forwarded-proto` header when the request gets forwarded.

A quick ChatGPT conversation later, I fixed the NGINX configuration.

```nginx
proxy_set_header X-Forwarded-Proto $scheme;
```

I am able to log in to the application in production environment.
Wow! I am not crying, I am just happy.
Navigating around the application seems to work fine.

### Level's final boss

I tried to upload a voice clip, and it doesn't work.
There is 400 error in Network Panel for the POST `/clip` request.
The network panel doesn't show any response.

[Ah! Shit! Here we go again](https://www.youtube.com/watch?v=-1qju6V1jLM)

I tried to copy the request, and run it cURL to see what is the response.
There is an error message but since I want to debug it, I just wrote bunch of [debug](https://npm.im/debug) logs. 😁
It was handy before so why not!

This was the problematic piece of code, and it was doing an early here.
Can you guess what is the problem here?

```js
  saveClip = async (request: Request, response: Response) => {
    debug('saveClip request started', request.headers);
    const { client_id, headers } = request;
    const sentenceId = headers.sentence_id as string;
    const source = headers.source || 'unidentified';
    const format = headers['content-type'];
    const size = headers['content-length'];

    if (!sentenceId || !client_id) {
      this.clipSaveError(
        headers,
        response,
        400,
        `missing parameter: ${sentenceId ? 'client_id' : 'sentence_id'}`,
        ERRORS.MISSING_PARAM,
        'clip'
      );
      return;
    }
```

The error I saw in the logs was `sentence_id` parameter is missing.
I did a few extra round trips to front-end code base before it hit me.
`sentence_id` header is being dropped.
You already know who the culprit is, NGINX.

By default, NGINX drops any headers with underscores.
After a small configuration change, everything works well!

```nginx
    underscores_in_headers on;
```

I can now upload clips to the self-hosted instance of common-voice.

Actually, I cursed a lot at this point. Why? When we have `multipart/form-data` available or query parameters, why use headers to transmit information?
I thought it might be better to transmit all custom headers with `x-` prefix.
I searched to find any supporting documents.
I found a [StackOverflow answer](https://stackoverflow.com/a/3561399/1117168) which stated that all headers are allowed now.
IETF deprecated the suggestion to prefix custom headers with `x-`.
Read the SO answer for more details.

## Conclusion

What was I able to achieve over this weekend beyond obvious stuff?
I have demonstrated the expertise to myself to go up and down the stack seamlessly.
I was able to read and navigate through several core npm packages that underpin the Node.js ecosystem.
It was instrumental in solving my problems.
I am a little better programmer than I am yesterday.

As I was solving the problems, I kept writing a [small guide](https://hackmd.io/@vramana/rksgTjsqp) to my future self and whosoever works on this project after me.
There should be clear path for who comes after me.
My wish is that the atomic commits I made with meaningful commit messages and this blog post will help maintain this project.

It feels good.
Now I can go and solve the problem which got excited.
Maybe I will write another blog post about it.
