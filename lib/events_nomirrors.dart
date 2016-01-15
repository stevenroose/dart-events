// The MIT License (MIT)
// Copyright (c) 2016 Steven Roose

library events.nomirrors;

import "dart:async";

import "package:stevenroose/lru_map.dart";

/**
 * Used internally to represent an event and the accompanying data.
 */
class _Event {
  final type;
  final data;
  const _Event(this.type, this.data);
}

/**
 * Used solely to differentiate between an unset parameter and an explicit null value.
 */
class _Nothing {
  const _Nothing();
}
const _nothing = const _Nothing();

/**
 * Returns a function that is used to filter a stream for events of type [eventType].
 */
Function _eventTypeMatcher(dynamic eventType) => (_Event event) {
  if(eventType == event.type) {
    return true;
  }
  return false;
};

/**
 * Map an event to its accompanying data.
 */
dynamic _eventDataMapper(_Event event) => event.data;

/**
 * This mixin enables classes to act as an event emitter to which
 * other objects can listen.
 */
class Events {

  /**
   * The controller of the main event stream.
   */
  final StreamController<_Event> _eventStreamController = new StreamController<_Event>.broadcast();

  /**
   * Stream cache.
   * Caching filtered streams avoids creating a new WhereStream every time [on()] is called and
   * reduces the amount of CPU work for new events when there are a lot of subscribers.
   *
   * The number of cached event streams is chosen arbitrarily.
   */
  static const int _STREAM_CACHE_SIZE = 25;
  final LRUMap _streamCache = new LRUMap(capacity: _STREAM_CACHE_SIZE);


  /**
   * Emit a new event.
   *
   * Two options are supported:
   *
   * 1. specify an event type and data
   *
   *     emit("response", newResponse)
   *   will trigger `on("response")` with data `newResponse`.
   *   The event type can be anything: `emit(Error, "some_error")`
   *
   * 2. specify an event only
   *
   *     emit(new Error("something went wrong"))`\
   *   will trigger `on(Error)` with data `new Error(...)`
   *
   * The second method is equivalent to the first method in the following way:
   *     emit(new Error("oh noo")) <=> emit(Error, new Error("oh noo"))
   *     emit("text") <=> emit(String, "text")
   *
   * If you want to trigger an event type only, without accompanying data,
   * set data to null explicitly, like this:
   *     emit("event_type", null)
   */
  void emit(dynamic event, [dynamic data = _nothing]) {
    if(data == _nothing) {
      _eventStreamController.add(new _Event(event.runtimeType, event));
    } else {
      _eventStreamController.add(new _Event(event, data));
    }
  }

  /**
   * Listen to new events of type [eventType].
   * Returns a [Stream] of events.
   *
   * Calling without parameters will subscribe to all events.
   *
   * In normal use, this returns a [Stream] of events to which
   * can be listened with the `listen()` method. `listen()` will
   * return a [StreamSubscription] that is required to cancel the
   * subscription.
   *     Stream eventStream = emitter.on(Error);
   *     StreamSubscription sub = eventStream.listen((e) => print(e));
   *     sub.cancel();
   * or shorter `emitter.on(Error).listen((e) => print(e));`
   *
   * [onEvent] allows the use of a shorthand notation as follows:
   *     emitter.on(Error, (e) => print(e))
   * In this case, it will return a [StreamSubscription] immediately,
   * to cancel the subscription as follows:
   *     var sub = emitter.on(Error, (e) => print(e));
   *     sub.cancel();
   */
  dynamic/*Stream|StreamSubscription*/ on([dynamic eventType, Function onEvent]) {
    Stream filteredStream = _getFilteredStream(eventType);
    return onEvent != null ? filteredStream.listen(onEvent) : filteredStream;
  }

  /**
   * Tries to fetch the stream from cache and creates and caches the stream of it was not cached.
   */
  Stream _getFilteredStream(dynamic eventType) {
    Stream stream = _streamCache[eventType];
    if(stream == null) {
      stream = _createFilteredStream(eventType);
      _streamCache[eventType] = stream;
    }
    return stream;
  }

  /**
   * Create a stream that filters events of type [eventType].
   */
  Stream _createFilteredStream(dynamic eventType) => eventType != null ?
  _eventStreamController.stream.where(_eventTypeMatcher(eventType)).map(_eventDataMapper) :
  _eventStreamController.stream.map(_eventDataMapper);

  /**
   * Wait for the first occurrence of type [eventType].
   *
   * Returns a [Future] of the event, to which an action can be coupled using `then()`:
   *     eventObject.once(Error).then((e) => throw e)
   *
   * [onEvent] allows the use of a shorthand notation as follows:
   *     eventObject.once(Error, (e) => throw e)
   */
  Future once([dynamic eventType, Function onEvent]) {
    Future onceEvent = _getFilteredStream(eventType).first;
    return onEvent != null ? onceEvent.then(onEvent) : onceEvent;
  }
}

/**
 * The use of this class is optional and only indicative.
 *
 * It can be used to create event types and indicate what type of data will
 * accompany the event.
 *
 * For example:
 *     EventType<Result> finished = new EventType<Result>();
 *     emitter.on(finished).listen((Result res) => handleResult(res));
 *
 * The recommended way of specifying event types for an emitter class, is to define
 * them in static variables using the EventType class.
 *
 *     class MyEmitter extends Object with Events {
 *       static final EventType FINISHED = new EventType<Result>();
 *       void doAsyncStuff() {
 *         [...]
 *         emit(FINISHED, resultingData);
 *       }
 *     }
 *
 *     void main() {
 *       myEmitter.on(MyEmitter.FINISHED).listen((Result result) => useResult(result));
 *     }
 *
 * In Java, the most common way to describe event types is to use inner classes
 * like in the example above. However Dart does not support this. One way around
 * the restriction is to do something like this example:
 *
 *     class ResultEvent extends EventType<Result> {}
 *     class Finished extends ResultEvent {}
 *     emitter.on(Finished).listen((Result res) => handleResult(res));
 *
 */
class EventType<T> {
  EventType();
}