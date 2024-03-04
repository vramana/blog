+++
date = "2022-06-25"
published = true
title = "Short anatomy of node-redis client"
layout = "post"
tags = ["node"]
+++

I am trying to write simple redis-client in rust. As part of that exercise, I have read the source code of
Node.js Redis Client. I want to jot down some notes on how it works.

<!--more-->

A Redis Client opens a TCP connection and it writes and reads over that connection.
We will to examine these 3 things in detail. Opening a connection, writing a command and reading a reponse.

### Opening a connection

`RedisClient` definition in [this file][redis-client-class].

```ts
class RedisClient {
  // ....
  constructor(options?: RedisClientOptions<M, F, S>) {
    super();
    this.#options = this.#initiateOptions(options);
    this.#queue = this.#initiateQueue();
    this.#socket = this.#initiateSocket();
    // ....
  }
  // ....
}
```

In the constructor, we see that `RedisClient` object has two private variables `this.#queue` & `this.#socket` that are relevant to us.

```ts
class RedisClient {
  // ....
  #initiateSocket(): RedisSocket {
    const socketInitiator = async (): Promise<void> => {
      const promises = [];

      if (this.#selectedDB !== 0) {
        promises.push(
          this.#queue.addCommand(["SELECT", this.#selectedDB.toString()], {
            asap: true,
          }),
        );
      }

      if (this.#options?.readonly) {
        promises.push(
          this.#queue.addCommand(COMMANDS.READONLY.transformArguments(), {
            asap: true,
          }),
        );
      }

      if (this.#options?.name) {
        promises.push(
          this.#queue.addCommand(
            COMMANDS.CLIENT_SETNAME.transformArguments(this.#options.name),
            { asap: true },
          ),
        );
      }

      if (this.#options?.username || this.#options?.password) {
        promises.push(
          this.#queue.addCommand(
            COMMANDS.AUTH.transformArguments({
              username: this.#options.username,
              password: this.#options.password ?? "",
            }),
            { asap: true },
          ),
        );
      }

      const resubscribePromise = this.#queue.resubscribe();
      if (resubscribePromise) {
        promises.push(resubscribePromise);
      }

      if (promises.length) {
        this.#tick(true);
        await Promise.all(promises);
      }
    };

    return new RedisSocket(socketInitiator, this.#options?.socket)
      .on("data", (chunk) => this.#queue.onReplyChunk(chunk))
      .on("error", (err) => {
        this.emit("error", err);
        if (this.#socket.isOpen && !this.#options?.disableOfflineQueue) {
          this.#queue.flushWaitingForReply(err);
        } else {
          this.#queue.flushAll(err);
        }
      })
      .on("connect", () => this.emit("connect"))
      .on("ready", () => {
        this.emit("ready");
        this.#tick();
      })
      .on("reconnecting", () => this.emit("reconnecting"))
      .on("drain", () => this.#tick())
      .on("end", () => this.emit("end"));
  }
  // ....
}
```

`initiateSocket` method returns a `RedisSocket` object which is turn an `EventEmitter`.
The method also pushes some commands onto `this.#queue`.
`RedisSocket` definition is in [this file][redis-socket-class].

```ts
class RedisSocket {
  // ...
  async #connect(retries: number, hadError?: boolean): Promise<void> {
    if (retries > 0 || hadError) {
      this.emit("reconnecting");
    }

    try {
      this.#isOpen = true;
      this.#socket = await this.#createSocket();
      this.#writableNeedDrain = false;
      this.emit("connect");

      try {
        await this.#initiator();
      } catch (err) {
        this.#socket.destroy();
        this.#socket = undefined;
        throw err;
      }
      this.#isReady = true;
      this.emit("ready");
    } catch (err) {
      this.emit("error", err);

      const retryIn = (
        this.#options?.reconnectStrategy ??
        RedisSocket.#defaultReconnectStrategy
      )(retries);
      if (retryIn instanceof Error) {
        this.#isOpen = false;
        throw new ReconnectStrategyError(retryIn, err);
      }

      await promiseTimeout(retryIn);
      return this.#connect(retries + 1);
    }
  }

  #createSocket(): Promise<net.Socket | tls.TLSSocket> {
    return new Promise((resolve, reject) => {
      const { connectEvent, socket } = RedisSocket.#isTlsSocket(this.#options)
        ? this.#createTlsSocket()
        : this.#createNetSocket();

      if (this.#options.connectTimeout) {
        socket.setTimeout(this.#options.connectTimeout, () =>
          socket.destroy(new ConnectionTimeoutError()),
        );
      }

      socket
        .setNoDelay(this.#options.noDelay)
        .once("error", reject)
        .once(connectEvent, () => {
          socket
            .setTimeout(0)
            // https://github.com/nodejs/node/issues/31663
            .setKeepAlive(
              this.#options.keepAlive !== false,
              this.#options.keepAlive || 0,
            )
            .off("error", reject)
            .once("error", (err: Error) => this.#onSocketError(err))
            .once("close", (hadError) => {
              if (!hadError && this.#isOpen && this.#socket === socket) {
                this.#onSocketError(new SocketClosedUnexpectedlyError());
              }
            })
            .on("drain", () => {
              this.#writableNeedDrain = false;
              this.emit("drain");
            })
            .on("data", (data) => this.emit("data", data));

          resolve(socket);
        });
    });
  }

  #createNetSocket(): CreateSocketReturn<net.Socket> {
    return {
      connectEvent: "connect",
      socket: net.connect(this.#options as net.NetConnectOpts), // TODO
    };
  }

  // ...
}
```

