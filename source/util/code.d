module util.code;

import std.array;
import std.algorithm;
import std.stdio;
import std.string;
import std.traits;

import util.enums;

import std.utf;
version(Windows){
  import core.sys.windows.windows;
}
version(Posix){
  import iconv.iconv;
  import core.stdc.string;
  alias iconv_convert = iconv.iconv.iconv;
}

import std.stdio;

private immutable uint BUFSIZE = 1024;

enum ACCESSIBLE{
  READ = "r",
  WRITE = "w",
  APPEND = "a",
  BINARY = "b",
  READ_BINARY = READ ~ BINARY,
  WRITE_BINARY = WRITE ~ BINARY,
  APPEND_BINARY = APPEND ~ BINARY,
}

version(Windows){
  enum Charset{
    ASCII = 0,
    SHIFTJIS = 1,
    UHC = 2,
    UTF8 = 3,
    UTF16LE = 4,
    UTF16BE = 5,
    UTF32LE = 6,
    UTF32BE = 7,
    DEFAULT
  }
}else{
  enum Charset{
    ASCII = 0,
    SHIFTJIS = 1,
    UHC = 2,
    UTF8 = 3,
    UTF16LE = 4,
    UTF16BE = 5,
    UTF32LE = 6,
    UTF32BE = 7,
    DEFAULT
  }
}

enum ConvertType{
  UPPER = 0x01,
  LOWER = 0x02,
  EN = 0x04,
  EM = 0x08,
}

/+
class SwapFile : File{
  this(){
    super();
  }
  this(string filename, FileMode mode = FileMode.In){
    super(filename, mode);
  }
  /*
   *
  */
  wchar[] readLineSwap(bool swap = false){
    return readLineSwap(null, swap);
  }
  /*
   *
  */
  wchar[] readLineSwap(wchar[] result, bool swap = false){
    size_t strlen = 0;
    wchar cr;
    wchar lf;
    if(swap){
      cr = ('\r' >> 8 | '\r' << 8);
      lf = ('\n' >> 8 | '\n' << 8);
    }else{
      cr = '\r';
      lf = '\n';
    }
    wchar c = getcw();
    while(readable){
      if(c == cr){
        if(seekable){
          c = getcw();
          if(c != lf){
            ungetcw(c);
          }
        }else{
          prevCr = true;
        }
      }
      if(c == lf || c == wchar.init){
        result.length = strlen;
        return result;
      }else if(c != cr){
        if(strlen < result.length){
          result[strlen] = c;
        }else{
          result ~= c;
        }
        strlen++;
      }
      c = getcw();
    }
    result.length = strlen;
    return result;
  }
}

C swap(C)(C c) if(isSomeChar!(C)){
  static if(C.sizeof == 1){
    return c;
  }else static if(C.sizeof == 2){
    return (cast(C)(c >> 8) | cast(C)(c << 8));
  }else static if(C.sizeof == 4){
    return ((c >> 24) | ((c >> 8) & 0xFF00) | ((c << 8) & 0xFF0000) | (c << 24));
  }
}

C[] swap(C)(C[] str, Charset incode) if(isSomeChar!(C))
in{
  assert(in_enum(incode));
  assert(get_size(incode) == C.sizeof);
}
do{
  static if(C.sizeof == 1){
    return str;
  }else{
    version(BigEndian){
      if(incode == Charset.UTF16BE || incode == Charset.UTF32BE){
        return str;
      }
    }
    version(LittleEndian){
      if(incode == Charset.UTF16LE || incode == Charset.UTF32LE){
        return str;
      }
    }
    Unqual!(C)[] result;
    result = str.dup;
    foreach(i; 0..result.length){
      static if(C.sizeof == 2){
        result[i] = (cast(C)(result[i] >> 8) | cast(C)(result[i] << 8));
      }else static if(C.sizeof == 4){
        result[i] = ((result[i] >> 24) | ((result[i] >> 8) & 0xFF00) | ((result[i] << 8) & 0xFF0000) | (result[i] << 24));
      }
    }
    return cast(C[])result;
  }
}
+/

C toEN(C)(C c) if(isSomeChar!(C) || isSomeString!(C)){
  static if(!is(Unqual!(C) == char)){
    return multiConvert(c, ConvertType.EN);
  }else{
    return c;
  }
}

C toEM(C)(C c) if(isSomeChar!(C) || isSomeString!(C)){
  static if(!is(Unqual!(C) == char)){
    return multiConvert(c, ConvertType.EM);
  }else{
    return c;
  }
}

C multiConvert(C)(C c, ConvertType type) if(isSomeChar!(C)){
  if((type & ConvertType.UPPER) &&
     ((c >= 'a' && c <= 'z') ||
      (c >= 'ａ' && c <= 'ｚ'))){
    c += ('A' - 'a');
  }else if((type & ConvertType.LOWER) &&
           ((c >= 'A' && c <= 'z') ||
            (c >= 'Ａ' && c <= 'Ｚ'))){
    c += ('a' - 'A');
  }
  static if(!is(Unqual!(C) == char)){
    if((type & ConvertType.EN) &&
       (c >= '！' && c <= '～')){
      c += ('!' - '！');
    }else if((type & ConvertType.EM) &&
             (c >= '!' && c <= '~')){
      c += ('！' - '!');
    }
    if((type & ConvertType.EN) && c == '　'){
      c = ' ';
    }else if((type & ConvertType.EM) && c == ' '){
      c = '　';
    }
  }
  return c;
}

