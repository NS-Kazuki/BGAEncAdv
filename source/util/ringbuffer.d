module util.ringbuffer;

version(unittest){
  import std.stdio;
}

import std.traits;

alias RingBuffer!(char) RingBufferC;
alias RingBuffer!(byte) RingBufferB;
alias RingBuffer!(ubyte) RingBufferUB;
alias RingBuffer!(short) RingBufferS;
alias RingBuffer!(ushort) RingBufferUS;
alias RingBuffer!(int) RingBufferI;
alias RingBuffer!(uint) RingBufferUI;
alias RingBuffer!(long) RingBufferL;
alias RingBuffer!(ulong) RingBufferUL;
alias RingBuffer!(float) RingBufferF;
alias RingBuffer!(double) RingBufferD;
alias RingBuffer!(real) RingBufferR;

class RingBuffer(T){
  private{
    T[] buffer;
    size_t _point;
  }
  //
  unittest{
    int[] i_result;
    RingBufferI buf = new RingBufferI(5);
    buf.write([1, 2, 3]);
    i_result = buf.read(2, 0);
    assert(buf.point == 3);
    assert(i_result == [2, 3]);
    //
    buf.write([4, 5, 6, 7].ptr, 4);
    buf.read(i_result, 1);
    assert(buf.point == 2);
    assert(i_result == [5, 6]);
    //
  }
  //
  public{
    this(size_t size){
      buffer.length = size;
      _point = 0;
    }
    //
    size_t point(){
      return _point;
    }
    //
    T[] read(size_t size, size_t start = 0)
    in{
      assert(buffer.length > start + size);
      assert(_point > start + size);
    }
    do{
      T[] result;
      result.length = size;
      if(start > _point){
        result[0..(buffer.length-start)] = buffer[(_point-start+buffer.length)..$];
        result[(buffer.length-start)..$] = buffer[0..(_point-start+size)];
      }else{
        result = buffer[(_point-start-size)..(_point-start)];
      }
      return result;
    }
    //
    void read(ref T[] result, size_t start = 0)
    in{
      assert(buffer.length >= start);
    }
    do{
      Signed!(size_t) end;
      end = _point - start;
      if(_point <= start){
        end += buffer.length;
      }
      if(end < result.length){
        result[0..(result.length-end)] = buffer[(buffer.length-(result.length-end))..$];
        result[(result.length-end)..$] = buffer[0..end];
      }else{
        result = buffer[(end-result.length)..end];
      }
    }
    //
    void write(T[] dest)
    in{
      assert(buffer.length >= dest.length);
    }
    do{
      if(_point + dest.length > buffer.length){
        buffer[_point..$] = dest[0..(buffer.length - _point)];
        buffer[0..(_point + dest.length - buffer.length)] = dest[(buffer.length - _point)..$];
      }else{
        buffer[_point..(_point+dest.length)] = dest;
      }
      _point = (_point + dest.length) % buffer.length;
    }
    //
    void write(T* dest, size_t size)
    in{
      assert(buffer.length >= size);
    }
    do{
      if(_point + size >= buffer.length){
        buffer[_point..$] = dest[0..(buffer.length - _point)];
        buffer[0..(_point + size - buffer.length)] = dest[(buffer.length - _point)..size];
      }else{
        buffer[_point..(_point+size)] = dest[0..size];
      }
      _point = (_point + size) % buffer.length;
    }
  }
}
