/**
 * メモリバッファストリームのクラス
 * 
 * License:   Public Domain
 * Date:      August 21, 010
 * Author:    Kazuki Okawa, naka4959@kcn.ne.jp
 * 
 * Version:   0.01
 * History:
 *  v0.01 公開
 * 
*/
module ngbase.streambuffer;

import core.memory;

import std.stdio;
import std.traits;
import core.stdc.string;

enum SeekPos{
  SET = SEEK_SET,
  CUR = SEEK_CUR,
  END = SEEK_END,
}


/**
 * メモリストリームのクラス
*/
class StreamBuffer{
  private{
    ubyte[] data; // バッファの先頭位置
    size_t point; // 読み書きを行う位置
  }
  public{
    /**
     * 特定の領域を，StreamBufferとして宣言
     * 
     * Params:
     *  buffer = StreamBufferで管理するバッファ
     *  size = バッファの大きさ
     *  access = 読み書きが可能であるかどうか
     *
     * Throws:
     *  バッファの領域が存在しない場合，StreamException<br>
     *  読み書きのどちらも出来ない場合，StreamException
     *
     * Example: 
     *  外部で宣言した領域を，読み込みと読み書きのstringioとして宣言
     * ---
     * int size = 256;
     * ubyte* buffer = cast(ubyte*)malloc(size);
     * auto a = new StreamBuffer(buffer, size, accessible.READ);
     * auto b = new StreamBuffer(buffer, size, accessible.READ | accessible.WRITE);
     * ---
    */
    this(ubyte[] buf){
      if(buf.length == 0){
        throw(new Exception("Buffer isn't exist"));
      }
      this.data = buf;
      this.point = 0;
    }
    /**
     * バッファのポインタを取得する
     *
     * Returns:
     *  バッファの先頭位置
    */
    ubyte* buffer(){
      return(this.data.ptr);
    }
    /**
     * バッファのサイズを取得する
     *
     * Returns:
     *  バッファのサイズ
    */
    size_t size(){
      return(this.data.length);
    }
    /**
     * バッファが終端かどうかを取得する
     *
     * Returns:
     *  バッファが終端ならtrue、そうでないならfalse
    */
    bool eof(){
      return(point >= this.data.length);
    }
    /**
     * バッファからデータを読み込む<br>
     * 残り領域以上に読み込もうとした場合，残り領域全てを読み込む
     *
     * Params:
     *  buffer = データが読み込まれる領域の先頭ポインタ
     *  size = 読み込むデータの大きさ
     * 
     * Returns:
     *  読み込めたバイト数
     * 
     * Throws:
     *  読み込みを許可していない場合，ReadException
    */
    size_t read(T)(ref T[] buffer, in size_t _length = 0){
      size_t result;
      size_t length = _length;
      if(length == 0 || length > T.sizeof * buffer.length){
        length = T.sizeof * buffer.length;
      }

      if(length + this.point > cast(size_t)this.data.length){
        result = cast(size_t)(this.data.length - this.point);
      }else{
        result = length;
      }
      memcpy(buffer.ptr, &this.data[cast(size_t)this.point], length);
      this.point += result;
      return(result);
    }
    size_t read(T)(ref T* buffer, in size_t _length = 0){
      size_t result;
      size_t length = _length;
      if(length == 0){
        length = T.sizeof;
      }

      if(length + this.point > cast(size_t)this.data.length){
        result = cast(size_t)(this.data.length - this.point);
      }else{
        result = length;
      }
      memcpy(buffer, &this.data[cast(size_t)this.point], length);
      this.point += result;
      return(result);
    }
    size_t read(T)(ref T buffer, in size_t _length = 0) if(!isPointer!(T) && !isDynamicArray!(T)){
      size_t result;
      size_t length = _length;
      if(length == 0){
        length = T.sizeof;
      }

      if(length + this.point > cast(size_t)this.data.length){
        result = cast(size_t)(this.data.length - this.point);
      }else{
        result = length;
      }
      memcpy(&buffer, &this.data[cast(size_t)this.point], length);
      this.point += result;
      return(result);
    }
    unittest{
      string src = "Nageyari Software";
      ubyte[32] dest;
      writeln("Unittest StreamBuffer.read");
      auto io = new StreamBuffer(src);
      io.readExact(dest.ptr, 8);
      assert(dest[0..8] == "Nageyari");
      assert(io.read(dest) == src.length - 8);
      assert(dest[0..src.length-8] == " Software");
    }
    /**
     * バッファをシークする<br>
     * 範囲外の位置を選択した場合，範囲の端に移動する
     *
     * Params:
     *  offset = 変更した後の位置，規準位置からの相対位置で指定する
     *  whence = シークの規準位置
     * 
     * Returns:
     *  変更された現在位置
     * 
     * Throws:
     *  定義されていない規準位置を指定した場合，SeekException
    */
    size_t seek(Signed!(size_t) offset, SeekPos whence){
      Signed!(size_t) base;
      switch(whence){
      case SeekPos.SET:
        base = 0;
        break;
      case SeekPos.CUR:
        base = this.point;
        break;
      case SeekPos.END:
        base = this.data.length;
        break;
      default:
        throw(new Exception("Unknown seekpos"));
      }
      if(base + offset < 0){
        this.point = 0;
      }else if(base + offset > this.data.length){
        this.point = this.data.length;
      }else{
        this.point = base + offset;
      }
      return(this.point);
    }
    unittest{
      writeln("Unittest StreamBuffer.seek");
      string src = "Nageyari Software";
      auto io = new StreamBuffer(cast(ubyte[])src, accessible.READ);
      io.seek(3, SeekPos.Set);
      assert(io.position == 3);
      io.seek(-2, SeekPos.Current);
      assert(io.position == 1);
      io.seek(-9, SeekPos.End);
      assert(io.position == 8);
    }
    /// 現在位置の取得
    size_t tell(){
      return this.point;
    }
    /* 解放 */
    ~this(){
    }
  }
}
