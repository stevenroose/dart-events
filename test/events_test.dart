// The MIT License (MIT)
// Copyright (c) 2016 Steven Roose

library events.test;

import "package:unittest/unittest.dart";

import "dart:async";

import "package:events/events.dart";

class TestEmitter extends Object with Events {



}

void _randomTest() {

  var ev1, ev2;
  var emitter = new TestEmitter();

  emitter.emit(Error, "test");

  emitter.on(Error, (var data) => print(" ${data.toString()}"));

  emitter.emit(Error, "test1");
  emitter.emit(Error, "test2");

  var sub = emitter.on(Error).listen((var data) => print(data.toString()));

  emitter.emit(Error, "test3");

  sub.pause();

  emitter.emit(Error, "test4");

  sub.resume();

  emitter.once(Error, (data) => print("kaka ${data.toString()}"));


  emitter.emit(Error, "pipi");

  new Timer(new Duration(seconds: 1), () {
    sub.cancel();
    new Timer(new Duration(seconds: 1), () {
      emitter.emit(new ArgumentError("snot"));
    });
  });




}

void _emittingStringsAndInts() {
  Function stringFoo = (o) {
    expect(o, isNotNull);
    expect(o, new isInstanceOf<String>());
  };
  Function intFoo = (o) {
    expect(o, isNotNull);
    expect(o, new isInstanceOf<int>());
  };
  var emitter = new TestEmitter();

  var sub = emitter.on(String).listen(expectAsync(stringFoo, count: 2));
  emitter.on(int).listen(expectAsync(intFoo, count: 1));
  emitter.on(String).listen(expectAsync(stringFoo, count: 3));
  emitter.once(String).then(expectAsync(stringFoo, count: 1));

  emitter.emit("test");
  emitter.emit(5);
  emitter.emit(String, "test2");

  emitter.once(String).then(expectAsync(stringFoo, count: 1));
  new Timer(new Duration(milliseconds: 5), () {
    sub.cancel();
    new Timer(new Duration(milliseconds: 5), () {
      emitter.emit("delayed");
    });
  });
}

void _shorthandEmittingStringsAndInts() {
  Function stringFoo = (o) {
    expect(o, isNotNull);
    expect(o, new isInstanceOf<String>());
  };
  Function intFoo = (o) {
    expect(o, isNotNull);
    expect(o, new isInstanceOf<int>());
  };
  var emitter = new TestEmitter();
  emitter.on(String, expectAsync(stringFoo, count: 2));
  emitter.on(int, expectAsync(intFoo, count: 1));
  emitter.on(String, expectAsync(stringFoo, count: 2));
  emitter.once(String, expectAsync(stringFoo, count: 1));
  emitter.emit("test");
  emitter.emit(5);
  emitter.emit("test2");
}


void main() {
  group("events", () {
    test("emitting_String_ints", () => _emittingStringsAndInts());
    test("emitting_String_ints_shorthand", () => _shorthandEmittingStringsAndInts());
  });
}