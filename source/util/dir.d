module util.dir;

import std.file;
import std.path;
import std.stdio;
import std.string;
import std.traits;

import core.memory;

import std.stdio;

string[][string] entries;

size_t bin_diff(T, U)(T[] a, U[] b) if(is(Unqual!(T) == Unqual!(U))){
  size_t result = 0;
  for(size_t i = 0; i < (a.length >= b.length ? a.length : b.length); i += 1){
    if(a != b){
      result += 1;
    }
  }
  return result + (a.length >= b.length ? a.length - b.length : b.length - a.length);
}

string load_path(string current){
  string dir;
  string fname;
  size_t diff = size_t.max;
  string result;
  dir = dirName(absolutePath(current));
  fname = current;
  if(dir !in entries){
    size_t i = 0;
    entries[dir].length = 256;
    foreach(s; dirEntries(dir, SpanMode.shallow)){
      if(entries[dir].length <= i){
        entries[dir].length += 128;
      }
      entries[dir][i] = s;
      i += 1;
    }
    entries[dir].length = i;
  }
  foreach(string s; entries[dir]){
    if(fname.toLower == s.toLower){
      if(fname == s){
        return current;
      }else if(diff > bin_diff(fname, s)){
        diff = bin_diff(fname, s);
        result = s;
      }
    }
  }
  return result;
}