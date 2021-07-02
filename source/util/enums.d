/**
 * ライブラリの様々な箇所で使われる汎用関数群。
 *
 * This file is part of Nageyari Gamebase.
 * 
 * License:   Public Domain
 * Date:      August 21, 2010
 * Author:    Kazuki Okawa, naka4959@kcn.ne.jp
*/
module util.enums;

version(unittest){
  import std.stdio;
}

/*
 * 列挙型の要素が正しいかどうかの判定
 *
 * Params:
 *  code = 判定を行う要素
 *
 * Throws:
 *  列挙体にその値が存在すればtrue、存在しなければfalse
*/
bool in_enum(T)(in T code){
  foreach(mem; __traits(allMembers, T)){
    if(code == __traits(getMember, T, mem)){
      return true;
    }
  }
  return false;
}
unittest{
  enum test_enum{
    RED,
    BLUE,
    GREEN
  }
  writefln("unittest in_enum");
  assert(in_enum(test_enum.BLUE) == true);
  assert(in_enum(cast(test_enum)0x02) == true);
  assert(in_enum(cast(test_enum)0xFF) == false);
}

/*
 * 型のビットサイズを返す
 * 
 * Params:
 *  T = 処理を行う型
 *
 * Returns:
 *  型のビットサイズ
*/

template bit_size(T){
  uint bit_size = T.sizeof * 8;
}

unittest{
  writefln("unittest bit_size");
  assert(bit_size!(uint) == 32);
}
