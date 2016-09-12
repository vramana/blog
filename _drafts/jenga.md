---
layout: post
title: What is jenga
published: false
---

Jenga is general purpose build system built by JaneStreet.

Tool & rules:
- Rules provided by user; interpreted by the tool

The build tool is responsible to orchestrate the minimal sequence of
actions necessary to bring a set of generated targets up to date.

General purpose tool
- no build in knowledge of specific languages or compilation tools
- no magic handling
- just a consistent general purpose build model

The overall build process is demand driven.
We request the system to build some top level target, perhaps main.exe

Rules (provided by user) decribe actions to run to create generated targets.
And any dependencies (other files) required for the action.

Example: a rule for linking
- linking stage might describes how some .o are linked into a .exe
- the .o's are the dependencies.
- if these are also generated targets (not sources), as expected, there will other rules for each .o
- then before the link is run the .os must be generated, or brought up to date
- by running whatever action is responsible for creating them
- and finally the link command can be run (or not, if we discover it is not required)

Commonly, rules are split. framework + per-project config
Dont want every developer to have to be a build system expert
They should say: build all .ml in this dir into library ''foo'', making use of lib ''bar''

----------------

So, the first question is probably: why on earth did we feel the
need to develop yet another build tool. Does the world not have enough?
- no other existing tool has the full set of features we deem important.
- omake (what we used before), comes closest
Overview of JS workflow: One big tree; two workflows...

One tree; big - main advantage of a single tree. Can modify
interfaces to heavily shared common library (improve names/types)
and fix up all callers in one consistent change-set

Two flows...
Continuous integration
- remote box; full tree; guard bad commits; incremental but restarted

Individual development
- local box; own project subtree; incremental, polling

Before jenga, janestreet used omake - pretty good!
Has lots of features we view as important.
And solves many issues newer tools fail on.
Brief list''
- one build instance for whole tree
- quick
- polling
- dynamic dependencies
- programmable rule generation
Problems, increasing over time...
- at JS we have stretched it scalability to the limit
- more importantly: hard to program

Thing we dislike the most about omake, is the omake language itself.
- dynamic typing; dynamic scoping; scripting language not a programming language


Correctness of build rules.
  Golden test: Incremental = From-clean
- want performance of incremenal builds, but with semantics of form-clean builds
- requires accurate spec of dependencies.

-----------------

How jenga is used: as a tool, and as system to describe build rules

---------------------------------------------------------------------

Programable
Rules are coded in OCaml, against an API. No DSL here.
{\tt jengaroot.ml} loaded using {\tt ocaml\_plugin}
omake had DSL. Ok in the small, but for a large engineering project it becomes unmanageable

Question. why wouldn't you want to use a real programming language?
and so an early design decision of jenga was for the rules to be described in ocaml, using an API

Incremental
   If not incremental. Your not a build system, but a script.
   We want to be able to rely on our incremental builds being correct.
   Requires that rules declare correct deps... any file wich is read by action

   Golden test: Incremental = From-clean
   How many times have you heard a broken build excesed with ''oh, just clean and build again''
   clear inditement that the build system is broken
   Not acceptable when a full tree build takes 1--2 hours

   Would be nice to avoid this explicit statement of deps. Dream system would avoid it.
   Instead we focus on giving user means to make accurate specification of deps
   We need our build tool to to offer a language rich enough to express
   complex (& dynamic) dependencies for rules and rule generation,
   which exists in the real world

Persistant (imp detail of incremental build)
   Use persistent store to record record of every action run.
   - digest of deps & targets + the exact command executed.
   so we can tell when we dont have to run again.

Polling
   for interactive use;  had in oamke. lovely feature
   rerun compilation ASAP, even while still building other parts of the tree  

Parallel build:
   jenga extract maximum parallel as expressed in the rules
   throttled by -j argument
   Commonly choose to set this to number of cores. Or higher and let OS slice.
   Most relevant when building a full tree ''from clean''

---------------------------------------------------------------------


The most important thing is dependencies.
Without accurate deps, there can be no hope of a correct incremental builds.
Developing \& maintaining a build system is a major engineering project.

Real world deps are not trivial, and very often dynamic.
- dont know what the deps are before the build starts
- they are discovered during the build process
Often we dont even know what targets have rules before we start
- i.e. setting up a compile rule for all .ml in a directory

