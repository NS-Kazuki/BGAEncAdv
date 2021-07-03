module util.math;

import std.traits;
import std.bigint;
import util.fraction;

version(unittest){
  import std.stdio;
}

/*
 * 
*/
unittest{
  writefln("load.get_LCM");
  fractionI a = {34, 25};
  fractionI b = {7, 5};
  fractionI c = {238, 5};
  fractionI d = {7, 5};
  fractionI e = {11, 3};
  fractionI f = {77, 1};
  fractionI g = {34, 1};
  assert(get_LCM(7, 13) == 7 * 13);
  assert(get_LCM(35, 65) == 5 * 7 * 13);
  assert(get_LCM(get_LCM(120, 140), 160) == 3360);
  assert(get_LCM(a, b) == c);
  assert(get_LCM(d, e) == f);
  assert(get_LCM(a, 17) == g);
}
T get_LCM(T, U)(T a, U b) if(isIntegral!(T) && isIntegral!(U))
out{
  assert(a == 0 || b == 0 || (__result % a == 0 && __result % b == 0));
}
do{
  //
  static if(T.sizeof > U.sizeof){
    T i;
    T j;
  }else{
    U i;
    U j;
  }
  if(a == 0){
    return b;
  }
  if(b == 0){
    return a;
  }
  i = a % b;
  if(i == 0){
    return a;
  }
  j = b % i;
  if(j == 0){
    return a / i * b;
  }
  while(true){
    i %= j;
    if(i == 0){
      return a / j * b;
    }
    j %= i;
    if(j == 0){
      return a / i * b;
    }
  }
}
//
U get_LCM(T, U)(T a, U b) if(isIntegral!(T) && is(U == BigInt)){
  return get_LCM(b, a);
}
//
T get_LCM(T, U)(T a, U b) if(is(T == BigInt) && (isIntegral!(U) || is(U == BigInt))){
  //
  T i;
  T j;
  if(a == 0){
    static if(is(U == BigInt)){
      return b;
    }else{
      return BigInt(b);
    }
  }
  if(b == 0){
    return a;
  }
  i = a % b;
  if(i == 0){
    return a;
  }
  j = b % i;
  if(j == 0){
    return a * b / i;
  }
  while(true){
    i %= j;
    if(i == 0){
      return a * b / j;
    }
    j %= i;
    if(j == 0){
      return a * b / i;
    }
  }
}
T get_LCM(T : fraction!(V), U, V)(ref T a, U b) if((isIntegral!(U) || is(U == BigInt)) && isAssignable!(V, U)){
  T result;
  result.numerator = get_LCM(a.numerator, b);
  result.denominator = 1;
  result.reduct();
  return result;
}
//
T get_LCM(T : fraction!(V), U : fraction!(W), V, W)(ref T a, ref U b){
  T result;
  V d;
  d = get_LCM(a.denominator, b.denominator);
  result.numerator = get_LCM(a.numerator * (d / a.denominator), b.numerator * (d / b.denominator));
  result.denominator = d;
  result.reduct();
  return result;
}
//
T get_GCD(T, U)(T a, U b) if(isIntegral!(T) && isIntegral!(U))
out{
  assert(a * b == 0 || a % __result == 0 && b % __result == 0);
}
do{
  //
  ulong i;
  ulong j;
  if(a == 0){
    return 0;
  }
  if(b == 0){
    return 0;
  }
  i = a % b;
  if(i == 0){
    return b;
  }
  j = b % i;
  if(j == 0){
    return i;
  }
  while(true){
    i %= j;
    if(i == 0){
      return j;
    }
    j %= i;
    if(j == 0){
      return i;
    }
  }
  return 0;
}
//
U get_GCD(T, U)(T a, U b) if(isIntegral!(T) && is(U == BigInt)){
  return get_GCD(b, a);
}
//
T get_GCD(T, U)(T a, U b) if(is(T == BigInt) && (isIntegral!(U) || is(U == BigInt))){
  //
  T i;
  T j;
  if(a == 0){
    static if(is(U == BigInt)){
      return b;
    }else{
      return BigInt(b);
    }
  }
  if(b == 0){
    return a;
  }
  i = a % b;
  if(i == 0){
    return b;
  }
  j = b % i;
  if(j == 0){
    return i;
  }
  while(true){
    i %= j;
    if(i == 0){
      return j;
    }
    j %= i;
    if(j == 0){
      return i;
    }
  }
}