C[] multiConvert(C)(C[] str, ConvertType type) if(isSomeChar!(C)){
  C[] result;
  result = str;
  foreach(i; 0..(str.length)){
    if((type & ConvertType.UPPER) &&
       ((str[i] >= 'a' && str[i] <= 'z') ||
        (str[i] >= 'ａ' && str[i] <= 'ｚ'))){
      str[i] += ('A' - 'a');
    }else if((type & ConvertType.LOWER) &&
             ((str[i] >= 'A' && str[i] <= 'z') ||
              (str[i] >= 'Ａ' && str[i] <= 'Ｚ'))){
      str[i] += ('a' - 'A');
    }
    static if(!is(Unqual!(C) == char)){
      if((type & ConvertType.EN) &&
         (str[i] >= '！' && str[i] <= '～')){
        str[i] += ('!' - '！');
      }else if((type & ConvertType.EM) &&
               (str[i] >= '!' && str[i] <= '~')){
        str[i] += ('！' - '!');
      }
      if((type & ConvertType.EN) && str[i] == '　'){
        str[i] = ' ';
      }else if((type & ConvertType.EM) && str[i] == ' '){
        str[i] = '　';
      }
    }
  }
  return str;
}

C modeConvert(C)(C c, ConvertType type)  if(isSomeChar!(C)){
  version(WIDE){
    return str.multiConvert(type);
  }else{
    if(type & ConvertType.UPPER){
      return str.toUpper();
    }else if(type & ConvertType.LOWER){
      return str.toLower();
    }else{
      return str;
    }
  }
}

C[] modeConvert(C)(C[] str, ConvertType type) if(isSomeChar!(C)){
  version(WIDE){
    return str.multiConvert(type);
  }else{
    if(type & ConvertType.UPPER){
      return str.toUpper();
    }else if(type & ConvertType.LOWER){
      return str.toLower();
    }else{
      return str;
    }
  }
}

ptrdiff_t multiIndex(C, D)(C[] str, D target, CaseSensitive lowupp, CaseSensitive enem) if(isSomeChar!(C) && isSomeChar!(D)){
  C temp;
  foreach(i; 0..(str.length)){
    temp = target;
    if(lowupp == CaseSensitive.no){
      if((str[i] >= 'a' && str[i] <= 'z') ||
         (str[i] >= 'ａ' && str[i] <= 'ｚ')){
        temp += ('A' - 'a');
      }else if((str[i] >= 'A' && str[i] <= 'z') ||
               (str[i] >= 'Ａ' && str[i] <= 'Ｚ')){
        temp += ('a' - 'A');
      }
      static if(!is(Unqual!(C) == char)){
        if(enem == CaseSensitive.no){
          if(str[i] >= '！' && str[i] <= '～'){
            temp += ('!' - '！');
          }else if(str[i] >= '!' && str[i] <= '~'){
            temp += ('！' - '!');
          }
          if(str[i] == '　'){
            temp = ' ';
          }else if(str[i] == ' '){
            temp = '　';
          }
        }
      }
    }
    if(str[i] == temp){
      return i;
    }
  }
  return -1;
}

ptrdiff_t multiIndex(C, D)(C[] str, D[] target, CaseSensitive lowupp, CaseSensitive enem) if(isSomeChar!(C) && isSomeChar!(D)){
  C[] balance;
  if(lowupp == CaseSensitive.yes){
    if(enem == CaseSensitive.yes){
      balance = std.algorithm.find(str, target);
    }else{
      balance = std.algorithm.find!
                ((a, b) => (a.multiConvert(ConvertType.EN) == b.multiConvert(ConvertType.EN)))(str, target);
    }
  }else{
    if(enem == CaseSensitive.yes){
      balance = std.algorithm.find!
                ((a, b) => (a.multiConvert(ConvertType.UPPER) == b.multiConvert(ConvertType.UPPER)))(str, target);
    }else{
      balance = std.algorithm.find!
                ((a, b) => (a.multiConvert(ConvertType.UPPER | ConvertType.EN) == b.multiConvert(ConvertType.UPPER | ConvertType.EN)))(str, target);
    }
  }
  return (balance.empty ? -1 : (balance.ptr - str.ptr));
}

ptrdiff_t modeIndex(C, D)(C[] str, D t, CaseSensitive c = CaseSensitive.yes)  if(isSomeChar!(C) && isSomeChar!(D)){
  version(WIDE){
    return str.multiIndex(t, c, c);
  }else{
    return str.indexOf(t, c);
  }
}

