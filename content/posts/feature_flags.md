+++
title = "Designing a feature flag system with Firebase"
date = 2023-08-19T15:04:36+05:30
tags = [
 "system design",
 "firebase",
 "firebase real-time database",
 "database",
 "react",
 "context",
 "feature flags",
 "javascript"
]
draft = false
layout = "post"
+++

Feature flags allow developers to enable and disable features without making changes to code and re-deploying the application.
I have designed & developed the feature flag system at work for [https://web.kisi.io](). It has been 3 years since I wrote the
first commit, and it's still in production.

<!--more-->

## Problem & Motivation

My team was able to ship features without feature flags. So why do we need feature flags?
Here are a few scenarios we ran into frequently

- As we developed features and sent the feature for QA tests, we discovered there is an API bug or that we feature was not completely built.
  So we need to put the pull request on hold. By the time, the bug is fixed in the API, there would be a bunch of merge conflicts
  on the pull request. So stale pull requests blocked by API team are drag on development.
- Other times, we would have designs ready for a feature and API team is not done yet. We were asked by
  our manager just build up the user interface and wait till API team is done with their work.
  This again leads to stale pull requests.
- When you have to build a large feature, it's headache to review large pull requests. So we want the
  ability to land feature incrementally (smaller pull requests) without breaking anything for user and not show the
  feature until it's ready.

Feature flags are clearly the answer to this exact. After we built feature flags, it gave us the
ability to enable to feature to particular customers (even if they are not ready).

## Requirements

There are many valid ways to build a feature flag. As an example, feature flags work on user account
level i.e, you can enable/disable features for single user. This is a possible solution is B2C situation.
My company [Kisi](https://getkisi.com) is B2B company. So it made sense for us to implement feature
flags for each business i.e, if we enable a feature flag for a business it would be enabled for all users
of the business. It's not granular, but it was good enough for us. We refer each business as organization
in our API.

This also meant that we didn't have to enable the feature flag for each developer on our team,
we can enable feature flag on test organization it will be enabled for all developers. A
reviewer doesn't have to ask to enable feature flag.

The system should allow any developer to add, enable, disable and remove a feature flag with ease. Optionally
it can even allow product managers to enable/disable feature flags without developer intervention.
But we never implemented as such requests were rare from our product manager.

A feature flag is two pieces of data, the name of the feature flag and it's value. So the following
example of feature flags for a given organization

```json
{
  "marketplaceFeature": true,
  "settingsRedesign": false
}
```

Let's say I receive a request to turn on feature flag for an organization. How should it work for
the end user? All I have to do is run a script or click a button in UI and the feature should
show up for user as soon as he refreshes the page. We want a smooth frictionless UX and DX.

## Choosing Firebase: Rationale & Advantages

Feature flags are persistent data to the obvious choice was make it part of our API. But our API
team was busy and we were asked to find a solution ourselves. Our company uses Google Cloud Platform
for all its cloud requirements, so our CTO asked us to look at anything available in GCP ecosystem.

The closest thing I could find was Firebase Remote Config. But it didn't allow us to target organizations
and it seemed as if it's built for Android and iOS in mind. There are SaaS products that are available that
do exactly this. But it's another dependency to our application. Also I have to convince my CTO pay
for tool and that didn't seem very plausible. So, it was time to roll out our own feature flag
system.

The basic requirement is we need a database to persist data. We already had Firebase project that we
use for sending push notifications via Firebase Cloud Messaging (FCM). So we have ready-made
access to Firebase real-time database. Since I didn't see need to do advanced queries as each
organization's feature flags are isolated, so the problem looks like we need a key-value store.
Firebase database is JSON like object it seemed like a perfect fit.

Here is schema for how we store feature flags.

```json
{
  "allOrganizations": {
    "featureFlag6": true
  },
  "organization": {
    "1": {
      "featureFlag1": true,
      "featureFlag2": true
    },
    "2": {
      "featureFlag3": true,
      "featureFlag4": true
    }
  }
}
```

Here we have special key called `allOrganizations` to enable or disable a feature for all organizations
i.e, it allows us to release a feature to production without removing the feature-flag from
code and re-deploying the application. Nice right?

Firebase real-time database also has nice UI to edit JSON (data in the database). So it's
super easy to modify the feature flags as necessary.

## Security Considerations

Firebase allows you to write security rules for real-time database. Since this is meant to be read
only system for end users and only developers need to edit it. We have disabled access reads and writes
for entire base using the database URL. We exposed the feature flag data using Firebase function instead.

## Affects on feature development

When submitting a pull request, both code review and QA review are required. But when we develop a feature
using feature flag, the developer can merge their code after passing the code review. Once the whole
feature is complete, then developers can raise review request from QA team. Usually one or two requests
will fix all the feedback. Instead of waiting on QA review and finish a feature in one go,
developers can split the feature into many pull requests. Often these pull requests have feature
in a broken state, and it is totally fine.

## Code

We fetch the feature flags from Firebase function and use context to propagate them throughout the UI.

```ts
import {
    createContext,
    useState,
    useEffect,
    useMemo,
    AppContext
} from 'react'

const AppContext = createContext({
    featureFlags: {}
})

function FeatureFlag({ children }) {
  const [featureFlags, setFeatureFlags] = useState({});

  useEffect(() => {
    fetch("https://example.com/feature_flags")
      .then(res => res.json())
      .then(setFeatureFlags)
      .catch(console.error)
  }, [])

  const appContext = useMemo(() => ({ featureFlags }), [featureFlags]);

  return (
    <AppContext.Provider value={appContext}>
        {children}
    </AppContext.Provider>
  );
}


function MyComponent() {
  const { featureFlags } = useContext(AppContext);

  return (
    <div>
      {(
        featureFlags.myFeature ?
          <IncompleteFeature /> :
          <ProductionReadyFeature />
      )}
    </div>
  };
}
```
