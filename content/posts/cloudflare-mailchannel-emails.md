+++
title = "How to send free transactional emails with Cloudflare & MailChannels: Step by step tutorial"
date = 2024-04-29T00:15:38+05:30
tags = ["email", "cloudflare", "dns", "javascript"]
draft = false
layout = "post"
+++

Back in 2022, Cloudflare introduced support for free transactional emails in partnership with MailChannels back
I have known about this for a some time and I wanted to see if it's easy to setup and send an email.
Turns out, its amazingly easy and free.

<!--more-->

Are you thinking of building a SaaS or a side project?
You will run into a situation where you have to send emails to your users.

Sending emails is a costly affair from popular email services like Mailgun, Sendgrid, Loops, Postmark etc.,
It usually costs roughly in the order of a dollar for 1000 emails.
A little bit less or more depending on the exact provider.
AWS SES offers emails for 10,000 emails for a dollar, one order of magnitude cheaper.

Sending emails is completely free with Cloudflare and MailChannels.
But you still have pay for worker execution.
It costs around 0.3 dollars per million executions for Cloudflare workers.
This again orders of magnitude cheaper than AWS SES.

So what's the catch? You don't have email deliverability dashboard.
This is probably important for certain use cases like marketing emails.
Maybe it's possible to build a dashboard on top of Cloudflare stack.
It's whole another adventure in itself.

Anyway, let's set up a Cloudflare worker to send an email.


## Configuring DNS

As a prerequisite, you need a domain whose nameservers are managed by Cloudflare.
You need to do 2 steps to configure your domain.

1. Add SPF record
2. Add domain lockdown record

A sender policy framework (SPF) record is a type of DNS TXT record that lists all the servers authorized to send emails from a particular domain.

On your domain, you need to add the following as TXT record at root level

```
v=spf1 a mx include:relay.mailchannels.net ~all
```

According to MailChannels,

> Domain Lockdown™ lets you control which MailChannels accounts and sender-ids are authorized to send an email that is addressed from your domain by specifying your preferences in a simple DNS TXT record.

So, it's TXT record used by MailChannels as an allow list of all the domains that can send emails to MailChannels.
In our case, create TXT record for `_mailchannels.yourdomain.com` as

```
v=mc1 cfid=<cloudflare worker subdomain>.workers.dev
```

You can find out your Cloudflare worker subdomain in Workers and Pages Overview page on the right-hand side.


## Configuring Cloudflare Worker

Create a new worker from Cloudflare dashboard and edit the code of the worker to be following

```js
export default {
  async fetch(request) {
    if (request.method !== 'POST') {
      return new Response("OK");
    }

    // For testing purpose, replace this with your personal email
    // so that you can see the message sent to your inbox
    const receiver = 'test@example.com'
    // Replace <yourcompany.com> with the domain you set up earlier
    const sender = 'mail@yourdomain.com'
    const send_request = new Request('https://api.mailchannels.net/tx/v1/send', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        personalizations: [
          {
            to: [{ email: receiver, name: 'Test Email' }],
          },
        ],
        from: {
          email: sender,
          name: 'Cloudflare Workers - MailChannels integration',
        },
        subject: 'Mail from Cloudflare',
        content: [
          {
            type: 'text/html',
            value: '<h1>Hello from Cloudflare worker</h1>',
          },
        ],
      }),
    })
    const resp = await fetch(send_request);
    return new Response("Sent email");
  },
}
```

Enable route trigger on your Cloudflare worker by going into the worker settings.

That's it.
You can test request by sending a post request to the worker using your favorite.
An email should arrive shortly.

