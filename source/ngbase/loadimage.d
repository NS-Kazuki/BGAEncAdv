/**
 * 画像フォーマットから復号したビットマップ画像を扱うクラス。
 *
 * This file is part of Nageyari Gamebase.
 * 
 * License:   Public Domain
 * Date:      August 21, 2010
 * Author:    Kazuki Okawa, naka4959@kcn.ne.jp
*/
module ngbase.loadimage;

import std.algorithm;
import std.array;
import std.file;
import std.math;
import std.path;
import std.string;
import std.traits;
import std.exception;

import core.stdc.string;

import core.memory;

alias malloc = GC.malloc;
alias free = GC.free;

import libjpeg.jpeglib;
import libjpeg.jconfig;
import libpng.png;

import ngbase.bitmap;
import ngbase.streambuffer;

immutable size_t BUFFER_SIZE = 4096; /// ファイルの展開処理内で使われるバッファの大きさ

private{
  enum ACCESSIBLE{
    READ = "r",
    WRITE = "w",
    APPEND = "a",
    BINARY = "b",
    READ_BINARY = READ ~ BINARY,
    WRITE_BINARY = WRITE ~ BINARY,
    APPEND_BINARY = APPEND ~ BINARY,
  }

  /*
   * データソースの展開中の情報を保持する構造体
  */
  struct jpeg_extend_source_mgr{
    jpeg_source_mgr pub; // public fields
    void* data; // source stream
    ubyte* buffer; // start of buffer
    uint size; // data size
    bool start_of_data; // have we gotten any data yet?
  }
  /*
   *
  */
  enum BMP_TYPE{
    OS_2 = 12,
    WINDOWS = 40
  }
  /*
   *
  */
  struct bitmapcore_header{
    short width;
    short height;
    ushort planes;
    ushort bitcount;
  }
  /*
   *
  */
  struct bitmapinfo_header{
    int width;
    int height;
    ushort planes;
    ushort bitcount;
    uint compression;
    uint sizeImage;
    int xppm;
    int yppm;
    uint color_used;
    uint color_important;
    // V4(56)
    uint red_mask;
    uint green_mask;
    uint blue_mask;
    uint alpha_mask;
    uint ctype;
    struct endpoints{
      ciexyz red;
      ciexyz blue;
      ciexyz green;
    };
    uint gamma_red; 
    uint gamma_reen; 
    uint gamma_blue; 
    //
    uint intent; 
    uint profile_data; 
    uint profile_size; 
    uint reserved; 
  }
  /*
   *
  */
  struct ciexyz{
    int x;
    int y;
    int z;
  }
  /*
   *
  */
  struct bitmapV4_header_52{
    bitmapinfo_header info;
    uint red_mask;
    uint green_mask;
    uint blue_mask;
  }
  /*
   *
  */
  union color_mask{
    struct{
      uint red;
      uint green;
      uint blue;
      uint alpha;
    }
    uint[4] data;
  }
  extern (C){
    /*
     * 圧縮されたデータの展開開始フラグを立てる
     *
     * Params:
     *  cinfo = 圧縮されたデータの情報を格納している構造体
    */
    void init_source_memory(jpeg_decompress_struct* cinfo)
    in{
      assert(cinfo !is null);
    }
    do{
      jpeg_extend_source_mgr* src;
      src = cast(jpeg_extend_source_mgr*)cinfo.src;
      src.start_of_data = true;
    }
    /*
     * ストリームから圧縮されているデータを読み込む
     *
     * Params:
     *  cinfo = 圧縮されたデータの情報を格納している構造体
     *
     * Returns:
     *  読み込めたデータの長さ
    */
    int fill_input_buffer(jpeg_decompress_struct* cinfo)
    in{
      assert(cinfo !is null);
    }
    do{
      jpeg_extend_source_mgr* src;
      size_t nbytes;
      src = cast(jpeg_extend_source_mgr*)cinfo.src;
      nbytes = (cast(StreamBuffer)src.data).read(src.buffer, BUFFER_SIZE);
      if(nbytes <= 0){
        if(src.start_of_data == true){
          //cinfo.err.msg_code = J_MESSAGE_CODE.JERR_INPUT_EMPTY;
          cinfo.err.error_exit(cast(jpeg_common_struct*)cinfo);
        }
        //cinfo.err.msg_code = J_MESSAGE_CODE.JWRN_JPEG_EOF;
        cinfo.err.emit_message(cast(jpeg_common_struct*)cinfo, -1);
        src.buffer[0] = 0xFF;
        src.buffer[1] = JPEG_EOI;
        nbytes = 2;
      }
      src.pub.next_input_byte = cast(ubyte*)src.buffer;
      src.pub.bytes_in_buffer = nbytes;
      src.start_of_data = false;
      return true;
    }
    /*
     * ストリームのポインタを指定されたバイト数だけ移動
     *
     * Params:
     *  cinfo = 圧縮されたデータの情報を格納している構造体
     *  num_bytes = 移動させるバイト数
    */
    void skip_input_data(jpeg_decompress_struct* cinfo, int num_bytes)
    in{
      assert(cinfo !is null);
    }
    do{
      jpeg_extend_source_mgr* src;
      src = cast(jpeg_extend_source_mgr*)cinfo.src;
      if(num_bytes > 0){
        while(num_bytes > cast(long)src.pub.bytes_in_buffer){
          num_bytes -= src.pub.bytes_in_buffer;
          fill_input_buffer(cinfo);
        }
        src.pub.next_input_byte += cast(size_t)num_bytes;
        src.pub.bytes_in_buffer -= cast(size_t)num_bytes;
      }
    }
    /*
     * 
     *
     * Params:
     *  cinfo = 圧縮されたデータの情報を格納している構造体
    */
    void term_source(jpeg_decompress_struct* cinfo){
      // none
    }
    /*
     * jpeg画像展開処理内で，エラーが起こった場合に呼び出される関数
     *
     * Params:
     *  cinfo = 圧縮されたデータの情報を格納している構造体
    */
    void error_jpeg(jpeg_common_struct* cinfo){
      // none
    }
    /*
     * pngファイルから画像データを読み出すコールバック関数
     *
     * Params:
     *  info = pngフォーマットの情報
     *  buffer = データを書き込むバッファ
     *  size = 書き込むデータのサイズ
    */
    void load_png_callback(png_struct* info, ubyte* buffer, size_t size)
    in{
      assert(info !is null);
      assert(buffer !is null);
      assert(size > 0);
    }
    do{
      (cast(StreamBuffer)png_get_io_ptr(info)).read(buffer, size);
    }
  }
}