ptrdiff_t modeIndex(C, D)(in C[] str, in D[] t, CaseSensitive c = CaseSensitive.yes)  if(isSomeChar!(C) && isSomeChar!(D)){
  version(WIDE){
    return str.multiIndex(t, c, c);
  }else{
    return str.indexOf(t, c);
  }
}

Charset getEncode(C)(C fname){
  File f;
  Charset result;
  //
  string line;
  ubyte DBCS_base;
  ubyte utf_base;
  uint mode;
  uint DBCS_sjis;
  uint DBCS_euc;
  //
  f = File(fname, ACCESSIBLE.READ);
  result = Charset.UTF8;
  mode = 0;
  while(true){
    line = f.readln();
    if(f.eof){break;}
    // BOMによる判定(Shiftjis/UHC/UTF-8)
    if(line[0] == 0xEF && line[1] == 0xBB && line[2] == 0xBF){
      f.close();
      return Charset.UTF8;
    }
    if(line[0] == 0xFF && line[1] == 0xFE){
      f.close();
      return Charset.UTF16LE;
    }
    if(line[0] == 0xFE && line[1] == 0xFF){
      f.close();
      return Charset.UTF16BE;
    }
    if(line[0] == 0xFF && line[1] == 0xFE && line[2] == 0x00 && line[3] == 0x00){
      f.close();
      return Charset.UTF32LE;
    }
    if(line[0] == 0x00 && line[1] == 0x00 && line[2] == 0xFE && line[3] == 0xFF){
      f.close();
      return Charset.UTF32BE;
    }
    foreach(i; 0..line.length){
      switch(mode % 0x08){
      case 0:
        if(result == Charset.UTF8){
          if(line[i] >= 0x80){
            if(line[i] < 0xC0){
              result = Charset.ASCII;
            }else{
              mode += 1;
              utf_base = line[i];
            }
          }
        }
        break;
      case 1:
        if(line[i] < 0x80 || line[i] >= 0xC0){
          result = Charset.ASCII;
          mode &= 0x08;
        }
        if(utf_base >= 0xE0){
          mode += 1;
        }else{
          mode &= 0x08;
        }
        break;
      case 2:
        if(line[i] < 0x80 || line[i] >= 0xC0){
          result = Charset.ASCII;
          mode &= 0x08;
        }
        if(utf_base >= 0xF0){
          mode += 1;
        }else{
          mode &= 0x08;
        }
        break;
      case 3:
        if(line[i] < 0x80 || line[i] >= 0xC0){
          result = Charset.ASCII;
          mode &= 0x08;
        }
        if(utf_base >= 0xF8){
          mode += 1;
        }else{
          mode &= 0x08;
        }
        break;
      case 4:
        if(line[i] < 0x80 || line[i] >= 0xC0){
          result = Charset.ASCII;
          mode &= 0x08;
        }
        if(utf_base >= 0xFC){
          mode += 1;
        }else{
          mode &= 0x08;
        }
        break;
      case 5:
        if(line[i] < 0x80 || line[i] >= 0xC0){
          result = Charset.ASCII;
        }
        mode &= 0x08;
        break;
      default:
        break;
      }
      if(mode >= 8){
        if(((DBCS_base >= 0x80 && DBCS_base <= 0x9F) || (DBCS_base >= 0xE0 && DBCS_base <= 0xFC)) &&
           ((line[i] >= 0x40 && line[i] <= 0x7E) || (line[i] >= 0x80 && line[i] <= 0xFC))){
          DBCS_sjis += 1;
        }
        if(DBCS_base >= 0xA0 && line[i] >= 0xA0){
          DBCS_euc += 1;
        }
        mode -= 8;
      }else{
        if(line[i] >= 0x80){
          mode += 8;
          DBCS_base = line[i];
        }
      }
    }
  }
  f.close();
  //
  if(result == Charset.ASCII){
    if(DBCS_sjis > 0 || DBCS_euc > 0){
      if(DBCS_sjis > DBCS_euc){
        result = Charset.SHIFTJIS;
      }else{
        result = Charset.UHC;
      }
    }
  }
  return result;
}

