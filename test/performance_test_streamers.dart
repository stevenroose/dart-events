import 'package:streamers/streamers.dart';
import 'dart:async';

abstract class TestInterface{int val;}
class A implements TestInterface{int val;}
class B extends A{}
class C extends B{}
class D extends C{}
class E extends D{}
class F extends E{}
class G extends F{}
class H extends G{}
class I extends H{}
class J extends I{}
class K extends J{}
class L extends K{}
class M extends L{}
class N extends M{}
class O extends N{}
class P extends O{}
class Q extends P{}
class R extends Q{}
class S extends R{}
class T extends S{}
class U extends T{}
class V extends U{}
class W extends V{}
class X extends W{}
class Y extends X{}
class Z extends Y{}
class DoesntInherit{int val;}
class GenericsA<T>{int val;}
class GenericsB<T> extends GenericsA<T>{}

void main() {
  /**
   * configure test run with the following variables
   */
  int numOfObjToEmit = 100000;
  int numOfDumbSubs = 200;
  Function emitObj = () => new Z();
  Type typeToListenTo = A;
  /**
   * End of config variables.
   */

  executePerformanceTest(numOfObjToEmit, numOfDumbSubs, emitObj, typeToListenTo);
}

Future executePerformanceTest(int numOfObjToEmit, int numOfDumbSubs, Function emitObj, Type typeToListenTo){
  Completer completer = new Completer();
  Stopwatch stopwatch = new Stopwatch();
  Emitter emitter = new Emitter();
  var dumbHandler = (obj){};
  var actualHandler = (obj){
    if(obj.val == numOfObjToEmit - 1){
      stopwatch.stop();
      print('Emitting $numOfObjToEmit ${emitObj().runtimeType} whilst listening to $typeToListenTo, by $numOfDumbSubs handlers took: ${stopwatch.elapsed}');
      if(!completer.isCompleted) completer.complete();
    }
  };

  // subscribe handlers
  emitter.on(All).listen(actualHandler);
  for(var i = 0; i < numOfDumbSubs; i++){
    emitter.on(typeToListenTo).listen(dumbHandler);
  }

  // emit objects and start timing
  stopwatch.start();
  for(var i = 0; i < numOfObjToEmit; i++){
    emitter.emit(emitObj()..val = i);
  }

  return completer.future;
}