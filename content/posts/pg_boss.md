+++
title = "Notes on pg_boss"
date = 2024-08-27T07:00:02+05:30
tags = []
draft = true
layout = "post"
+++


<!--more-->

pg_boss is mainly a collection of event emitters

- attorney.js  is a collection of validation functions
- db.js is event emitter that initiates a pooled database connections. It executes any sql commands
- plan.js is a collection of sql queries used managing queues and jobs
- contractor.js is a class that manages schema migrations for jobs and queues tables
- tools.js has a single function. delay is wrapper around setTimeout but it's abortable.
- worker.js class that executes jobs. It's a state machine with following state created, active, stopping or stopped. Worker can execute jobs
  at a minimum interval.
- manager.js class orchestrates the workers.
- timekeeper.js is a event emitter which schedules new jobs based on cron schedule. It also accounts clock skew between the database and the server.
- boss.js does maintainence of failed, archived and deletes job after a certain period of time.
- index.js orchestrates manager, timekeeper, boss and contractor
