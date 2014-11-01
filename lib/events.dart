library events;

import "dart:async";
@MirrorsUsed(override: "*", symbols: "")
import "dart:mirrors";

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

/**
 * Returns a function that is used to filter a stream for events of type [eventType].
 */
Function _eventTypeMatcher(dynamic eventType) => (_Event event) {
  if(eventType == event.type)
    return true;
  if(eventType is Type && event.type is Type)
    return reflectType(event.type).isSubtypeOf(reflectType(eventType));
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

  final StreamController<_Event> _eventStreamController = new StreamController<_Event>.broadcast();


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
  void emit(dynamic event, [dynamic data = const _Nothing()]) {
    if(data is _Nothing)
      _eventStreamController.add(new _Event(event.runtimeType, event));
    else
      _eventStreamController.add(new _Event(event, data));
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
  dynamic on([dynamic eventType, Function onEvent]) {
    Stream filteredStream = eventType != null ?
        _eventStreamController.stream.where(_eventTypeMatcher(eventType)).map(_eventDataMapper) :
        _eventStreamController.stream.map(_eventDataMapper);
    return onEvent != null ? filteredStream.listen(onEvent) : filteredStream;
  }

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
    Future onceEvent = _eventStreamController.stream.firstWhere(_eventTypeMatcher(eventType)).then(_eventDataMapper);
    if(onEvent != null)
      onceEvent.then(onEvent);
    return onceEvent;
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
 * It can also be used as an interface or superclass as follows:
 *     class ResultEvent extends EventType<Result> {}
 *     class Finished extends ResultEvent {}
 *     emitter.on(Finished).listen((Result res) => handleResult(res));
 *
 * In Java, this is the most common way to describe events, but it
 * is almost always done using inner classes, which Dart does not support.
 */
class EventType<T> {
  EventType();
}