dstring convert(Charset outcode, C)(C[] src, Charset incode) if(isSomeChar!(C) && (outcode == Charset.UTF32LE || outcode == Charset.UTF32BE))
in{
  assert(in_enum(incode));
  assert(get_size(incode) == C.sizeof);
}
do{
  uint str_size;
  version(Windows){
    wchar[] dst;
  }
  version(Posix){
    dchar[] dst;
    iconv_t conv;
  }
  static if(is(Unqual!(C) == char)){
    if(incode == Charset.DEFAULT){
      version(Windows){
        dst.length = src.length;
        str_size = MultiByteToWideChar(0, 0, src.ptr, src.length * C.sizeof, dst.ptr, dst.length);
        dst.length = str_size;
        return cast(dchar[])swap(toUTF32(dst), incode);
      }
      version(Posix){
        return cast(dchar[])toUTF32(src);
      }
    }else if(incode == Charset.SHIFTJIS){
      dst.length = src.length;
      version(Windows){
        str_size = MultiByteToWideChar(932, 0, src.ptr, src.length * C.sizeof, dst.ptr, dst.length);
        dst.length = str_size;
        return cast(dchar[])swap(toUTF32(dst), incode);
      }
      version(Posix){
        static if(outcode == Charset.UTF32LE){
          conv = iconv_open("UTF32LE", "SHIFT-JIS");
        }else static if(outcode == Charset.UTF32BE){
          conv = iconv_open("UTF32BE", "SHIFT-JIS");
        }
        size_t temp1 = src.length * C.sizeof;
        size_t temp2 = dst.length;
        const char* temp3 = src.ptr;
        char* temp4 = dst.ptr;
        str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
        iconv_close(conv);
        dst.length = temp2;
        return dst;
      }
    }else if(incode == Charset.UHC){
      dst.length = src.length;
      version(Windows){
        str_size = MultiByteToWideChar(949, 0, src.ptr, src.length * C.sizeof, dst.ptr, dst.length);
        dst.length = str_size;
        return cast(dchar[])dst;
      }
      version(Posix){
        static if(outcode == Charset.UTF32LE){
          conv = iconv_open("UTF32LE", "UHC");
        }else static if(outcode == Charset.UTF32BE){
          conv = iconv_open("UTF32BE", "UHC");
        }
        size_t temp1 = src.length * C.sizeof;
        size_t temp2 = dst.length;
        const char* temp3 = src.ptr;
        char* temp4 = dst.ptr;
        str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
        iconv_close(conv);
        dst.length = temp2;
        return dst;
      }
    }else{
      return cast(dstring)toUTF32(src);
    }
  }else static if(is(Unqual!(C) == wchar)){
    return cast(dstring)swap(toUTF32(src), incode);
  }
  return cast(dstring)swap(src, incode);
}

//
wstring convert(Charset outcode, C)(C[] src, Charset incode) if(isSomeChar!(C) && (outcode == Charset.UTF16LE || outcode == Charset.UTF16BE))
in{
  assert(in_enum(incode));
  assert(get_size(incode) == C.sizeof);
}
do{
  wchar[] dst;
  version(Posix){
    iconv_t conv;
  }
  uint str_size;
  static if(is(Unqual!(C) == char)){
    if(incode == Charset.DEFAULT){
      version(Windows){
        dst.length = src.length;
        str_size = MultiByteToWideChar(0, 0, src.ptr, src.length * C.sizeof, dst.ptr, dst.length);
        dst.length = str_size;
        return cast(wstring)swap(toUTF16(dst), incode);
      }
      version(Posix){
        return cast(wstring)toUTF16(src);
      }
    }else if(incode == Charset.SHIFTJIS){
      dst.length = src.length;
      version(Windows){
        str_size = MultiByteToWideChar(932, 0, src.ptr, src.length * C.sizeof, dst.ptr, dst.length);
        dst.length = str_size;
        return cast(wstring)dst;
      }
      version(Posix){
        static if(outcode == Charset.UTF16LE){
          conv = iconv_open("UTF16LE", "UHC");
        }else static if(outcode == Charset.UTF16BE){
          conv = iconv_open("UTF16BE", "UHC");
        }
        size_t temp1 = src.length * C.sizeof;
        size_t temp2 = dst.length;
        const char* temp3 = src.ptr;
        char* temp4 = dst.ptr;
        str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
        iconv_close(conv);
        if(str_size >= 0 && temp4 !is null){
          *temp4 = '\0';
          dst.length = strlen(dst.ptr);
        }else{
          dst.length = 0;
        }
        return cast(wstring)dst;
      }
    }else if(incode == Charset.UHC){
      dst.length = src.length;
      version(Windows){
        str_size = MultiByteToWideChar(949, 0, src.ptr, src.length * C.sizeof, dst.ptr, dst.length);
        dst.length = str_size;
        return cast(wstring)dst;
      }
      version(Posix){
        static if(outcode == Charset.UTF16LE){
          conv = iconv_open("UTF16LE", "UHC");
        }else static if(outcode == Charset.UTF16BE){
          conv = iconv_open("UTF16BE", "UHC");
        }
        size_t temp1 = src.length * C.sizeof;
        size_t temp2 = dst.length;
        const char* temp3 = src.ptr;
        char* temp4 = dst.ptr;
        str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
        iconv_close(conv);
        if(str_size >= 0 && temp4 !is null){
          *temp4 = '\0';
          dst.length = strlen(dst.ptr);
        }else{
          dst.length = 0;
        }
        return dst;
      }
    }else{
      return cast(wstring)toUTF16(src);
    }
  }else static if(is(Unqual!(C) == dchar)){
    return cast(wstring)swap(toUTF16(src), incode);
  }
  return cast(wstring)swap(src, incode);
}

