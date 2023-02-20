+++
title = "Is Java Reflection Slow?"
date = 2023-02-18T11:03:26+05:30
tags = ["gcp", "bigtable", "dataflow", "beam", "java", "benchmark"]
draft = false
layout = "post"
+++

I came across a piece of Java code written by my colleague which uses reflection in a hot code path. I read somewhere
that reflection is often slow and should not be used hot code paths. My first instinct was let's benchmark this and understand
what kind of performance speedup we can get.

<!--more-->

At my company we are designing a data for Dataflow pipeline which will read events from Google Cloud PubSub and write them into Google Cloud BigTable.

![](/events-dataflow-pipeline.excalidraw.png)

We parse each event into an `Event` class.


```java
public class Event {
    private String action;

    private Integer actorId;

    private String actorName;

    private String actorType;

    private Integer authenticatedById;

    private String authenticatedByType;

    private Date cameraSnapshotsExpireAfter;

    private String code;

    private Date createdAt;

    private Object details;

    private Integer id;

    // A lot more fields
}
```


In the third step of Dataflow, we need to convert each Event object into a BigTable Row.