/**
 * 複数の画像フォーマットを扱うクラス
*/
class ImageBitmap{
  mixin Bitmap;
  private{
    void delegate(string, color)[string] load_file_image; // ファイルからの読み込み関数の関連付け
  }
  public{
    /**
     * ファイルから画像データを読み込む
     *
     * Params:
     *  fname = 読み込むファイルの名称
     *  alpha = 透過する色とその透過率
     *
     * Throws:
     *  ファイルが見つからない場合，IllegalFormatException<br>
     *  ファイルフォーマットがサポートしている画像フォーマットのものでない場合，IllegalFormatException
    */
    this(string fname, color alpha = color(0xFF, 0xFF, 0xFF, 0xFF)){
      string extention;
      //
      load_file_image[".jpg"] = &load_jpg_file;
      load_file_image[".jpeg"] = &load_jpg_file;
      load_file_image[".png"] = &load_png_file;
      load_file_image[".bmp"] = &load_bmp_file;
      //
      enforce(exists(fname) == true, new IllegalFormatException("File not exist"));
      extention = extension(fname).toLower;
      enforce(extention in load_file_image,
              new IllegalFormatException("No supported format"));
      load_file_image[extention](fname, alpha);
    }
    /**
     * バッファから画像データを読み込む
     *
     * Params:
     *  start = データが格納されたバッファの先頭位置
     *
     * Throws:
     *  ファイルフォーマットがサポートしている画像フォーマットのものでない場合，IllegalFormatException
    */
    this(ubyte[] start, color alpha = color(0xFF, 0xFF, 0xFF, 0xFF)){
      // jpegファイルの復号
      if(start[6..10] == "JFIF"){
        load_jpg_memory(start, alpha);
      // pngファイルの復号
      }else if(start[0..8] == "\x89PNG\r\n\x1a\n"){
        load_png_memory(start, alpha);
      // bmpファイルの復号
      }else if(start[0] == 'B' && start[1] == 'M'){
        load_bmp_memory(start, alpha);
      }else{
        // 拡張子の時点で弾く
        throw(new IllegalFormatException("No supported format"));
      }
    }
  }
  //
  private{
    /**
     * jpegファイルから、画像データを読み込む
     *
     * Params:
     *  fname = 読み込むファイルの名称
    */
    void load_jpg_file(string fname, color alpha)
    in{
      assert(exists(fname));
    }
    do{
      ubyte[] buf = cast(ubyte[])read(fname);
      load_jpg_memory(buf, alpha);
    }
    /**
     * jpegフォーマットの格納されたバッファから、画像データを読み込む
     *
     * Params:
     *  data = データが格納されたバッファの先頭位置
    */
    void load_jpg_memory(ubyte[] data, color alpha)
    in{
      assert(cast(char[])data[6..10] == "JFIF");
    }
    out{
      assert(standard_map !is null);
    }
    do{
      uint point;
      StreamBuffer stream = new StreamBuffer(data);
      point = 2;
      while(data[point+1] != 0xDA){
        point += (data[point+2] * 256 | data[point+3]) + 2;
      }
      stream.seek(point + 2, SeekPos.SET);
      load_jpg_common(stream, alpha);
    }
    extern(C){
      /**
       * jpegデータを読み込むための共通処理
       *
       * Params:
       *  data = データが格納されたバッファの先頭位置
      */
      void load_jpg_common(StreamBuffer data, color alpha){
        ubyte* buffer;
        jpeg_decompress_struct cinfo;
        jpeg_error_mgr jerr;
        jpeg_extend_source_mgr* src;
        // 初期化
        memset(&cinfo, 0, jpeg_decompress_struct.sizeof);
        cinfo.err = jpeg_std_error(&jerr);
        jpeg_CreateDecompress(&cinfo, JPEG_LIB_VERSION, jpeg_decompress_struct.sizeof);
        // ファイルの存在は先に証明している
        if(cinfo.src == null){
          src = cast(jpeg_extend_source_mgr*)malloc(jpeg_extend_source_mgr.sizeof);
          memset(src, 0, jpeg_extend_source_mgr.sizeof);
          src.buffer = cast(ubyte*)malloc(4096);
          memset(src.buffer, 0, 4096);
          cinfo.src = cast(jpeg_source_mgr*)src;
        }
        src.data = &data;
        src.size = cast(uint)(data.size);
        src.pub.next_input_byte = null;
        src.pub.bytes_in_buffer = 0;
        src.pub.init_source = &init_source_memory;
        src.pub.fill_input_buffer = &fill_input_buffer;
        src.pub.skip_input_data = &skip_input_data;
        src.pub.resync_to_restart = &jpeg_resync_to_restart;
        src.pub.term_source = &term_source;
        enforce(jpeg_read_header(&cinfo, true) == true,
                new IllegalFormatException("jpeg_read_header failed"));
        enforce(jpeg_start_decompress(&cinfo) == true,
                new IllegalFormatException("Start decompress failed")); 
        // 初期化
        bitmap_width = cinfo.output_width;
        bitmap_height = cinfo.output_height;
        create_bitmap();
        buffer = cast(ubyte*)malloc(tex_width * color.sizeof);
        // 読み込んだ列を32ビットカラーに変換
        do{
          jpeg_read_scanlines(&cinfo, &buffer, 1);
          foreach(i; 0..bitmap_width){
            if(buffer[i * 3] == alpha.red && buffer[i * 3 + 1] == alpha.green && buffer[i * 3 + 2] == alpha.blue){
              standard_map[data_position(cinfo.output_scanline - 1, i)].alpha = alpha.alpha;
            }else{
              standard_map[data_position(cinfo.output_scanline - 1, i)].alpha = 0xFF;
            }
            standard_map[data_position(cinfo.output_scanline - 1, i)].red = buffer[i * 3];
            standard_map[data_position(cinfo.output_scanline - 1, i)].green = buffer[i * 3 + 1];
            standard_map[data_position(cinfo.output_scanline - 1, i)].blue = buffer[i * 3 + 2];
          }
        }while(cinfo.output_scanline < bitmap_height);
        // 
        free(buffer);
        //
        jpeg_finish_decompress(&cinfo);
        jpeg_destroy_decompress(&cinfo);
        src = cast(jpeg_extend_source_mgr*)cinfo.src;
        free(src.buffer);
        free(src);
      }
    }
    /*
     * ファイル上のPNGから，画像データを読み込む
     *
     * Params:
     *  fname = 読み込む対象のファイル名
    */
    void load_png_file(string fname, color alpha)
    in{
      assert(exists(fname));
    }
    out{
      assert(standard_map !is null);
    }
    do{
      ubyte[] buf = cast(ubyte[])read(fname);
      load_png_memory(buf, alpha);
    }
    /*
     * メモリ上のPNGから，画像データを読み込む
     *
     * Params:
     *  data = 読み込む対象の先頭データ
    */
    void load_png_memory(ubyte[] data, color alpha)
    in{
      assert(cast(char[])data[0..8] == "\x89PNG\r\n\x1a\n");
    }
    out{
      assert(standard_map !is null);
    }
    do{
      StreamBuffer stream = new StreamBuffer(data);
      load_png_common(stream, alpha);
    }
    /*
     * PNGデータを読み込むための共通処理
     *
     * Params:
     *  data = 読み込む対象となるデータ
    */
    void load_png_common(StreamBuffer data, color alpha)
    out{
      assert(standard_map !is null);
    }
    do{
      png_struct* png_struct;
      png_info* png_info;
      int bit_size;
      int color_type;
      png_color* palette;
      png_struct = png_create_read_struct(cast(char*)PNG_LIBPNG_VER_STRING, null, null, null);
      enforce(png_struct !is null,
              new IllegalFormatException("Png struct create failed"));
      png_info = png_create_info_struct(png_struct);
      png_set_tRNS_to_alpha(png_struct);
      enforce(png_info !is null,
              new IllegalFormatException("Pnginfo create failed"));
      png_set_read_fn(png_struct, cast(void*)data, &load_png_callback);
      png_read_info(png_struct, png_info);
      png_get_IHDR(png_struct, png_info, &bitmap_width, &bitmap_height, &bit_size,
                   &color_type, null, null, null);
      create_bitmap();
      // インデックスカラーのみ透明色を確保
      /*if(color_type == PNG_COLOR_TYPE_PALETTE){
        palette = cast(png_color*)malloc(png_color.sizeof * 0x100);
        png_get_PLTE(png_struct, png_info, cast(png_color**)&palette, &i);
        png_get_tRNS(png_struct, png_info, null, &j, null);
        writefln("%d", j);
        if(j > 0 && j <= 0x100){
          invisible.red = palette[j-1].red;
          invisible.green = palette[j-1].green;
          invisible.blue = palette[j-1].blue;
          invisible.alpha = 0xFF;
        }
      }
      */
      // 色変換
      if(png_get_valid(png_struct, png_info, PNG_INFO_tRNS) ||
         color_type == PNG_COLOR_TYPE_PALETTE ||
         (color_type == PNG_COLOR_TYPE_GRAY && bit_size < 8)){
        png_set_expand(png_struct);
      }
      if(bit_size > 8){
        png_set_strip_16(png_struct);
      }
      if(color_type == PNG_COLOR_TYPE_GRAY){
        png_set_gray_to_rgb(png_struct);
      }
      if(!(color_type & PNG_COLOR_MASK_ALPHA)){
        png_set_filler(png_struct, 0xFF, 1);
      }
      // データを読み込ませる
      foreach(n; 0..height){
        png_read_row(png_struct, cast(ubyte*)&standard_map[n*tex_width], null);
      }
      png_read_end(png_struct, null);
      // パレットに透明色が存在する場合、透明色を適用
      for(Signed!(size_t) n = (height - 1); n >= 0; n -= 1){
        foreach(o; 0..bitmap_width){
          if(standard_map[data_position(n, o)].red == alpha.red &&
             standard_map[data_position(n, o)].green == alpha.green &&
             standard_map[data_position(n, o)].blue == alpha.blue){
            standard_map[data_position(n, o)].alpha = alpha.alpha;
          }
          //if(color_type == PNG_COLOR_TYPE_PALETTE && standard_map[data_position(n, o)] == invisible){
            //standard_map[data_position(n, o)].alpha = 0;
          //}
        }
      }
      if(color_type == PNG_COLOR_TYPE_PALETTE){
        free(palette);
      }
      png_destroy_read_struct(&png_struct, &png_info, null);
    }
    /**
     * BMPファイルから、データを読み込む
     *
     * Params:
     *  fname = 読み込む対象のファイル名
    */
    void load_bmp_file(string fname, color alpha)
    in{
      assert(exists(fname));
    }
    out{
      assert(standard_map !is null);
    }
    do{
      ubyte[] buf = cast(ubyte[])read(fname);
      load_bmp_memory(buf, alpha);
    }
    /*
     * メモリ上のBMPから，画像データを読み込む
     *
     * Params:
     *  data = 読み込む対象の先頭データ
    */
    void load_bmp_memory(ubyte[] data, color alpha)
    in{
      assert(data[0] == 'B' && data[1] == 'M');
    }
    out{
      assert(standard_map !is null);
    }
    do{
      // ビットマップファイルのサイズはどうやって計測する？
      // ヘッダサイズを求める カラーパレット 後何のチャンクがあったっけ ビットマップデータ
      StreamBuffer io = new StreamBuffer(data);
      load_bmp_common(io, alpha);
    }
    /*
     * BMPデータを読み込むための共通処理
     *
     * Params:
     *  data = 読み込む対象となるデータ
     *  read_func = データの読み込みを行うための関数
     *  seek_func = 読み込み開始位置の移動を行うための関数
    */
    void load_bmp_common(StreamBuffer data, color alpha)
    in{
      assert(data !is null);
    }
    do{
      char[2] header;
      BMP_TYPE type;
      uint parette_size;
      ushort bit_count;
      uint compress;
      color[] colors;
      bitmapinfo_header head_data;
      bool mode;
      //
      data.read(header);
      enforce(header == "BM",
              new IllegalFormatException("Not bmp format"));
      data.seek(14, SeekPos.SET);
      data.read(type);
      //
      if(type == BMP_TYPE.OS_2){
        bitmapcore_header core_data;
        data.read(core_data);
        bitmap_width = core_data.width;
        bitmap_height = core_data.height.abs;
        parette_size = 0;
        bit_count = core_data.bitcount;
        compress = 0;
        mode = (core_data.height > 0);
      }else{
        data.read(head_data, type - type.sizeof);
        bitmap_width = head_data.width;
        bitmap_height = head_data.height.abs;
        parette_size = head_data.color_used;
        bit_count = head_data.bitcount;
        compress = head_data.compression;
        mode = (head_data.height > 0);
      }
      //
      create_bitmap();
      // 8ビット以下もしくはパレットカラーが存在する場合、パレットを取得
      if((bit_count > 0 && bit_count <= 8) || parette_size > 0){
        if(parette_size == 0){
          parette_size = 1 << bit_count;
        }
        colors.length = parette_size;
        if(type == BMP_TYPE.OS_2){
          foreach(i; 0..parette_size){
            data.read(colors[i], 3);
          }
          // BGRAをRGBAに変換
          foreach(i; 0..parette_size){
            ubyte temp;
            temp = colors[i].red;
            colors[i].red = colors[i].blue;
            colors[i].blue = temp;
            if(colors[i].red == alpha.red &&
               colors[i].green == alpha.green &&
               colors[i].blue == alpha.blue){
              colors[i].alpha = alpha.alpha;
            }else{
              colors[i].alpha = 0xFF;
            }
          }
        }
        if(type == BMP_TYPE.WINDOWS){
          colors.length = parette_size;
          data.read(colors);
          // BGRAをRGBAに変換
          foreach(i; 0..parette_size){
            ubyte temp;
            temp = colors[i].red;
            colors[i].red = colors[i].blue;
            colors[i].blue = temp;
            if(colors[i].red == alpha.red &&
               colors[i].green == alpha.green &&
               colors[i].blue == alpha.blue){
              colors[i].alpha = alpha.alpha;
            }else if(bit_count <= 24){
              colors[i].alpha = 0xFF;
            }
          }
        }
      }
      if(compress == 0){ // No compress
        ubyte[] buffer;
        buffer.length = ((bitmap_width * bit_count) + 31) / 32 * 4;
        foreach(Signed!(size_t) i; 0..bitmap_height){
          if(mode){
            i = bitmap_height - i - 1;
          }
          data.read(buffer);
          if(bit_count >= 8){
            foreach(j; 0..bitmap_width){
              // 1ピクセルに使われているビット数に応じて処理を変更
              switch(bit_count){
              case 8:
                standard_map[data_position(i, j)] = colors[buffer[j]];
                break;
              case 16:
                standard_map[data_position(i, j)].blue = cast(ubyte)((buffer[j*2] & 0x1F) * 255 / 31);
                standard_map[data_position(i, j)].green = cast(ubyte)((((buffer[j*2] & 0xE0) >> 5) + ((buffer[j*2+1] & 0x03) << 3)) * 255 / 31);
                standard_map[data_position(i, j)].red = cast(ubyte)(((buffer[j*2+1] & 0x7C) >> 2) * 255 / 31);
                if(standard_map[data_position(i, j)].red == alpha.red &&
                   standard_map[data_position(i, j)].green == alpha.green &&
                   standard_map[data_position(i, j)].blue == alpha.blue){
                  standard_map[data_position(i, j)].alpha = alpha.alpha;
                }else{
                  standard_map[data_position(i, j)].alpha = 0xFF;
                }
                break;
              case 24:
                standard_map[data_position(i, j)].red = buffer[j*3+2];
                standard_map[data_position(i, j)].green = buffer[j*3+1];
                standard_map[data_position(i, j)].blue = buffer[j*3];
                if(standard_map[data_position(i, j)].red == alpha.red &&
                   standard_map[data_position(i, j)].green == alpha.green &&
                   standard_map[data_position(i, j)].blue == alpha.blue){
                  standard_map[data_position(i, j)].alpha = alpha.alpha;
                }else{
                  standard_map[data_position(i, j)].alpha = 0xFF;
                }
                break;
              case 32:
                standard_map[data_position(i, j)].red = buffer[j*4+2];
                standard_map[data_position(i, j)].green = buffer[j*4+1];
                standard_map[data_position(i, j)].blue = buffer[j*4];
                if(standard_map[data_position(i, j)].red == alpha.red &&
                   standard_map[data_position(i, j)].green == alpha.green &&
                   standard_map[data_position(i, j)].blue == alpha.blue){
                  standard_map[data_position(i, j)].alpha = alpha.alpha;
                }else{
                  standard_map[data_position(i, j)].alpha = 0xFF;
                }
                break;
              default:
                throw(new IllegalFormatException("Undefined bitmap pixel size"));
              }
            }
          }else{
            foreach(j; 0..(((bitmap_width * bit_count) + 7) / 8)){
              switch(bit_count){
              case 4:
                standard_map[data_position(i, j * 2)] = colors[buffer[j] >> 4];
                if(j * 2 + 1 < bitmap_width){
                  standard_map[data_position(i, j * 2 + 1)] = colors[buffer[j] & 0x0F];
                }
                break;
              case 2:
                standard_map[data_position(i, j * 4)] = colors[buffer[j] >> 6];
                if(j * 4 + 1 < bitmap_width){
                  standard_map[data_position(i, j * 4 + 1)] = colors[(buffer[j] >> 4) & 0x03];
                  if(j * 4 + 2 < bitmap_width){
                    standard_map[data_position(i, j * 4 + 2)] = colors[(buffer[j] >> 2) & 0x03];
                    if(j * 4 + 3 < bitmap_width){
                      standard_map[data_position(i, j * 4 + 3)] = colors[buffer[j] & 0x03];
                    }
                  }
                }
                break;
              case 1:
                foreach(size_t k; 0..8){
                  if(j * 8 + k >= bitmap_width){
                    break;
                  }
                  if(buffer[j] & (0x80 >> k)){
                    standard_map[data_position(i, j * 8 + k)] = colors[1];
                  }else{
                    standard_map[data_position(i, j * 8 + k)] = colors[0];
                  }
                }
                break;
              default:
                throw(new IllegalFormatException("Undefined bitmap pixel size"));
              }
            }
          }
        }
      }else if(compress == 1 || compress == 2){ // RLE(1,RLE8 2,RLE4)
        ubyte* buffer;
        bool abs = false;
        uint x;
        uint y;
        uint size;
        uint count;
        bool odd;
        //
        size = cast(uint)(data.size - data.tell());
        buffer = cast(ubyte*)malloc(size);
        y = bitmap_height - 1;
        //
        data.read(buffer, size);
        for(auto i = 0; i < size; i += 1){
          // 絶対モードでの書き出し
          if(abs){
            if(compress == 1){
              standard_map[data_position(y, x)] = colors[buffer[i]];
              x += 1;
              count -= 1;
            }else{
              standard_map[data_position(y, x)] = colors[buffer[i] >> 4];
              x += 1;
              count -= 1;
              if(count > 0){
                standard_map[data_position(y, x)] = colors[buffer[i] & 0x0F];
                x += 1;
                count -= 1;
              }
            }
            if(count == 0){
              abs = false;
              if(odd){
                i += 1;
              }
            }
          // 通常書き出し
          }else{
            if(buffer[i] == 0){
              // 行末
              if(buffer[i+1] == 0){
                y -= 1;
                x = 0;
                abs = false;
                i += 1;
              // 終端
              }else if(buffer[i+1] == 1){
                break;
              // 位置移動
              }else if(buffer[i+1] == 2){
                y -= buffer[i+3];
                x += buffer[i+2];
                i += 3;
              }else{
              // 絶対モード
                abs = true;
                count = buffer[i+1];
                if(compress == 1){
                  odd = ((count & 1) != 0);
                }else{
                  odd = (((count + 1) & 2) != 0);
                }
                i += 1;
              }
            }else{
              if(compress == 1){
                foreach(j; 0..buffer[i]){
                  standard_map[data_position(y, x)] = colors[buffer[i+1]];
                  x += 1;
                }
              }else{
                foreach(j; 0..buffer[i]){
                  if(j & 1){
                    standard_map[data_position(y, x)] = colors[buffer[i+1] & 0x0F];
                  }else{
                    standard_map[data_position(y, x)] = colors[buffer[i+1] >> 4];
                  }
                  x += 1;
                }
              }
              i += 1;
            }
          }
        }
        if(buffer !is null){
          free(buffer);
        }
      }else if(compress == 3){ // ビットフィールド
        color_mask bit;
        uint bit_sum;
        color_mask check;
        data.read(bit.red);
        data.read(bit.green);
        data.read(bit.blue);
        bit.alpha = head_data.alpha_mask;
        foreach(i; 0..bit.data.length){
          check.data[i] = bit.data[i] & -bit.data[i];
          if((bit.data[i] + check.data[i]) & (bit.data[i] + check.data[i] - 1)){
            throw(new IllegalFormatException("Invalid bitmask"));
          }
        }
        bit_sum = (bit.red + bit.green + bit.blue + bit.alpha);
        if((bit.red | bit.green | bit.blue | bit.alpha) != bit_sum){
          throw(new IllegalFormatException("Invalid bitmask"));
        }
        //
        if(bit_count == 16){
          if(bit_sum >= 0x00010000){
           throw(new IllegalFormatException("Invalid bitmask"));
          }
          ushort[] buffer;
          buffer.length = (((bitmap_width * bit_count) + 31) / 32 * 4);
          foreach(Signed!(size_t) i; 0..bitmap_height){
            if(mode){
              i = bitmap_height - i - 1;
            }
            data.read(buffer);
            foreach(j; 0..bitmap_width){
              standard_map[data_position(i, j)].red = cast(ubyte)((bit.red & buffer[j]) / check.red * 255 / (bit.red / check.red));
              standard_map[data_position(i, j)].green = cast(ubyte)((bit.green & buffer[j]) / check.green * 255 / (bit.green / check.green));
              standard_map[data_position(i, j)].blue = cast(ubyte)((bit.blue & buffer[j]) / check.blue * 255 / (bit.blue / check.blue));
              if(bit.alpha != 0){
                standard_map[data_position(i, j)].alpha = cast(ubyte)((bit.alpha & buffer[j]) / check.alpha * 255 / (bit.alpha / check.alpha));
              }else if(standard_map[data_position(i, j)].red == alpha.red &&
                 standard_map[data_position(i, j)].green == alpha.green &&
                 standard_map[data_position(i, j)].blue == alpha.blue){
                standard_map[data_position(i, j)].alpha = alpha.alpha;
              }else{
                standard_map[data_position(i, j)].alpha = 0xFF;
              }
            }
          }
        }else if(bit_count == 32){
          uint[] buffer;
          buffer.length = (((bitmap_width * bit_count) + 31) / 32 * 4);
          foreach(Signed!(size_t) i; 0..bitmap_height){
            if(mode){
              i = bitmap_height - i - 1;
            }
            data.read(buffer);
            foreach(j; 0..bitmap_width){
              standard_map[data_position(i, j)].red = cast(ubyte)((bit.red & buffer[j]) / check.red * 255 / (bit.red / check.red));
              standard_map[data_position(i, j)].green = cast(ubyte)((bit.green & buffer[j]) / check.green * 255 / (bit.green / check.green));
              standard_map[data_position(i, j)].blue = cast(ubyte)((bit.blue & buffer[j]) / check.blue * 255 / (bit.blue / check.blue));
              if(bit.alpha != 0){
                standard_map[data_position(i, j)].alpha = cast(ubyte)((bit.alpha & buffer[j]) / check.alpha * 255 / (bit.alpha / check.alpha));
              }else if(standard_map[data_position(i, j)].red == alpha.red &&
                 standard_map[data_position(i, j)].green == alpha.green &&
                 standard_map[data_position(i, j)].blue == alpha.blue){
                standard_map[data_position(i, j)].alpha = alpha.alpha;
              }else{
                standard_map[data_position(i, j)].alpha = 0xFF;
              }
            }
          }
        }else{
          throw(new IllegalFormatException("Undefined bitmap pixel size"));
        }
      }else if(compress == 4){ // jpeg
        ubyte[] buffer;
        size_t size;
        //
        size = cast(size_t)(data.size - data.tell);
        buffer.length = size;
        //
        data.read(buffer);
        load_jpg_memory(buffer, alpha);
      }else if(compress == 5){ // png
        ubyte[] buffer;
        size_t size;
        //
        size = cast(size_t)(data.size - data.tell);
        buffer.length = size;
        //
        data.read(buffer);
        load_png_memory(buffer, alpha);
      }else{
        throw(new IllegalFormatException("Unsurpported compress mode"));
      }
    }
  }
}
