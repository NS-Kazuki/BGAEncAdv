module util.fractionW;

import std.math;
import std.traits;

version(unittest){
  import std.stdio;
}

import std.stdio;

import util.code;
import util.fraction;

unittest{
  writefln("fraction.toFraction");
  fractionL a = toFraction!(long)("0.52");
  fractionL b = toFraction!(long)("-0.03125");
  fractionL c = toFraction!(long)("120.0");
  assert(a.numerator == 13);
  assert(a.denominator == 25);
  assert(b.numerator == -1);
  assert(b.denominator == 32);
  assert(c.numerator == 120);
  assert(c.denominator == 1);
}

bool isFraction(C)(C str) if(isSomeString!(C)){
  bool border = false;
  if(str.length == 0){
    return false;
  }
  if(str[0].toEN == '.'){
    border = true;
  }else if(str[0].toEN != '-' && (str[0].toEN < '0' || str[0].toEN > '9')){
    return false;
  }
  foreach(i; 1..str.length){
    if((str[i].toEN < '0' || str[i].toEN > '9') && (str[i] != '.' || border == true)){
      return false;
    }
  }
  return true;
}

fraction!(T) toFraction(T, C)(C str, bool abs = false) if(isSomeString!(C)){
  fraction!(T) result;
  bool zero = true;
  bool minus = false;
  bool border = false;
  if(str[0].toEN == '-'){
    minus = true;
  }else if(str[0].toEN == '.'){
    border = true;
  }else if(str[0].toEN > '0' && str[0].toEN <= '9'){
    result.numerator = (str[0].toEN - '0');
    zero = true;
  }
  foreach(i; 1..str.length){
    if(border){
      result.denominator *= 10;
    }
    if(str[i].toEN == '.'){
      border = true;
    }else if(zero == false){
      if(str[i].toEN > '0' && str[i].toEN <= '9'){
        result.numerator = result.numerator * 10 + (str[i].toEN - '0');
        zero = true;
      }
    }else if(str[i].toEN >= '0' && str[i].toEN <= '9'){
      result.numerator = result.numerator * 10 + (str[i].toEN - '0');
    }
  }
  if(!abs && minus){
    result.numerator *= -1;
  }
  if(!border || result.numerator == 0){
    result.denominator = 1;
  }
  result.reduct();
  return result;
}
