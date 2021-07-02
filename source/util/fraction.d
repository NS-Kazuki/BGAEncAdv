module util.fraction;

import std.bigint;
import std.traits;

import util.code;

version(unittest){
  import std.stdio;
}

alias fractionI = fraction!(int);
alias fractionL = fraction!(long);
alias fractionB = fraction!(BigInt);

//分数
struct fraction(T) if(isIntegral!(T) || is(T == BigInt)){
  T numerator = 0; /// 分子
  static if(isIntegral!(T)){
    Unsigned!(T) denominator = 1; /// 分母
  }else{
    T denominator = 1; /// 分母
  }
  //
  unittest{
    writefln("fraction.opBinary");
    fractionL a = {3, 5};
    fractionL b = {5, 8};
    a = a + 2;
    b = b - a;
    assert(a.numerator == 13 && a.denominator == 5);
    assert(b.numerator == -79 && b.denominator == 40);
  }
  //
  fraction!(T) opAssign(U)(U rhs) if(isIntegral!(U) || is(U == BigInt)){
    numerator = rhs;
    denominator = 1;
    return this;
  }
  //
  fraction!(T) opAssign(U : fraction!(V), V)(U rhs) if(isAssignable!(T, V)){
    numerator = rhs.numerator;
    denominator = rhs.denominator;
    return this;
  }
  //
  fraction!(T) opBinary(string op, U)(U rhs) if(isIntegral!(U) || is(U == BigInt)){
    fraction result;
    static if(op == "+"){
      result.numerator = numerator + rhs * denominator;
      result.denominator = denominator;
    }else static if(op == "-"){
      result.numerator = numerator - rhs * denominator;
      result.denominator = denominator;
    }else static if(op == "*"){
      result.numerator = numerator * rhs;
      result.denominator = denominator;
      result.reduct();
    }else static if(op == "/"){
      result.numerator = numerator;
      result.denominator = denominator * rhs;
      result.reduct();
    }
    return result;
  }
  //
  fraction!(T) opBinary(string op, U : fraction!(V), V)(U rhs){
    fraction result;
    static if(op == "+"){
      result.numerator = numerator * rhs.denominator + rhs.numerator * denominator;
      result.denominator = denominator * rhs.denominator;
      result.reduct();
    }else static if(op == "-"){
      result.numerator = numerator * rhs.denominator - rhs.numerator * denominator;
      result.denominator = denominator * rhs.denominator;
      result.reduct();
    }else static if(op == "*"){
      result.numerator = numerator * rhs.numerator;
      result.denominator = denominator * rhs.denominator;
      result.reduct();
    }else static if(op == "/"){
      result.numerator = numerator * rhs.denominator;
      result.denominator = denominator * rhs.numerator;
      result.reduct();
    }
    return result;
  }
  //
  long opCmp(U)(const U obj) const if(isIntegral!(U)){
    return (numerator - cast(Signed!(T))(obj * denominator));
  }
  //
  long opCmp(U : BigInt)(const U obj) const{
    return ((numerator - obj * denominator).toLong);
  }
  //
  long opCmp(U : fraction!(V), V)(const U obj) const{
    return (numerator * obj.denominator - cast(Signed!(T))(obj.numerator * denominator));
  }
  //
  real decimal(){
    static if(isIntegral!(T)){
      return(cast(real)numerator / denominator);
    }else{
      return 0.0;
    }
  }
  //
  fraction!(T) reverse(){
    if(numerator < 0){
      return fraction!(T)(-denominator, -numerator);
    }else{
      return fraction!(T)(denominator, numerator);
    }
  }
  //
  void reduct(){
    //
    T i;
    T j;
    if(numerator < 0){
      i = -numerator % denominator;
    }else{
      i = numerator % denominator;
    }
    if(i == 0){
      numerator /= denominator;
      denominator = 1;
      return;
    }
    j = denominator % i;
    if(j == 0){
      numerator /= i;
      denominator /= i;
      return;
    }
    while(true){
      i %= j;
      if(i == 0){
        numerator /= j;
        denominator /= j;
        return;
      }
      j %= i;
      if(j == 0){
        numerator /= i;
        denominator /= i;
        return;
      }
    }
  }
}

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