Dynamic dependencies
generalisation of what some build tools call scanner dependencies.
Example: gcc -M to detect which header files are required
(if headers are generated - need fixpointing)
for ocaml - ocamldep.. also incomplete soltion
%
In jenga, arbitrary conditional deps can be expressed
example: ocaml compilation rule setup depends on existance/or not of .mli
%
Jenga introduces ''glob dependencies'' i.e. `*.ml`
Most commonly used during rule configuration
And this also works properly in polling mode where we can be
triggered as new files appear or exiting files disappear
in omake, `*.ml` did not wrk in polling mode, requiring restart of omake

rule generation.
Not a distinct phase. Integrated with rest of build system.
For example, rules can be written to have a per-directory config file (flags etc) which is consulted for rule-gen.
This config file could itself be a generated file!

We did in fact use generatted config for during switch over from omake
For a while (some months) we could build with both build systems. jenga config was 99generated automattically from omake config
jbuild.gen / jbuild

---------------------------------------------------------------------

The concept of a rule in classic make is a static triple.
Nice and simple.
Often is sufficient
But in general - it is not expressive enough

---------------------------------------------------------------------


So ''dep'' is a parametrised type.
The simpler dep of the make rules triple, now becomes: unit dep.

What do values of this type mean?
Semantically, a value of type {\tt t dep} can be thought of
as taking different values of type {\tt t} at different times.
%
These times might be:
- each time the build tool is restart (we re-evaluate the rules)
- we re-evaluate as necessary in response to being triggered by external events (inotify)

---------------------------------------------------------------------

This is also the approach takes by shake
%
Early version attempted to avoid exposing the monad to the rules
author - but this was a mistake.
%
Made the rule setup more tricky & much more fragile.

---------------------------------------------------------------------

Action carried by the parametrised dependency type.
Rule generation fits in the scheme.
Simple rule creation can be recovered.

---------------------------------------------------------------------


All leading up to this big example. I'll take a little time here.
Sorry about the rather visually disturbing orange rectangle!
%
This is used to highlight the 2nd argument to ''rule'', having type ''action dep''
composed using the map/bind combinators
determines dependencies: static & dynamic
Ends in a call to ''bash''
In this case the cbash command string is static, but it need not be.
- In the case of linking the bash action would not be static, for example
- if the objects being linked have to be ordered w.r.t inter-module dep
%
But this example does how dynamic deps are represented.
- the call to ''needs'' makes use of ''dynamic'', coming from deps_from_file
- but on RHS of the bind operator.
- (the .ml.d file will presuamble be generated by some other rule, perhaps running ocamldep)
- if the .ml.d changes, this rule will reconfig itself to be dependant on the new names listed.

---------------------------------------------------------------------

Example shows:
- rule generation, based on `*.ml` existing in a dir
- conditional rule setup

---------------------------------------------------------------------

Switch away from descibing jenga from user (rule author) perspecitive
And to the implementation of jenga

---------------------------------------------------------------------

Clearly, we like the features described.
As a means for user to describe declaratively the build rules.
And we want the parallel, polling, incremental builds!
So how does jenga achieve this... Tower of monads.
Differnet layers reposnsible for different aspects of the design.
%
Depends
   Already seem Depends. from user POV
   API offerred to user of jenga
   main purpose is supports incremental (recompilation) feature of jenga
%
Tenacious
   part of implementation of jenga; not exposed to user
   supports polling feature
%
Deferred
   monad at heart of JS async library
   support concurrent/parallel jenga builds
   "Co-operative multi threading"
%
All monadic. return; bind; map.
Support parallel/concurrentcy via [all] combinator

%======================================================================

Start at bottom of tower & work up...

---------------------------------------------------------------------

Supports concurrent apps; read/write multi files/sockets; server apps.
Computations started from when the deferred is created.
Dont want blocking computation in one (async) thread to block entire app.
%
What is a value of deferred type?
Cell to hold the result of computation. Filled in asynchronously when finished.
When the result is ready, the deferred is said to become determined.
A deferred is determined (at most) once; and retains its value.
%
User code can wait for the result of a deferred value to be determined
When a deferred becomes determined, waiting computations are resumed.
%
Abstraction for asynchronous computations. Core type of JS async library.
"Co-operative multi threading"

Lightweight.
Some nice atomicity guarentees
User code 'can' block entire application. (downside)

---------------------------------------------------------------------