The `#createSocket` & `#createNetSocket` method finally lead us to TCP connection logic we are looking for.

From Node.js documentation, `net` module

> The net module provides an asynchronous network API for creating stream-based TCP or IPC servers (net.createServer()) and clients (net.createConnection()).

### Writing commands

Once the connection is established, we trigger several callbacks that we have setup so far.
The `socket` connected is stored in `this.#socket` and the `this.#initiator` callback is called ([socket.ts L108][initiator-call]) which is passed
as the argument to be `RedisSocket` constructor.

There are several commands queued from the initiator callback ([socket.ts L224-261]).
Let's look at `this.#queue` from `RedisClient`. `this.#queue` is an instance of `RedisCommandQueue`.
`RedisCommandQueue` definition is in [this file][command-queue].

`RedisCommandQueue` is backed by two doubly-linked lists ([yallist][yallist]) `#waitingToBeSent` and `#waitingForReply`.
The names are self explanatory, one queue for keep commands yet to sent and the other for response yet to be recieved.

```ts
    addCommand<T = RedisCommandRawReply>(args: RedisCommandArguments, options?: QueueCommandOptions): Promise<T> {
        if (this.#pubSubState.isActive && !options?.ignorePubSubMode) {
            return Promise.reject(new Error('Cannot send commands in PubSub mode'));
        } else if (this.#maxLength && this.#waitingToBeSent.length + this.#waitingForReply.length >= this.#maxLength) {
            return Promise.reject(new Error('The queue is full'));
        } else if (options?.signal?.aborted) {
            return Promise.reject(new AbortError());
        }

        return new Promise((resolve, reject) => {
            const node = new LinkedList.Node<CommandWaitingToBeSent>({
                args,
                chainId: options?.chainId,
                returnBuffers: options?.returnBuffers,
                resolve,
                reject
            });

            if (options?.signal) {
                const listener = () => {
                    this.#waitingToBeSent.removeNode(node);
                    node.value.reject(new AbortError());
                };
                node.value.abort = {
                    signal: options.signal,
                    listener
                };
                // AbortSignal type is incorrent
                (options.signal as any).addEventListener('abort', listener, {
                    once: true
                });
            }

            if (options?.asap) {
                this.#waitingToBeSent.unshiftNode(node);
            } else {
                this.#waitingToBeSent.pushNode(node);
            }
        });
    }
```

Every command enqueued returns a Promise so it's caller can recieve the response asynchronously.
The command is stored as an object along with the promise's resolve and reject functions.

One thing to note the queues are using doubly-linked lists so commands if need be can be added to the front of the queue.
All the commands in the socket initiator pass an additional argument `{ asap: true }`.
The authentication command is the last command enqueued from socket initiator with `{ asap: true }` so it will be exectued first.

So far we queued commands, Let's examine how they are sent.

`RedisSocket.#socket` will emit a `ready` event and `RedisSocket` will in turn emit `ready` event too.
In `RedisClient.#initiateSocket`, `RedisSocket` has a callback for `ready` event.

```ts
return new RedisSocket(socketInitiator, this.#options?.socket)
  .on("data", (chunk) => this.#queue.onReplyChunk(chunk))
  .on("error", (err) => {
    this.emit("error", err);
    if (this.#socket.isOpen && !this.#options?.disableOfflineQueue) {
      this.#queue.flushWaitingForReply(err);
    } else {
      this.#queue.flushAll(err);
    }
  })
  .on("connect", () => this.emit("connect"))
  .on("ready", () => {
    this.emit("ready");
    this.#tick();
  })
  .on("reconnecting", () => this.emit("reconnecting"))
  .on("drain", () => this.#tick())
  .on("end", () => this.emit("end"));
```

Let's examine `RedisClient.#tick` method and related methods

