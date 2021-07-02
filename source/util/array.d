module util.array;

import std.traits;
import std.string;

int index(T, U)(T[] src, U target) if(isImplicitlyConvertible!(U, T)){
  foreach(i; 0..src.length){
    if(src[i] == target){
      return i;
    }
  }
  return -1;
}

bool includePart(C, D)(C[] source, D target) if(isSomeString!(C) &&  isSomeString!(D)){
  foreach(t; source){
    if(target.indexOf(t, CaseSensitive.no) >= 0){
      return true;
    }
  }
  return false;
}

bool include(T, U)(T[] source, U target) if(isImplicitlyConvertible!(U, T)){
  foreach(t; source){
    if(t == target){
      return true;
    }
  }
  return false;
}