Monadic composition: sequential (bind); concurrent (all)
[all] synchronises when a list of computation are all determined.
[in_thread] wraps blocking primitive computations (run in separate thread.)
so cant block entire application.
%
example primitives
- and operation which takes signiifcant time (i.e. may block app)
- system call or bigger.

- not really primitives!
written in user async code, from real primitives - system calls lifted in to async monad
Most uses of in_thread within async library where system calls are lifted into async
%
User code which composes deferred computations runs in a single thread.
Scheduler is the single point of mediation
Queue of pending deferreds; Pool of threads; Central select loop for IO
When leaf in_thread computation are finished, or IO becomes available
scheduler fills in the deferred; waiting computations can proceed


%======================================================================

So use of async is pervasive across 90of JS's code base
%
From POV of apps like jenga, deferred gives us the basic support for writing concurrent apps.
i.e. run multiple compilation commands in parallel

also needed in jenga...
read files / digest files (run external md5sum to digest file)
async save to persist store
support query access via socket (jenga is a server)
receive inotify events from OS indicating indicating file mod event. i.e source file edited
%
So what is tenacious for?

---------------------------------------------------------------------

Tenacious computation is a: invalidatable, restartable, cancelable computation

[invalidatable]
Each (sub) computations has associated with it, a certificate. Indicating the basis for the computation is still valid.
What "basis for computation" means is up to user.
%
[restartable]
An invalid computation will get re-played.
RHS of bind re-applied to get new result
to supersede old RSH computation
%
[cancelable]
A computation which is dep on an invalid computation (RHS of bind)
will be cancelled - stop unwinding & discontinued
(choose that leaf computations will run to completion)

Purpose of tenacious is to support implementation OS jenga 'polling' mode.
%
Describe from jenga user POV.
- start build.. compilation commands run.. assuming succ build.. everything done.. waiting
- get inotify event.. some .ml file is edited. need to redo part of the build effected.
- first the compilation of that file.. then any dep files.. linking libraries.. linking exe
- only want to check the effected part of the tree (important when tree big)
%
tenacious does not have knowledge of FS notification built in
although that is a very important application

But, building is a long running process. make take an hour say. don't
want to wait until the whole build is finished before we restart compiles which need to be redone.
Want to start immediately!
Must discard any thing done previously which make use of now invalidated data
Mustn't start anything new which was dependent on the pre-event state of the world.

Different form Acar's self-adjusting computation,
which has two-phase semantics: {change-inputs; stabilize} repeat

---------------------------------------------------------------------

Like deferred, Monadic composition, with ''all'' for concurrent computations
Primitive computations are lifted into the tenacious type, making use of heart abstraction.
%
[Heart] is a certificate of validity. break-once mutable triggers. (heart is broken); light weight
hearts compose internally by tenacious
invalidity trigger flows instantly to all computations which are deemed broken.

As tenacious computations are unwound, relevant hearts are checked before started new leaf lifted computations
when hearts are broken, computations are re-played. RHS of binds re-applied.. maybe creating different computations

[lift]
allows arb deferred computation, which may be async invalidated to be liftend in to tenacious
tenacious does not have knowledge of FS notification built in
although that is a very important application - next example

%======================================================================

So we have parallel builds.
And builds which are retriggered in response to event from the FS notifier.
What does the depends layer give us?
%
Support for checking builds are up-to-date,
but without running any actions which are not necessary
because we determine the actions have been run before & nothing (pertinent) has changed.
Running the action again now should(!) have no effect.

---------------------------------------------------------------------

API for describing build rules.
rule is pair of target paths & action carried by depends monad
(think of action as the command line string which we will run)

Supports "incremental builds!"
Avoid running unnecessary (compilation) actions
%
An action is unnecessary when
- we ran it before
- all deps are up-to-date & are unchanged (from when we last ran the action)
- and the targets are still there & are untampered with
%
by unchanged we consider a digest of the file
for glob, the list of files is unchanged - but not in this example!

Presumption that user compilation actions will always operate the same
generating identical targets from same dependent files
Not always true! e.g. ar - timestamp

---------------------------------------------------------------------

Explanation of depends abstraction is inter-twined with operation of he build algorithm
stated here. read!

Particular example - the null build...
- build whole tree.. everything is up to date
- stop jenga (dont touch an files)
- restart: everything is checked - NO actions are run

%======================================================================