//
string convert(Charset outcode, C)(C[] src, Charset incode) if(isSomeChar!(C) && (outcode == Charset.UTF8))
in{
  assert(in_enum(incode));
  assert(get_size(incode) == C.sizeof);
}
do{
  version(Windows){
    wchar[] dst;
  }
  version(Posix){
    char[] dst;
    iconv_t conv;
  }
  size_t str_size;
  static if(is(Unqual!(C) == char)){
    if(incode == Charset.DEFAULT){
      version(Windows){
        dst.length = src.length * 2;
        str_size = MultiByteToWideChar(0, 0, src.ptr, cast(int)(src.length * C.sizeof), dst.ptr, cast(int)dst.length);
        dst.length = str_size;
        return cast(string)toUTF8(dst);
      }
      version(Posix){
        return cast(string)src;
      }
    }else if(incode == Charset.SHIFTJIS){
      dst.length = src.length * 2;
      version(Windows){
        str_size = MultiByteToWideChar(932, 0, src.ptr, cast(int)(src.length * C.sizeof), dst.ptr, cast(int)dst.length);
        dst.length = str_size;
        return cast(string)toUTF8(dst);
      }
      version(Posix){
        conv = iconv_open("UTF-8", "SHIFT-JIS");
        size_t temp1 = src.length * C.sizeof;
        size_t temp2 = dst.length;
        const char* temp3 = src.ptr;
        char* temp4 = dst.ptr;
        str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
        iconv_close(conv);
        if(str_size >= 0 && temp4 !is null){
          *temp4 = '\0';
          dst.length = strlen(dst.ptr);
        }else{
          dst.length = 0;
        }
        return cast(string)dst;
      }
    }else if(incode == Charset.UHC){
      dst.length = src.length * 2;
      version(Windows){
        str_size = MultiByteToWideChar(949, 0, src.ptr, cast(int)(src.length * C.sizeof), dst.ptr, cast(int)dst.length);
        dst.length = str_size;
        return cast(string)toUTF8(dst);
      }
      version(Posix){
        conv = iconv_open("UTF8", "UHC");
        size_t temp1 = src.length * C.sizeof;
        size_t temp2 = dst.length;
        const char* temp3 = src.ptr;
        char* temp4 = dst.ptr;
        str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
        iconv_close(conv);
        if(str_size >= 0 && temp4 !is null){
          *temp4 = '\0';
          dst.length = strlen(dst.ptr);
        }else{
          dst.length = 0;
        }
        return cast(string)dst;
      }
    }
  }else{
    return cast(string)toUTF8(swap(src, incode));
  }
  return cast(string)src;
}

//
string convert(Charset outcode, C)(C[] src, Charset incode) if(isSomeChar!(C) && outcode == Charset.SHIFTJIS)
in{
  assert(in_enum(incode));
  assert(get_size(incode) == C.sizeof);
}
do{
  version(Windows){
    wchar[] dst;
  }
  version(Posix){
    char[] dst;
    iconv_t conv;
  }
  char[] result;
  uint str_size;
  //
  static if(is(Unqual!(C) == char)){
    if(incode == Charset.DEFAULT){
      dst.length = src.length;
      version(Windows){
        if(GetConsoleCP() == 932){
          return cast(string)src;
        }else{
          result.length = src.length * 2;
          str_size = MultiByteToWideChar(0, 0, src.ptr, src.length * C.sizeof, dst.ptr, dst.length);
          dst.length = str_size;
          str_size = WideCharToMultiByte(932, 0, dst.ptr, str_size, result.ptr, result.length, null, null);
          result.length = str_size;
          return cast(string)result;
        }
      }
      version(Posix){
        conv = iconv_open("SHIFT-JIS", "UTF8");
        size_t temp1 = src.length * C.sizeof;
        size_t temp2 = dst.length;
        const char* temp3 = src.ptr;
        char* temp4 = dst.ptr;
        str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
        iconv_close(conv);
        if(str_size >= 0 && temp4 !is null){
          *temp4 = '\0';
          dst.length = strlen(dst.ptr);
        }else{
          dst.length = 0;
        }
        return cast(string)dst;
      }
    }else if(incode == Charset.UHC){
      dst.length = src.length;
      version(Windows){
        result.length = src.length * 2;
        str_size = MultiByteToWideChar(949, 0, src.ptr, src.length * C.sizeof, dst.ptr, dst.length);
        dst.length = str_size;
        str_size = WideCharToMultiByte(932, 0, dst.ptr, str_size, result.ptr, result.length, null, null);
        result.length = str_size;
        return cast(string)result;
      }
      version(Posix){
        conv = iconv_open("SHIFT-JIS", "UHC");
        size_t temp1 = src.length * C.sizeof;
        size_t temp2 = dst.length;
        const char* temp3 = src.ptr;
        char* temp4 = dst.ptr;
        str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
        iconv_close(conv);
        if(str_size >= 0 && temp4 !is null){
          *temp4 = '\0';
          dst.length = strlen(dst.ptr);
        }else{
          dst.length = 0;
        }
        return cast(string)dst;
      }
    }else if(incode == Charset.UTF8){
      version(Windows){
        dst = cast(wstring)toUTF16(src);
        result.length = src.length * 2;
        str_size = WideCharToMultiByte(932, 0, dst.ptr, dst.length, result.ptr, result.length, null, null);
        result.length = str_size;
        return cast(string)result;
      }
      version(Posix){
        conv = iconv_open("SHIFT-JIS", "UTF8");
        size_t temp1 = src.length * C.sizeof;
        size_t temp2 = dst.length;
        const char* temp3 = src.ptr;
        char* temp4 = dst.ptr;
        str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
        iconv_close(conv);
        if(str_size >= 0 && temp4 !is null){
          *temp4 = '\0';
          dst.length = strlen(dst.ptr);
        }else{
          dst.length = 0;
        }
        return cast(string)dst;
      }
    }
  }else static if(is(Unqual!(C) == wchar)){
    version(Windows){
      result.length = src.length * 2;
      str_size = WideCharToMultiByte(932, 0, src.ptr, src.length, result.ptr, result.length, null, null);
      result.length = str_size;
    }
    version(Posix){
      static if(outcode == Charset.UTF32LE){
        conv = iconv_open("SHIFT-JIS", "UTF32LE");
      }else static if(outcode == Charset.UTF32BE){
        conv = iconv_open("SHIFT-JIS", "UTF32BE");
      }
      size_t temp1 = src.length * C.sizeof;
      size_t temp2 = dst.length;
      const char* temp3 = src.ptr;
      char* temp4 = result.ptr;
      str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
      iconv_close(conv);
      if(str_size >= 0 && temp4 !is null){
        *temp4 = '\0';
        result.length = strlen(dst.ptr);
      }else{
        result.length = 0;
      }
    }
    return result;
  }else static if(is(Unqual!(C) == dchar)){
    version(Windows){
      dst = cast(wstring)toUTF16(src);
      result.length = src.length * 2;
      str_size = WideCharToMultiByte(932, 0, dst.ptr, dst.length, result.ptr, result.length, null, null);
      result.length = str_size;
    }
    version(Posix){
      static if(outcode == Charset.UTF32LE){
        conv = iconv_open("SHIFT-JIS", "UTF32LE");
      }else static if(outcode == Charset.UTF32BE){
        conv = iconv_open("SHIFT-JIS", "UTF32BE");
      }
      size_t temp1 = src.length * C.sizeof;
      size_t temp2 = dst.length;
      const char* temp3 = src.ptr;
      char* temp4 = result.ptr;
      str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
      iconv_close(conv);
      if(str_size >= 0 && temp4 !is null){
        *temp4 = '\0';
        result.length = strlen(dst.ptr);
      }else{
        result.length = 0;
      }
    }
    return result;
  }
  return cast(string)src;
}

