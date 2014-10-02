Event handling library for Dart.
=======
[![Build Status](https://drone.io/github.com/stevenroose/dart-events/status.png)](https://drone.io/github.com/stevenroose/dart-events/latest)

This project introduces a class to be used as a mixin to allow a class to act as an event emitter
to which others can subscribe.
Several event-related projects existed, but none of them offered the flexibility and simplicity that I wanted,
so I created events.

Events uses built-in classes from `dart:async` to handle synchronicity. Event streams are represented as `Stream`
objects and subscriptions as `StreamSubscription`s. This allows users to perform additional operations like
filtering or mapping on the incoming events.

# Event type and data schemes

Several different schemes exist for event emitting, based on Java's or Node's most popular packages.
This library supports several different options, without adding overhead to the use of it.

Firstly, events allows to use objects as events and subscribe based on the type of object emitted:
```dart
// to emit:
emitter.emit(new SuccessEvent());
// to subscribe:
emitter.on(SuccessEvent).listen((SuccessEvent e) => doStuff(e));
```

Secondly, you can also use objects or strings as event types, and provide additional data separately:
```dart
// to emit:
emitter.emit("success", new Result());
// to subscribe:
emitter.on("success").listen((Result r) => doStuff(r));
```

Thirdly, events provides a class `EventType`, that can be used to define custom event types and define the type of
data that accompany the events (know that every object can be used as an event type, so this class is only indicative):
```dart
EventType Success = new EventType<Result>();
// to emit:
emitter.emit(Success, new Result());
// to subscribe:
emitter.on(Success).listen((Result r) => doStuff(r));
```

# Shorthand notation

Because many libraries in other languages use a different, shorter notation, events provides this notation as well.
Following statements are pairwise equivalent:
```dart
// subscribing
emitter.on(Success).listen(eventHandler);
emitter.on(Success, eventHandler);
// subscribing only to the first next event
emitter.once(Success).then(eventHandler);
emitter.once(Success, eventHandler);
```

You can also subscribe to all events from an event emitter as follows:
```dart
emitter.on().listen(eventHandler);
```

# Unsubscribing and event streams

The `on()` subscription method normally returns a `Stream` object that contains all incoming events. You listen
to it using the `listen()` method. `listen()` returns a `StreamSubscription` that is required to unsubscribe later.
```dart
Stream successStream = emitter.on(Success);
StreamSubscription successSubscription = successStream.listen((e) => handleSuccess(e));
// to cancel subscription:
successSubscription.cancel();
```

Using the shorthand notation, the `on()` method returns the `StreamSubscription` directly:
```dart
var sub = emitter.on(Success, (e) => handleSuccess(e));
// unsub:
sub.cancel();
```

One-time subscriptions return `Future` objects and are not cancellable.
```dart
Future onSuccess = emitter.once(Success);
onSuccess.then((e) => handleSuccess(e));
// or shorter:
Future f = emitter.once(Success, (e) => handleSuccess(e));
// the Future onSuccess and f above are the same future
```