```ts
    #tick(force = false): void {
        if (this.#socket.writableNeedDrain || (!force && !this.#socket.isReady)) {
            return;
        }

        this.#socket.cork();

        while (!this.#socket.writableNeedDrain) {
            const args = this.#queue.getCommandToSend();
            if (args === undefined) break;

            this.#socket.writeCommand(args);
        }
    }

```

```ts
    getCommandToSend(): RedisCommandArguments | undefined {
        const toSend = this.#waitingToBeSent.shift();
        if (!toSend) return;

        let encoded: RedisCommandArguments;
        try {
            encoded = encodeCommand(toSend.args);
        } catch (err) {
            toSend.reject(err);
            return;
        }

        this.#waitingForReply.push({
            resolve: toSend.resolve,
            reject: toSend.reject,
            channelsCounter: toSend.channelsCounter,
            returnBuffers: toSend.returnBuffers
        });
        this.#chainInExecution = toSend.chainId;
        return encoded;
    }

```

```ts
    writeCommand(args: RedisCommandArguments): void {
        if (!this.#socket) {
            throw new ClientClosedError();
        }

        for (const toWrite of args) {
            this.#writableNeedDrain = !this.#socket.write(toWrite);
        }
    }
```

`this.#socket.cork()` is a rabbit hole on it's own. This [blog post][cork] explains it in a good detail.

`RedisCommandQueue.getCommandToSend` method will pop the first command off the the queue and encode the command in RESP2 protocol.
`RedisCommandQueue.#waitingForReply` queue is enqueued with node containing `RedisCommandQueue.addCommand` return value promise's
`resolve` and `reject` so they can be called once a response is recieved.

The encoded command is written to the socket in `RedisSocket.writeCommand` with `this.#socket.write`.
`RedisSocket.#writableNeedDrain` tracks if the TCP socket's buffer is full and stops `RedisClient.#tick` from enqueueing more commands.

> Returns true if the entire data was flushed successfully to the kernel buffer. Returns false if all or part of the data was queued in user memory. 'drain' will be emitted when the buffer is again free.

[socket.write documentation][socket-write]

Is this handling backpressure? Yep. It seems so. Read this great [blog post][node-backpressure].

```ts
            .on('drain', () => this.#tick())
```

`RedisClient.#tick` will enqueue command until `RedisSocket.#writableNeedDrain` is true.
`RedisClient.#tick` will be called again when `RedisSocket` will emit `drain`.

### Reading a response

```ts
return new RedisSocket(socketInitiator, this.#options?.socket).on(
  "data",
  (chunk) => this.#queue.onReplyChunk(chunk),
);
```

```ts
    onReplyChunk(chunk: Buffer): void {
        this.#decoder.write(chunk);
    }
```

`RedisSocket` will queue data coming from the TCP socket to `RedisCommandQueue.onReplyChunk` method.

```ts
#decoder = new RESP2Decoder({
  returnStringsAsBuffers: () => {
    return (
      !!this.#waitingForReply.head?.value.returnBuffers ||
      this.#pubSubState.isActive
    );
  },
  onReply: (reply) => {
    if (this.#handlePubSubReply(reply)) {
      return;
    } else if (!this.#waitingForReply.length) {
      throw new Error("Got an unexpected reply from Redis");
    }

    const { resolve, reject } = this.#waitingForReply.shift()!;
    if (reply instanceof ErrorReply) {
      reject(reply);
    } else {
      resolve(reply);
    }
  },
});
```

`RESP2Decoder` will decode the response and call `onReply`.
`RedisCommandQueue.#waitingForReply` will pop a node so that it can finally settle to the Promise that was created in `RedisCommandQueue.addCommand`.

What a journey! I feel great understanding how all this works.

[redis-client-class]: https://github.dev/redis/node-redis/blob/bf80c163b1305a859baa3dbc0bd6488c300e7a4f/packages/client/lib/client/index.ts#L74
[redis-socket-class]: https://github.dev/redis/node-redis/blob/23b65133c9610c44f336199a1ea73e77a9b73bc7/packages/client/lib/client/socket.ts#L32
[initiator-call]: https://github.dev/redis/node-redis/blob/23b65133c9610c44f336199a1ea73e77a9b73bc7/packages/client/lib/client/socket.ts#L108
[command-queue]: https://github.dev/redis/node-redis/blob/0752f143a6dbc83df0a5db987907e8794aabe9db/packages/client/lib/client/commands-queue.ts#L53
[yallist]: https://www.npmjs.com/package/yallist
[cork]: https://baus.net/on-tcp_cork/
[socket-write]: https://nodejs.org/api/net.html#socketwritedata-encoding-callback
[node-backpressure]: https://ey3ball.github.io/posts/2014/07/17/node-streams-back-pressure/