//
string convert(Charset outcode, C)(C[] src, Charset incode) if(isSomeChar!(C) && outcode == Charset.UHC)
in{
  assert(in_enum(incode));
  assert(get_size(incode) == C.sizeof);
}
do{
  version(Windows){
    wchar[] dst;
  }
  version(Posix){
    char[] dst;
    iconv_t conv;
  }
  char[] result;
  uint str_size;
  static if(is(Unqual!(C) == char)){
    if(incode == Charset.DEFAULT){
      dst.length = src.length;
      version(Windows){
        if(GetConsoleCP() == 949){
          return cast(string)src;
        }else{
          result.length = src.length * 2;
          str_size = MultiByteToWideChar(0, 0, src.ptr, src.length * C.sizeof, dst.ptr, dst.length);
          dst.length = str_size;
          str_size = WideCharToMultiByte(949, 0, dst.ptr, str_size, result.ptr, result.length, null, null);
          result.length = str_size;
          return result;
        }
      }
      version(Posix){
        conv = iconv_open("SHIFT-JIS", "UTF8");
        size_t temp1 = src.length * C.sizeof;
        size_t temp2 = dst.length;
        const char* temp3 = src.ptr;
        char* temp4 = dst.ptr;
        str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
        iconv_close(conv);
        if(str_size >= 0 && temp4 !is null){
          *temp4 = '\0';
          dst.length = strlen(dst.ptr);
        }else{
          result.length = 0;
        }
      }
    }
    return result;
  }else static if(is(Unqual!(C) == dchar)){
    version(Windows){
      dst = cast(wstring)toUTF16(src);
      result.length = src.length * 2;
      str_size = WideCharToMultiByte(949, 0, dst.ptr, dst.length, result.ptr, result.length, null, null);
      result.length = str_size;
    }
    version(Posix){
      static if(outcode == Charset.UTF32LE){
        conv = iconv_open("SHIFT-JIS", "UTF32LE");
      }else static if(outcode == Charset.UTF32BE){
        conv = iconv_open("SHIFT-JIS", "UTF32BE");
      }
      size_t temp1 = src.length * C.sizeof;
      size_t temp2 = dst.length;
      const char* temp3 = src.ptr;
      char* temp4 = result.ptr;
      str_size = iconv_convert(conv, &temp3, &temp1, &temp4, &temp2);
      iconv_close(conv);
      if(str_size >= 0 && temp4 !is null){
        *temp4 = '\0';
        result.length = strlen(dst.ptr);
      }else{
        result.length = 0;
      }
    }
    return cast(string)result;
  }
  return cast(string)src;
}

