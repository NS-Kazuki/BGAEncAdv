module util.tointW;

import std.traits;
import util.code;

version(unittest){
  import std.stdio;
}

unittest{
  writefln("load.toDigit");
  string a = "120";
  string b = "-0824";
  string c = "1a4";
  assert(isDigit(a) == true);
  assert(toDigit(a) == 120);
  assert(isDigit(b) == true);
  assert(toDigit(b) == -824);
  assert(isDigit(c) == false);
}

bool isDigit(C)(C str) if(isSomeString!(C)){
  if(str.length == 0){
    return false;
  }
  if(str[0].toEN != '-' && (str[0].toEN < '0' || str[0].toEN > '9')){
    return false;
  }
  foreach(i; 1..str.length){
    if(str[i].toEN < '0' || str[i].toEN > '9'){
      return false;
    }
  }
  return true;
}

int toDigit(C)(C str, bool abs = false) if(isSomeString!(C)){
  int result = 0;
  bool zero = true;
  bool minus = false;
  if(str.length == 0){
    return 0;
  }
  if(str[0].toEN == '-'){
    minus = true;
  }else if(str[0].toEN >= '1' && str[0].toEN <= '9'){
    result = (str[0].toEN - '0');
    zero = true;
  }
  foreach(i; 1..str.length){
    if(zero == false){
      if(str[i].toEN >= '1' && str[i].toEN <= '9'){
        result = result * 10 + (str[i].toEN - '0');
        zero = true;
      }
    }else if(str[i].toEN >= '0' && str[i].toEN <= '9'){
      result = result * 10 + (str[i].toEN - '0');
    }
  }
  if(minus && !abs){
    return -result;
  }else{
    return result;
  }
}
//
unittest{
  writeln("load.toDecimal");
  assert(toDecimal("A") == 10);
  assert(toDecimal("11") == 37);
  assert(toDecimal("ZZ") == 36 * 36 - 1);
}

bool isDecimal(C)(C str) if(isSomeString!(C)){
  if(str.length == 0){
    return false;
  }
  if(str[0].toEN != '-' && (str[0].toEN < '0' || str[0].toEN > '9') && (str[0].toEN < 'A' || str[0].toEN > 'Z') && (str[0].toEN < 'a' || str[0].toEN > 'z')){
    return false;
  }
  foreach(i; 1..(str.length)){
    if((str[i].toEN < '0' || str[i].toEN > '9') && (str[i].toEN < 'A' || str[i].toEN > 'Z') && (str[i].toEN < 'a' || str[i].toEN > 'z')){
      return false;
    }
  }
  return true;
}

uint toDecimal(C)(C[] str) if(isSomeChar!(C)){
  bool zero = true;
  uint result = 0;
  foreach(C c; str){
    if(zero == false){
      result *= 36;
    }
    if(c.toEN >= '0' && c.toEN <= '9'){
      if(c.toEN != '0'){
        zero = false;
      }
      result += c.toEN - '0';
    }else if(c.toEN >= 'A' && c.toEN <= 'Z'){
      zero = false;
      result += c.toEN - 'A' + 10;
    }else{
      zero = false;
      result += c.toEN - 'a' + 10;
    }
  }
  return result;
}

unittest{
  writeln("load.toHex");
  assert(toHex("A") == 0x0A);
  assert(toHex("11") == 0x11);
  assert(toHex("FF") == 0xFF);
}

uint toHex(C)(C[] str) if(isSomeChar!(C)){
  bool zero = true;
  uint result = 0;
  foreach(C c; str){
    if(zero == false){
      result *= 16;
    }
    if(c.toEN >= '0' && c.toEN <= '9'){
      if(c.toEN != '0'){
        zero = false;
      }
      result += c.toEN - '0';
    }else if(c.toEN >= 'A' && c.toEN <= 'F'){
      zero = false;
      result += c.toEN - 'A' + 10;
    }else{
      zero = false;
      result += c.toEN - 'a' + 10;
    }
  }
  return result;
}