//
string convert(Charset outcode, C)(C[] src, Charset incode) if(isSomeChar!(C) && outcode == Charset.DEFAULT)
in{
  assert(in_enum(incode));
  assert(get_size(incode) == C.sizeof);
}
do{
  version(Windows){
    wchar[] dst;
    char[] result;
    uint str_size;
    static if(is(Unqual!(C) == char)){
      if(incode == Charset.SHIFTJIS){
        dst.length = src.length;
        result.length = src.length * 2;
        str_size = MultiByteToWideChar(932, 0, src.ptr, cast(int)(src.length * C.sizeof), dst.ptr, cast(int)dst.length);
        dst.length = str_size;
        str_size = WideCharToMultiByte(0, 0, dst.ptr, str_size, result.ptr, cast(int)(result.length), null, null);
        result.length = str_size;
        return cast(string)result;
      }else if(incode == Charset.UHC){
        dst.length = src.length;
        result.length = src.length * 2;
        str_size = MultiByteToWideChar(949, 0, src.ptr, cast(int)(src.length * C.sizeof), dst.ptr, cast(int)(dst.length));
        dst.length = str_size;
        str_size = WideCharToMultiByte(0, 0, dst.ptr, str_size, result.ptr, cast(int)(result.length), null, null);
        result.length = str_size;
        return cast(string)result;
      }else if(incode == Charset.UTF8){
        dst = cast(wchar[])toUTF16(src);
        result.length = src.length * 2;
        str_size = WideCharToMultiByte(0, 0, dst.ptr, cast(int)(dst.length), result.ptr, cast(int)(result.length), null, null);
        result.length = str_size;
        return cast(string)result;
      }
    }else static if(is(Unqual!(C) == wchar)){
      result.length = src.length * 2;
      str_size = WideCharToMultiByte(0, 0, src.ptr, src.length, result.ptr, result.length, null, null);
      result.length = str_size;
      return result;
    }else static if(is(Unqual!(C) == dchar)){
      dst = cast(wstring)toUTF16(src);
      result.length = src.length * 2;
      str_size = WideCharToMultiByte(0, 0, dst.ptr, dst.length, result.ptr, result.length, null, null);
      result.length = str_size;
      return result;
    }
    return cast(string)src;
  }
  version(Posix){
    return convert!(Charset.UTF8)(src, incode);
  }
}

//
uint get_size(Charset c)
in{
  assert(in_enum(c));
}
do{
  switch(c){
  case Charset.ASCII:
  case Charset.SHIFTJIS:
  case Charset.UHC:
  case Charset.UTF8:
  case Charset.DEFAULT:
    return char.sizeof;
  case Charset.UTF16LE:
  case Charset.UTF16BE:
    return wchar.sizeof;
  case Charset.UTF32LE:
  case Charset.UTF32BE:
    return dchar.sizeof;
  default:
    break;
  }
  return 0;
}

C[] replace_vaild(C)(C[] str, Charset incode) if(isSomeChar!(C))
in{
  assert(in_enum(incode));
  assert(get_size(incode) == C.sizeof);
}
do{
  static if(C.sizeof == 4){
    C[] result;
    version(BigEndian){
      foreach(i; 0..(str.length)){
        if(incode == Charset.UTF32BE){
          if((str[i] >= 0x0000D800 && str[i] <= 0x0000DFFF) || str[i] >= 0x110000){
            if(result.length == 0){
              result = str.dup;
            }
            result[i] = 0x0000FFFD;
          }
        }else{
          if((swap(str[i]) >= 0x0000D800 && swap(str[i]) <= 0x0000DFFF) || swap(str[i]) >= 0x110000){
            if(result.length == 0){
              result = str.dup;
            }
            result[i] = 0xFDFF0000;
          }
        }
      }
    }
    version(LittleEndian){
      foreach(i; 0..(str.length)){
        if(incode == Charset.UTF32LE){
          if((str[i] >= 0x0000D800 && str[i] <= 0x0000DFFF) || str[i] >= 0x110000){
            if(result.length == 0){
              result = str.dup;
            }
            result[i] = 0x0000FFFD;
          }
        }else{
          if((swap(str[i]) >= 0x0000D800 && swap(str[i]) <= 0x0000DFFF) || swap(str[i]) >= 0x110000){
            if(result.length == 0){
              result = str.dup;
            }
            result[i] = 0xFDFF0000;
          }
        }
      }
    }
    if(result.length == 0){
      return str;
    }else{
      return result;
    }
  }else static if(C.sizeof == 2){
    C[] result;
    version(BigEndian){
      foreach(i; 0..(str.length)){
        if(incode == Charset.UTF16BE){
          if(str[i] >= 0xD800 && str[i] <= 0xDFFF){
            if(result.length == 0){
              result = str.dup;
            }
            result[i] = 0xFFFD;
          }
        }else{
          if(swap(str[i]) >= 0xD800 && swap(str[i]) <= 0xDFFF){
            if(result.length == 0){
              result = str.dup;
            }
            result[i] = 0xFDFF;
          }
        }
      }
    }
    version(LittleEndian){
      foreach(i; 0..(str.length)){
        if(incode == Charset.UTF16LE){
          if(str[i] >= 0xD800 && str[i] <= 0xDFFF){
            if(result.length == 0){
              result = str.dup;
            }
            result[i] = 0xFFFD;
          }
        }else{
          if(swap(str[i]) >= 0xD800 && swap(str[i]) <= 0xDFFF){
            if(result.length == 0){
              result = str.dup;
            }
            result[i] = 0xFDFF;
          }
        }
      }
    }
    if(result.length == 0){
      return str;
    }else{
      return result;
    }
  }else{
    if(incode == Charset.UTF8){
      C[] result;
      size_t point;
      char utf_base;
      dchar tumi;
      uint mode;
      foreach(i; 0..(str.length)){
        if(mode == 0){
          if(str[i] >= 0x80){
            if(str[i] < 0xC0){
              if(result.length == 0){
                if(i + 4 >= str.length){
                  result.length = str.length + 4;
                }else{
                  result.length = str.length;
                }
                result[0..i-mode] = str[0..i-mode];
                point = i - mode;
              }
              if(point < result.length && point + 4 >= result.length){
                result.length += 4;
              }
              result[point] = '\xEF';
              result[point+1] = '\xBF';
              result[point+2] = '\xBD';
              point += 3;
            }else{
              mode += 1;
              utf_base = cast(C)(str[i] << 2);
              tumi = str[i] & 0x3F;
            }
          }else{
            if(result.length > 0){
              if(point < result.length && point + 4 >= result.length){
                result.length += 4;
              }
              foreach(j; 0..mode){
                result[point-j] = str[i-j];
              }
              point += mode + 1;
            }
          }
        }else if(mode == 1){
          if(str[i] < 0x80 || str[i] >= 0xC0){
            if(result.length == 0){
              if(i + 4 >= str.length){
                result.length = str.length + 4;
              }else{
                result.length = str.length;
              }
              result[0..i-mode] = str[0..i-mode];
              point = i - mode;
            }
            result[point] = '\xEF';
            result[point+1] = '\xBF';
            result[point+2] = '\xBD';
            point += 3;
            mode = 0;
          }else{
            tumi = (tumi << 6) + (str[i] & 0x3F);
            if(utf_base & 0x80){
              utf_base <<= 1;
              mode += 1;
            }else{
              if(tumi < (1 << 7)){
                if(result.length == 0){
                  if(i + 4 >= str.length){
                    result.length = str.length + 4;
                  }else{
                    result.length = str.length;
                  }
                  result[0..i-mode] = str[0..i-mode];
                  point = i - mode;
                }
                if(point < result.length && point + 4 >= result.length){
                  result.length += 4;
                }
                result[point] = '\xEF';
                result[point+1] = '\xBF';
                result[point+2] = '\xBD';
                point += 3;
              }else{
                if(result.length > 0){
                  if(point < result.length && point + 4 >= result.length){
                    result.length += 4;
                  }
                  foreach(j; 0..mode){
                    result[point-j] = str[i-j];
                  }
                  point += mode + 1;
                }
              }
              mode = 0;
            }
          }
        }else{
          if(str[i] < 0x80 || str[i] >= 0xC0){
            if(result.length == 0){
              if(i + 4 >= str.length){
                result.length = str.length + 4;
              }else{
                result.length = str.length;
              }
              result[0..i+1] = str[0..i+1];
              point = i + 1;
            }else{
              result[point] = '\xEF';
              result[point+1] = '\xBF';
              result[point+2] = '\xBD';
              point += 3;
            }
            mode = 0;
          }else{
            tumi = ((tumi & ((1 << (1 + mode * 5)) - 1)) << 6) + (str[i] & 0x3F);
            if(utf_base & 0x80){
              utf_base <<= 1;
              mode += 1;
            }else{
              if(tumi < (1 << (1 + mode * 5)) || !isValidDchar(tumi)){
                if(result.length == 0){
                  if(i + 4 >= str.length){
                    result.length = str.length + 4;
                  }else{
                    result.length = str.length;
                  }
                  result[0..i-mode] = str[0..i-mode];
                  point = i - mode;
                }
                result[point] = '\xEF';
                result[point+1] = '\xBF';
                result[point+2] = '\xBD';
                point += 3;
              }else{
                if(result.length > 0){
                  if(point < result.length && point + 4 >= result.length){
                    result.length += 4;
                  }
                  foreach(j; 0..mode){
                    result[point+j] = str[i-mode+j];
                  }
                  point += mode + 1;
                }
              }
              mode = 0;
            }
          }
        }
      }
      if(result.length == 0){
        return str;
      }else{
        result.length = point;
        return result;
      }
    }else{
      return str;
    }
  }
}
