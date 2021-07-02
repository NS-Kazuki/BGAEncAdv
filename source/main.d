module bgaencoder;
//
import formats;
//

import ffmpeg.libavutil.avstring;
import ffmpeg.libavutil.avutil;
import ffmpeg.libavutil.dict;
import ffmpeg.libavutil.frame;
import ffmpeg.libavutil.imgutils;
import ffmpeg.libavutil.mathematics;
import ffmpeg.libavutil.mem;
import ffmpeg.libavutil.pixfmt;
import ffmpeg.libavutil.rational;

import ffmpeg.libavcodec.avcodec;

import ffmpeg.libavformat.avformat;
import ffmpeg.libavformat.avio;

import ffmpeg.libswscale.swscale;

//

import ngbase.loadimage;
import ngbase.bitmap;

//

import loader.load;
import loader.data;

import util.fraction;
import util.toint;
import util.code;
import util.dir;

import std.conv;
import std.file;
import std.path;
import std.stdio;
import std.string;
import std.traits;
import core.memory;
import core.stdc.stdlib;

alias CaseSensitive = std.string.CaseSensitive;
//

private{
  struct EncodeData{
    string infile;
    string outfile;
    string audiofile;
    fractionI framerate = fractionI(30, 1);
    real min_frames;
    uint width = 0;
    uint height = 0;
    int bgawidth = 0;
    int bgaheight = 0;
    int top = 0;
    uint layer = 2;
  }

  struct AudioData{
    AVCodec* codec;
    AVCodecContext* context;
    AVFormatContext* format;
    AVInputFormat input;
    AVStream* stream;
    fractionI time;
    uint index;
  }

  struct Moviedata{
    AVCodec* codec;
    AVCodecContext* context;
    AVFormatContext* format;
    AVInputFormat input;
    AVStream* stream;
    AVFrame* picture;
    AVFrame* dest;
    SwsContext* swscale;
    uint index;
    bool playing = false;
    bool start = false;
    fractionL count;
    fractionL time;
  }

  enum FlagMode{
    NONE,
    INFILE,
    OUTFILE,
    AUDIOFILE,
    FRAMERATE,
    WIDTH,
    HEIGHT,
    TOP,
    LAYER,
  }

  enum bga_mode{
    NONE,
    IMAGE = 0x01,
    MOVIE = 0x02,
    TRIMMING = 0x04,
  }
  struct rect{
    int top;
    int bottom;
    int left;
    int right;
  }

  struct layer_data{
    uint layer = 0;
    argb color;
  }

  AVPacket packet;

  alias write_func = void function(AVFrame*, ref layer_data[4], ref color[4], uint, uint);

  immutable write_func[16] write_pixel = [&_write_pixel!(0x00), &_write_pixel!(0x01), &_write_pixel!(0x02), &_write_pixel!(0x03),
                                          &_write_pixel!(0x04), &_write_pixel!(0x05), &_write_pixel!(0x06), &_write_pixel!(0x07),
                                          &_write_pixel!(0x08), &_write_pixel!(0x09), &_write_pixel!(0x0A), &_write_pixel!(0x0B),
                                          &_write_pixel!(0x0C), &_write_pixel!(0x0D), &_write_pixel!(0x0E), &_write_pixel!(0x0F)];
}

/**
 *
*/
void save_frame(BMS_data b, ref ImageBitmap[] images, ref Moviedata[size_t] movies, ref AudioData audio, ref EncodeData option, ref bga_mode[] modes){
  AVCodec* codec;
  AVCodecContext* context;
  AVFormatContext* format;
  AVOutputFormat* output;
  AVStream* video_stream;
  AVStream* audio_stream;
  AVDictionary* dict;
  int ret;
  int x;
  int y;
  int got_output;
  AVFrame* picture;
  long pts;
  //
  uint background_position;
  uint argb_position;
  uint bpm_position;
  bool need_update;
  fractionL time;
  fractionL count;
  uint framenum;
  layer_data[4] layer;
  //
  time = fractionL(option.framerate.denominator * 1_000_000L, option.framerate.numerator);
  count = fractionL(0, time.denominator);
  framenum = 0;
  //
  layer[0].color.values[] = 0xFF;
  layer[1].color.values[] = 0xFF;
  layer[2].color.values[] = 0xFF;
  layer[3].color.values[] = 0xFF;
  //
  codec = avcodec_find_encoder(AVCodecID.AV_CODEC_ID_HUFFYUV);
  if(!codec){
    stderr.writeln("codec not found");
    exit(1);
  }
  context = avcodec_alloc_context3(codec);
  picture = av_frame_alloc();
  //
  format = avformat_alloc_context();
  output = av_guess_format(ptr(AVFormat.AV_FORMAT_AVI), null, null);
  video_stream = avformat_new_stream(format, codec);
  
  format.oformat = output;
  video_stream.codec = context;
  
  av_strlcpy(format.filename.ptr, option.outfile.ptr, format.filename.length);
  //
  context.width = option.width;
  context.height = option.height;
  
  context.codec_id = codec.id;
  context.codec_type = AVMediaType.AVMEDIA_TYPE_VIDEO;
  //
  context.time_base = cast(AVRational)option.framerate.reverse;
  context.gop_size = 10;
  context.max_b_frames = 1;
  //
  context.pix_fmt = AVPixelFormat.AV_PIX_FMT_BGRA;
  //
  for(size_t i = 0;; i += 1){
    if(context.pix_fmt == codec.pix_fmts[i]){
      break;
    }
    if(codec.pix_fmts[i] < 0){
      context.pix_fmt = codec.pix_fmts[0];
      break;
    }
  }
  //
  video_stream.time_base = context.time_base;
  //
  if(avcodec_open2(context, codec, null) < 0){
    stderr.writeln("could not open codec");
    exit(1);
  }
  //
  if(option.audiofile != ""){
    audio_stream = avformat_new_stream(format, audio.codec);
    audio_stream.codec = audio.context;
    audio_stream.time_base = audio.context.time_base;
  }
  //
  if (!(format.flags & AVFMT_NOFILE)){
    ret = avio_open(&format.pb, format.filename.ptr, AVIO_FLAG_WRITE);
    if(ret < 0){
      stderr.writeln("can't open output file.");
    }
  }
  picture.format = context.pix_fmt;
  picture.width  = context.width;
  picture.height = context.height;
  
  ret = av_image_alloc(cast(ubyte*[4])picture.data[0..4], cast(int[4])picture.linesize[0..4], picture.width, picture.height, context.pix_fmt, 32);
  (cast(uint**)picture.data)[0][0..(picture.height * picture.linesize[0] / 4)] = 0xFF000000;
  if(ret < 0){
    stderr.writeln("could not alloc raw picture buffer");
    exit(1);
  }
  //
  avformat_write_header(format, &dict);
  //
  negative:
  while(background_position < b.background_list.length || movie_playing(movies)){
    need_update = false;
    while(background_position < b.background_list.length && b.background_list[background_position].time <= count){
      switch(b.background_list[background_position].type){
      case Object_type.BGA_BASE:
        change_movie(layer[0].layer, b.background_list[background_position].value, movies, b.bga_list, modes, count);
        layer[0].layer = b.background_list[background_position].value;
        break;
      case Object_type.BGA_LAYER1:
        change_movie(layer[1].layer, b.background_list[background_position].value, movies, b.bga_list, modes, count);
        layer[1].layer = b.background_list[background_position].value;
        break;
      case Object_type.BGA_LAYER2:
        change_movie(layer[2].layer, b.background_list[background_position].value, movies, b.bga_list, modes, count);
        layer[2].layer = b.background_list[background_position].value;
        break;
      case Object_type.BGA_POOR:
        change_movie(layer[3].layer, b.background_list[background_position].value, movies, b.bga_list, modes, count);
        layer[3].layer = b.background_list[background_position].value;
        break;
      case Object_type.ALPHA_BASE:
        layer[0].color.a = cast(ubyte)b.background_list[background_position].value;
        break;
      case Object_type.ALPHA_LAYER1:
        layer[1].color.a = cast(ubyte)b.background_list[background_position].value;
        break;
      case Object_type.ALPHA_LAYER2:
        layer[2].color.a = cast(ubyte)b.background_list[background_position].value;
        break;
      case Object_type.ALPHA_POOR:
        layer[3].color.a = cast(ubyte)b.background_list[background_position].value;
        break;
      default:
        break;
      }
      background_position += 1;
      need_update = true;
    }
    if(b.argb_list.length > 0){
      while(argb_position < b.argb_list.length && b.argb_list[argb_position].time <= count){
        switch(b.argb_list[argb_position].type){
        case Object_type.ARGB_BASE:
          layer[0].color = b.argb_list[argb_position].value;
          break;
        case Object_type.ARGB_LAYER1:
          layer[1].color = b.argb_list[argb_position].value;
          break;
        case Object_type.ARGB_LAYER2:
          layer[2].color = b.argb_list[argb_position].value;
          break;
        case Object_type.ARGB_POOR:
          layer[3].color = b.argb_list[argb_position].value;
          break;
        default:
          break;
        }
        argb_position += 1;
        need_update = true;
      }
    }
    if(b.BPM_list.length > 0){
      while(bpm_position < b.BPM_list.length && b.BPM_list[bpm_position].time <= count){
        if(b.BPM_list[bpm_position].value <= 0){
          break negative;
        }
        bpm_position += 1;
      }
    }
    foreach(ref Moviedata movie; movies){
      if(movie.playing){
        if(!movie.start){
          load_frame(movie);
        }
        while(movie.count < count && movie.playing){
          load_frame(movie);
          need_update = true;
        }
      }
    }
    //
    av_init_packet(&packet);
    
    //
    if(need_update){
      copy_bitmap(picture, images, movies, b.bga_list, layer, option, modes);
    }
    
    picture.pts = framenum;
    //
    ret = avcodec_encode_video2(context, &packet, picture, &got_output);
    
    if(ret < 0){
      stderr.writeln("error encoding frame");
      exit(1);
    }
    if(got_output){
      packet.stream_index = 0;
      writefln("encoding frame %05d", framenum);
      av_write_frame(format, &packet);
    }
    av_free_packet(&packet);
    count = count + time;
    framenum += 1;
  }
  //
  if(option.audiofile != ""){
    if(option.min_frames > framenum){
      av_init_packet(&packet);
      copy_bitmap(picture, images, movies, b.bga_list, layer, option, modes);
      ret = avcodec_encode_video2(context, &packet, picture, &got_output);
      if(got_output){
        while(option.min_frames > framenum){
          packet.pts = framenum;
          packet.dts = framenum;
          av_write_frame(format, &packet);
          writefln("encoding same frame %05d", framenum);
          framenum += 1;
        }
      }
      av_free_packet(&packet);
    }
    copy_audio(audio, format);
  }
  //
  av_write_trailer(format);
  if((format.flags & AVFMT_NOFILE) != 0){
    ret = avio_close(format.pb);
    if(ret < 0){
      stderr.writeln("can't close output file.");
    }
  }
  avcodec_close(context);
  av_free(context);
  av_freep(picture.data.ptr);
  av_freep(format.streams);
  av_frame_free(&picture);
  writeln("Finish!");
  return;
}

void copy_audio(ref AudioData audio, AVFormatContext* format){
  uint ret;
  for(uint i = 0;; i += 1){
    av_init_packet(&packet);
    ret = av_read_frame(audio.format, &packet);
    packet.stream_index = 1;
    av_write_frame(format, &packet);
    if(packet.size == 0){
      break;
    }
    av_free_packet(&packet);
  }
}

/**
 *
*/
void copy_bitmap(T : trimming[])(AVFrame* picture, ref ImageBitmap[] images, ref Moviedata[size_t] movies, ref T trimmings, ref layer_data[4] layer, ref EncodeData option, ref bga_mode[] modes){
  color[4] bit;
  ulong temp;
  int[4] xx;
  int[4] yy;
  rect[4] rects;
  uint writemode;
  write_func write;
  foreach(size_t i; 0..4){
    if(layer[i].layer > 0 && ((option.layer <= 1 && i == 3) || (option.layer > 0 && i != 3))){
      if(modes[layer[i].layer] & bga_mode.TRIMMING){
        if(modes[trimmings[layer[i].layer].number] & ~bga_mode.TRIMMING){
          writemode |= (1 << i);
          xx[i] = (trimmings[layer[i].layer].xstart - trimmings[layer[i].layer].dx) - cast(int)(picture.width - 256) / 2;
          yy[i] = (trimmings[layer[i].layer].ystart - trimmings[layer[i].layer].dy) - option.top;
          if(modes[trimmings[layer[i].layer].number] & bga_mode.MOVIE){
            rects[i].top = trimmings[layer[i].layer].ystart > 0 ? trimmings[layer[i].layer].ystart : 0;
            rects[i].bottom = movies[trimmings[layer[i].layer].number].dest.height < trimmings[layer[i].layer].yend ? movies[trimmings[layer[i].layer].number].dest.height : trimmings[layer[i].layer].yend;
            rects[i].left = trimmings[layer[i].layer].xstart > 0 ? trimmings[layer[i].layer].xstart : 0;
            rects[i].right = movies[trimmings[layer[i].layer].number].dest.width < trimmings[layer[i].layer].xend ? movies[trimmings[layer[i].layer].number].dest.width : trimmings[layer[i].layer].xend;
          }else{
            rects[i].top = trimmings[layer[i].layer].ystart > 0 ? trimmings[layer[i].layer].ystart : 0;
            rects[i].bottom = images[trimmings[layer[i].layer].number].height < trimmings[layer[i].layer].yend ? images[trimmings[layer[i].layer].number].height : trimmings[layer[i].layer].yend;
            rects[i].left = trimmings[layer[i].layer].xstart > 0 ? trimmings[layer[i].layer].xstart : 0;
            rects[i].right = images[trimmings[layer[i].layer].number].width < trimmings[layer[i].layer].xend ? images[trimmings[layer[i].layer].number].width : trimmings[layer[i].layer].xend;
          }
        }
      }else if(modes[layer[i].layer] == bga_mode.MOVIE){
        debug{
          if(layer[i].layer !in movies){
            stderr.writefln("Warning: NoImage command %d", layer[i].layer);
          }
        }
        writemode |= (1 << i);
        xx[i] = cast(int)(option.width - movies[layer[i].layer].dest.width) / -2;
        yy[i] = -cast(int)option.top;
        rects[i].top = 0;
        rects[i].bottom = movies[layer[i].layer].dest.height;
        rects[i].left = 0;
        rects[i].right = movies[layer[i].layer].dest.width;
      }else if(modes[layer[i].layer] == bga_mode.IMAGE){
        debug{
          if(layer[i].layer > 0 && images[layer[i].layer] is null){
            stderr.writefln("Warning: NoImage command %d", layer[i].layer);
          }
        }
        writemode |= (1 << i);
        xx[i] = cast(int)(option.width - images[layer[i].layer].width) / -2;
        yy[i] = -cast(int)option.top;
        rects[i].top = 0;
        rects[i].bottom = images[layer[i].layer].height;
        rects[i].left = 0;
        rects[i].right = images[layer[i].layer].width;
      }else{
        stderr.writefln("Warning: NoImage command %d", layer[i].layer);
      }
    }
  }
  write = write_pixel[writemode];
  //
  if(option.layer == 0){
    foreach(y; 0..(picture.height)){
      foreach(x; 0..(picture.width)){
        load_pixel(picture, images, movies, trimmings, layer[3].layer, option, modes, bit[3], rects[3], x + xx[3], yy[3]);
        _write_pixel!(0x08)(picture, layer, bit, x,y);
      }
      yy[3] += 1;
    }
  //
  }else if(option.layer == 1){
    foreach(y; 0..(picture.height)){
      foreach(x; 0..(picture.width)){
        if(writemode & 0x01){
          load_pixel(picture, images, movies, trimmings, layer[0].layer, option, modes, bit[0], rects[0], x + xx[0], yy[0]);
        }
        if(writemode & 0x02){
          load_pixel(picture, images, movies, trimmings, layer[1].layer, option, modes, bit[1], rects[1], x + xx[1], yy[1]);
        }
        if(writemode & 0x04){
          load_pixel(picture, images, movies, trimmings, layer[2].layer, option, modes, bit[2], rects[2], x + xx[2], yy[2]);
        }
        if(writemode & 0x08){
          load_pixel(picture, images, movies, trimmings, layer[3].layer, option, modes, bit[3], rects[3], x + xx[3], yy[3]);
        }
        write(picture, layer, bit, x, y);
      }
      yy[] += 1;
    }
  //
  }else{
    foreach(y; 0..(picture.height)){
      foreach(x; 0..(picture.width)){
        if(writemode & 0x01){
          load_pixel(picture, images, movies, trimmings, layer[0].layer, option, modes, bit[0], rects[0], x + xx[0], yy[0]);
        }
        if(writemode & 0x02){
          load_pixel(picture, images, movies, trimmings, layer[1].layer, option, modes, bit[1], rects[1], x + xx[1], yy[1]);
        }
        if(writemode & 0x04){
          load_pixel(picture, images, movies, trimmings, layer[2].layer, option, modes, bit[2], rects[2], x + xx[2], yy[2]);
        }
        write(picture, layer, bit, x, y);
      }
      yy[] += 1;
    }
  }
}

void load_pixel(T : trimming[])(AVFrame* picture, ref ImageBitmap[] images, ref Moviedata[size_t] movies, ref T trimmings, uint layer, ref EncodeData option, ref bga_mode[] modes, ref color bit, ref rect rect, uint xx, uint yy){
  if(modes[layer] & bga_mode.TRIMMING){
    if(modes[trimmings[layer].number] & bga_mode.MOVIE){
      if(movies[trimmings[layer].number].playing && yy >= rect.top && yy < rect.bottom && xx >= rect.left && xx < rect.right){
        bit.red = movies[trimmings[layer].number].dest.data[0][yy * movies[trimmings[layer].number].dest.linesize[0] + xx * 3 + 0];
        bit.green = movies[trimmings[layer].number].dest.data[0][yy  * movies[trimmings[layer].number].dest.linesize[0] + xx * 3 + 1];
        bit.blue = movies[trimmings[layer].number].dest.data[0][yy * movies[trimmings[layer].number].dest.linesize[0] + xx * 3 + 2];
        bit.alpha = 0xFF;
      }else{
        bit = color(0, 0, 0, 0);
      }
    }else{
      if(yy >= rect.top && yy < rect.bottom && xx >= rect.left && xx < rect.right){
        bit = images[trimmings[layer].number].data[images[trimmings[layer].number].data_position(yy, xx)];
      }else{
        bit = color(0, 0, 0, 0);
      }
    }
  }else if(modes[layer] == bga_mode.MOVIE){
    if(movies[layer].playing && yy >= rect.top && yy < rect.bottom && xx >= rect.left && xx < rect.right){
      bit.red = movies[layer].dest.data[0][yy * movies[layer].dest.linesize[0] + xx * 3 + 0];
      bit.green = movies[layer].dest.data[0][yy * movies[layer].dest.linesize[0] + xx * 3 + 1];
      bit.blue = movies[layer].dest.data[0][yy * movies[layer].dest.linesize[0] + xx * 3 + 2];
      bit.alpha = 0xFF;
    }else{
      bit = color(0, 0, 0, 0);
    }
  }else if(modes[layer] == bga_mode.IMAGE){
    if(yy >= rect.top && yy < rect.bottom && xx >= rect.left && xx < rect.right){
      bit = images[layer].data[images[layer].data_position(yy, xx)];
    }else{
      bit = color(0, 0, 0, 0);
    }
  }
}

void _write_pixel(int pictmode)(AVFrame* picture, ref layer_data[4] layer, ref color[4] bit, uint x, uint y){
  static if(pictmode == 0x00){
    picture.data[0][y * picture.linesize[0] + x * 4 + 0] = 0x00;
    picture.data[0][y * picture.linesize[0] + x * 4 + 1] = 0x00;
    picture.data[0][y * picture.linesize[0] + x * 4 + 2] = 0x00;
  }else static if(pictmode == 0x01 || pictmode == 0x02 || pictmode == 0x04 || pictmode == 0x08){
    uint temp;
    static if(pictmode == 0x01){
      immutable uint top = 0;
    }else static if(pictmode == 0x02){
      immutable uint top = 1;
    }else static if(pictmode == 0x04){
      immutable uint top = 2;
    }else static if(pictmode == 0x08){
      immutable uint top = 3;
    }
    // B
    temp = bit[top].blue * layer[top].color.b * bit[top].alpha * layer[top].color.a;
    picture.data[0][y * picture.linesize[0] + x * 4 + 0] = cast(ubyte)(temp / (0xFF * 0xFF * 0xFF));
    // G
    temp = bit[top].green * layer[top].color.g * bit[top].alpha * layer[top].color.a;
    picture.data[0][y * picture.linesize[0] + x * 4 + 1] = cast(ubyte)(temp / (0xFF * 0xFF * 0xFF));
    // R
    temp = bit[top].red * layer[top].color.r * bit[top].alpha * layer[top].color.a;
    picture.data[0][y * picture.linesize[0] + x * 4 + 2] = cast(ubyte)(temp / (0xFF * 0xFF * 0xFF));
  //
  }else static if(pictmode == 0x03 || pictmode == 0x05 || pictmode == 0x06 || pictmode == 0x09 || pictmode == 0x0A || pictmode == 0x0C){
    ulong temp;
    static if(pictmode == 0x03){
      immutable uint top = 1;
      immutable uint second = 0;
    }else static if(pictmode == 0x05){
      immutable uint top = 2;
      immutable uint second = 0;
    }else static if(pictmode == 0x06){
      immutable uint top = 2;
      immutable uint second = 1;
    }else static if(pictmode == 0x09){
      immutable uint top = 3;
      immutable uint second = 0;
    }else static if(pictmode == 0x0A){
      immutable uint top = 3;
      immutable uint second = 1;
    }else static if(pictmode == 0x0C){
      immutable uint top = 3;
      immutable uint second = 2;
    }
    // B
    temp = cast(ulong)bit[top].blue * layer[top].color.b * bit[top].alpha * layer[top].color.a * 0xFF * 0xFF +
           cast(ulong)bit[second].blue * layer[second].color.b * bit[second].alpha * layer[second].color.a * (0xFF * 0xFF - bit[top].alpha * layer[top].color.a);
    picture.data[0][y * picture.linesize[0] + x * 4 + 0] = cast(ubyte)(temp / (cast(ulong)0xFF * 0xFF * 0xFF * 0xFF * 0xFF));
    // G
    temp = cast(ulong)bit[top].green * layer[top].color.g * bit[top].alpha * layer[top].color.a * 0xFF * 0xFF +
           cast(ulong)bit[second].green * layer[second].color.g * bit[second].alpha * layer[second].color.a * (0xFF * 0xFF - bit[top].alpha * layer[top].color.a);
    picture.data[0][y * picture.linesize[0] + x * 4 + 1] = cast(ubyte)(temp / (cast(ulong)0xFF * 0xFF * 0xFF * 0xFF * 0xFF));
    // R
    temp = cast(ulong)bit[top].red * layer[top].color.r * bit[top].alpha * layer[top].color.a * 0xFF * 0xFF +
           cast(ulong)bit[second].red * layer[second].color.r * bit[second].alpha * layer[second].color.a * (0xFF * 0xFF - bit[top].alpha * layer[top].color.a);
    picture.data[0][y * picture.linesize[0] + x * 4 + 2] = cast(ubyte)(temp / (cast(ulong)0xFF * 0xFF * 0xFF * 0xFF * 0xFF));
  //
  }else static if(pictmode == 0x07 || pictmode == 0x0B || pictmode == 0x0D || pictmode == 0x0E){
    ulong temp;
    static if(pictmode == 0x07){
      immutable uint top = 2;
      immutable uint second = 1;
      immutable uint third = 0;
    }else static if(pictmode == 0x0B){
      immutable uint top = 3;
      immutable uint second = 1;
      immutable uint third = 0;
    }else static if(pictmode == 0x0D){
      immutable uint top = 3;
      immutable uint second = 2;
      immutable uint third = 0;
    }else static if(pictmode == 0x0E){
      immutable uint top = 3;
      immutable uint second = 2;
      immutable uint third = 1;
    }
    // B
    temp = cast(ulong)bit[top].blue * layer[top].color.b * bit[top].alpha * layer[top].color.a * 0xFF * 0xFF * 0xFF * 0xFF +
           cast(ulong)bit[second].blue * layer[second].color.b * bit[second].alpha * layer[second].color.a * (0xFF * 0xFF - bit[top].alpha * layer[top].color.a) * 0xFF * 0xFF +
           cast(ulong)bit[third].blue * layer[third].color.b * bit[third].alpha * layer[third].color.a * (0xFF * 0xFF - bit[top].alpha * layer[top].color.a) * (0xFF * 0xFF - bit[second].alpha * layer[second].color.a);
    picture.data[0][y * picture.linesize[0] + x * 4 + 0] = cast(ubyte)(temp / (cast(ulong)0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF));
    // G
    temp = cast(ulong)bit[top].green * layer[top].color.g * bit[top].alpha * layer[top].color.a * 0xFF * 0xFF * 0xFF * 0xFF +
           cast(ulong)bit[second].green * layer[second].color.g * bit[second].alpha * layer[second].color.a * (0xFF * 0xFF - bit[top].alpha * layer[top].color.a) * 0xFF * 0xFF +
           cast(ulong)bit[third].green * layer[third].color.g * bit[third].alpha * layer[third].color.a * (0xFF * 0xFF - bit[top].alpha * layer[top].color.a) * (0xFF * 0xFF - bit[second].alpha * layer[second].color.a);
    picture.data[0][y * picture.linesize[0] + x * 4 + 1] = cast(ubyte)(temp / (cast(ulong)0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF));
    // R
    temp = cast(ulong)bit[top].red * layer[top].color.r * bit[top].alpha * layer[top].color.a * 0xFF * 0xFF * 0xFF * 0xFF +
           cast(ulong)bit[second].red * layer[second].color.r * bit[second].alpha * layer[second].color.a * (0xFF * 0xFF - bit[top].alpha * layer[top].color.a) * 0xFF * 0xFF +
           cast(ulong)bit[third].red * layer[third].color.r * bit[third].alpha * layer[third].color.a * (0xFF * 0xFF - bit[top].alpha * layer[top].color.a) * (0xFF * 0xFF - bit[second].alpha * layer[second].color.a);
    picture.data[0][y * picture.linesize[0] + x * 4 + 2] = cast(ubyte)(temp / (cast(ulong)0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF));
  //
  }else{
    ulong temp;
    // B
    temp = cast(ulong)bit[3].blue * layer[3].color.b * bit[3].alpha * layer[3].color.a * 0xFF * 0xFF * 0xFF * 0xFF +
           cast(ulong)bit[2].blue * layer[2].color.b * bit[2].alpha * layer[2].color.a *
           (0xFF * 0xFF - bit[3].alpha * layer[3].color.a) * 0xFF * 0xFF +
           cast(ulong)bit[1].blue * layer[1].color.b * bit[1].alpha * layer[1].color.a * (0xFF * 0xFF - bit[3].alpha * layer[3].color.a) * (0xFF * 0xFF - bit[2].alpha * layer[2].color.a) +
           cast(ulong)bit[0].blue * layer[0].color.b * bit[0].alpha * layer[0].color.a * (cast(ulong)(0xFF * 0xFF - bit[3].alpha * layer[3].color.a) * (0xFF * 0xFF - bit[2].alpha * layer[2].color.a) * (0xFF * 0xFF - bit[1].alpha * layer[1].color.a) / (0xFF * 0xFF));
    picture.data[0][y * picture.linesize[0] + x * 4 + 0] = cast(ubyte)(temp / (cast(ulong)0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF));
    // G
    temp = cast(ulong)bit[3].green * layer[3].color.g * bit[3].alpha * layer[3].color.a * 0xFF * 0xFF * 0xFF * 0xFF +
           cast(ulong)bit[2].green * layer[2].color.g * bit[2].alpha * layer[2].color.a * (0xFF * 0xFF - bit[3].alpha * layer[3].color.a) * 0xFF * 0xFF +
           cast(ulong)bit[1].green * layer[1].color.g * bit[1].alpha * layer[1].color.a * (0xFF * 0xFF - bit[3].alpha * layer[3].color.a) * (0xFF * 0xFF - bit[2].alpha * layer[2].color.a) +
           cast(ulong)bit[0].green * layer[0].color.g * bit[0].alpha * layer[0].color.a * (cast(ulong)(0xFF * 0xFF - bit[3].alpha * layer[3].color.a) * (0xFF * 0xFF - bit[2].alpha * layer[2].color.a) * (0xFF * 0xFF - bit[1].alpha * layer[1].color.a) / (0xFF * 0xFF));
    picture.data[0][y * picture.linesize[0] + x * 4 + 1] = cast(ubyte)(temp / (cast(ulong)0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF));
    // R
    temp = cast(ulong)bit[3].red * layer[3].color.r * bit[3].alpha * layer[3].color.a * 0xFF * 0xFF * 0xFF * 0xFF +
           cast(ulong)bit[2].red * layer[2].color.r * bit[2].alpha * layer[2].color.a * (0xFF * 0xFF - bit[3].alpha * layer[3].color.a) * 0xFF * 0xFF +
           cast(ulong)bit[1].red * layer[1].color.r * bit[1].alpha * layer[1].color.a * (0xFF * 0xFF - bit[3].alpha * layer[3].color.a) * (0xFF * 0xFF - bit[2].alpha * layer[2].color.a) +
           cast(ulong)bit[0].red * layer[0].color.r * bit[0].alpha * layer[0].color.a * (cast(ulong)(0xFF * 0xFF - bit[3].alpha * layer[3].color.a) * (0xFF * 0xFF - bit[2].alpha * layer[2].color.a) * (0xFF * 0xFF - bit[1].alpha * layer[1].color.a) / (0xFF * 0xFF));
    picture.data[0][y * picture.linesize[0] + x * 4 + 2] = cast(ubyte)(temp / (cast(ulong)0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF * 0xFF));
  }
}

/**
 *
*/
EncodeData load_parameter(C)(C[] params) if(isSomeString!(C)){
  EncodeData result;
  FlagMode mode;
  mode = FlagMode.NONE;
  //
  foreach(i; 0..(params.length)){
    switch(mode){
    case FlagMode.NONE:
      if(params[i].indexOf("-f", CaseSensitive.yes) == 0){
        if(params[i] == "-f"){
          mode = FlagMode.FRAMERATE;
        }else{
          if(isFraction(params[i][("-f".length)..$])){
            if(toFraction!(int)(params[i][("-f".length)..$], true) > 0){
              result.framerate = toFraction!(int)(params[i][("-f".length)..$], true);
            }else{
              stderr.writefln("warning: \"%s\" is invalid.", params[i]);
            }
          }else{
            stderr.writefln("warning: \"%s\" is illegal command.", params[i]);
          }
        }
      //
      }else if(params[i].indexOf("-i", CaseSensitive.yes) == 0){
        if(params[i] == "-i"){
          mode = FlagMode.INFILE;
        }else{
          if(exists(params[i][("-i".length)..$])){
            result.infile = params[i][("-i".length)..$];
          }else{
            stderr.writefln("warning: \"%s\" is not found", params[i][("-i".length)..$]);
          }
        }
      //
      }else if(params[i].indexOf("-o", CaseSensitive.yes) == 0){
        if(exists(params[i][("-o".length)..$])){
          mode = FlagMode.OUTFILE;
        }else{
          result.outfile = params[i][("-o".length)..$];
        }
      //
      }else if(params[i].indexOf("-a", CaseSensitive.yes) == 0){
        if(params[i] == "-a"){
          mode = FlagMode.AUDIOFILE;
        }else if(exists(params[i][("-a".length)..$])){
          result.audiofile = params[i][("-a".length)..$];
        }else{
          stderr.writefln("warning: \"%s\" is not found", params[i][("-a".length)..$]);
        }
      //
      }else if(params[i].indexOf("-w", CaseSensitive.yes) == 0){
        if(params[i] == "-w"){
          mode = FlagMode.WIDTH;
        }else{
          if(isDigit(params[i][("-w".length)..$])){
            result.width = toDigit(params[i][("-w".length)..$], true);
          }else{
            stderr.writefln("warning: \"%s\" is illegal command.", params[i]);
          }
        }
      //
      }else if(params[i].indexOf("-h", CaseSensitive.yes) == 0){
        if(params[i] == "-h"){
          mode = FlagMode.HEIGHT;
        }else{
          if(isDigit(params[i][("-h".length)..$])){
            result.height = toDigit(params[i][("-h".length)..$], true);
          }else{
            stderr.writefln("warning: \"%s\" is illegal command.", params[i]);
          }
        }
      //
      }else if(params[i].indexOf("-t", CaseSensitive.yes) == 0){
        if(params[i] == "-t"){
          mode = FlagMode.TOP;
        }else{
          if(isDigit(params[i][("-t".length)..$])){
            result.top = toDigit(params[i][("-t".length)..$], true);
          }else{
            stderr.writefln("warning: \"%s\" is illegal command.", params[i]);
          }
        }
      //
      }else if(params[i].indexOf("-l", CaseSensitive.yes) == 0){
        if(params[i] == "-l"){
          mode = FlagMode.LAYER;
        }else{
          if(isDigit(params[i][("-l".length)..$])){
            result.layer = toDigit(params[i][("-l".length)..$], true);
          }else{
            stderr.writefln("warning: \"%s\" is illegal command.", params[i]);
          }
        }
      //
      }else{
        if(result.infile.length == 0){
          if(exists(params[i])){
            result.infile = params[i];
          }else{
            stderr.writefln("warning: \"%s\" is not found", params[i]);
          }
        }else if(result.outfile.length == 0){
          result.outfile = params[i];
        }else{
          stderr.writefln("warning: \"%s\" is undefined", params[i]);
        }
      }
      break;
    case FlagMode.INFILE:
      if(exists(params[i])){
        result.infile = params[i];
      }else{
        stderr.writefln("warning: \"%s\" is not found", params[i]);
      }
      mode = FlagMode.NONE;
      break;
    case FlagMode.OUTFILE:
      result.infile = params[i];
      mode = FlagMode.NONE;
      break;
    case FlagMode.AUDIOFILE:
      if(params[i].exists()){
        result.audiofile = params[i];
      }else{
        stderr.writefln("warning: \"%s\" is not found", params[i]);
      }
      mode = FlagMode.NONE;
      break;
    case FlagMode.FRAMERATE:
      if(isFraction(params[i])){
        if(toFraction!(int)(params[i], true) > 0){
          result.framerate = toFraction!(int)(params[i], true);
        }else{
          stderr.writefln("warning: \"%s\" is invalid.", params[i]);
        }
      }else{
        stderr.writefln("warning: \"%s\" is illegal command.", params[i]);
      }
      mode = FlagMode.NONE;
      break;
    case FlagMode.WIDTH:
      if(isDigit(params[i])){
        result.width = toDigit(params[i], true);
      }else{
        stderr.writefln("warning: \"%s\" is illegal command.", params[i]);
      }
      mode = FlagMode.NONE;
      break;
    case FlagMode.HEIGHT:
      if(isDigit(params[i])){
        result.height = toDigit(params[i], true);
      }else{
        stderr.writefln("warning: \"%s\" is illegal command.", params[i]);
      }
      mode = FlagMode.NONE;
      break;
    case FlagMode.TOP:
      if(isDigit(params[i])){
        result.top = toDigit(params[i]);
      }else{
        stderr.writefln("warning: \"%s\" is illegal command.", params[i]);
      }
      mode = FlagMode.NONE;
      break;
    case FlagMode.LAYER:
      if(isDigit(params[i])){
        result.layer = toDigit(params[i], true);
      }else{
        stderr.writefln("warning: \"%s\" is illegal command.", params[i]);
      }
      mode = FlagMode.NONE;
      break;
    default:
      stderr.writeln("warning: unknown option");
      break;
    }
  }
  if(mode != FlagMode.NONE){
    stderr.writeln("warning: ");
  }
  return result;
}

//import core.stdc.stdio;

/**
 *
*/
EncodeData write_parameter(C)(C[] params) if(isSomeString!(C)){
  EncodeData result;
  char[] s;
  stdin.flush();
  //
  if(params.length == 1){
    write("infile: ");
    readln(s);
    result.infile = cast(string)convert!(Charset.UTF8)(s, Charset.DEFAULT).cut.dup;
  }else{
    result.infile = params[1];
  }
  if(!exists(result.infile)){
    stderr.writefln("warning: \"%s\" is not found", result.infile);
  }
  //
  write("framerate(default=30, max=360): ");
  readln(s);
  if(isFraction(s.stripRight) && s.toFraction!(int)(true) > 0){
    result.framerate = s.toFraction!(int)(true);
  }
  //
  write("width(default=auto, max=65536): ");
  readln(s);
  if(isDigit(s.stripRight)){
    result.width = s.toDigit(true);
  }
  //
  write("height(default=auto, max=65536): ");
  readln(s);
  if(isDigit(s.stripRight)){
    result.height = s.toDigit(true);
  }
  //
  write("top margin(default=0): ");
  readln(s);
  if(isDigit(s.stripRight)){
    result.top = s.toDigit(true);
  }
  //
  writeln("layer mode: ");
  writeln("0 Misslayer only");
  writeln("1 Show all layer");
  writeln("2 Standard(default)");
  readln(s);
  if(isDigit(s.stripRight)){
    result.layer = s.toDigit(true);
  }
  //
  write("audio file(default=none): ");
  s.readln();
  if(s[0] != '\n' && s[0] != '\r'){
    if(s.isAbsolute()){
      result.audiofile = cast(string)(convert!(Charset.UTF8)(s, Charset.DEFAULT).stripRight.cut.dup);
    }else{
      result.audiofile = cast(string)(dirName(params[0]) ~ "/" ~ convert!(Charset.UTF8)(s, Charset.DEFAULT).stripRight.cut);
    }
  }
  if(result.audiofile != "" && !exists(result.audiofile)){
    stderr.writefln("warning: \"%s\" is not found", result.audiofile);
  }
  //
  write("outfile name(default=out.avi): ");
  readln(s);
  if(s[0] == '\n' || s[0] == '\r'){
    result.outfile = cast(string)(dirName(params[0]) ~ "/out.avi");
  }else if(isAbsolute(s)){
    result.outfile = cast(string)(convert!(Charset.UTF8)(s, Charset.DEFAULT).stripRight.cut.dup);
  }else{
    result.outfile = cast(string)(dirName(params[0]) ~ "/" ~ convert!(Charset.UTF8)(s, Charset.DEFAULT).stripRight.cut);
  }
  return result;
}

/**
 *
*/
C cut(C)(C str) if(isSomeString!(C)){
  if(str.length <= 1){
    return str;
  }
  str = str.stripRight;
  if(str[0] == '"' || str[0] == '\''){
    str = str[1..$];
  }
  if(str[$-1] == '"' || str[$-1] == '\''){
    str.length -= 1;
  }
  return str;
}

string exist_multitype(C)(C str, C basepath, C infile, string ext = "") if(isSomeString!(C)){
  C path;
  string imagefile;
  if(basepath.length > 0){
    path = basepath;
  }else{
    path = dirName(infile);
  }
  if(ext.length > 0){
    imagefile = load_path(cast(string)(path ~ dirSeparator ~ setExtension(str, ext)));
  }else{
    imagefile = load_path(cast(string)(path ~ dirSeparator ~ str));
  }
  if(exists(imagefile)){
    return imagefile;
  }else{
    return null;
  }
}

/**
 *
*/
void load_images(BMS_data b, ref EncodeData option, ref ImageBitmap[] images, ref Moviedata[size_t] movies, ref bga_mode[] modes){
  string imagefile;
  //
  foreach(i; 0..(b.bmp_list.length)){
    if(b.bmp_list[i].length > 0){
      imagefile = exist_multitype(b.bmp_list[i], b.path, option.infile);
      if(imagefile !is null){
        if(imagefile.extension.toLower == ".png" ||
           imagefile.extension.toLower == ".jpg" ||
           imagefile.extension.toLower == ".jpeg" ||
           imagefile.extension.toLower == ".bmp"){
          images[i] = new ImageBitmap(imagefile, color(0, 0, 0, 0));
          modes[i] = bga_mode.IMAGE;
          writefln("Load %s", convert!(Charset.DEFAULT)(imagefile, Charset.UTF8));
        }else{
          movies[i] = load_movie(imagefile);
          modes[i] = bga_mode.MOVIE;
          writefln("Load %s", convert!(Charset.DEFAULT)(imagefile, Charset.UTF8));
        }
      }else{
        foreach(exts; [".png", ".jpg", ".jpeg", ".bmp"]){
          imagefile = exist_multitype(cast()b.bmp_list[i], b.path, option.infile, exts);
          if(imagefile !is null){
            images[i] = new ImageBitmap(imagefile, color(0, 0, 0, 0));
            modes[i] = bga_mode.IMAGE;
            writefln("Load %s", convert!(Charset.DEFAULT)(imagefile, Charset.UTF8));
            break;
          }
        }
        if(imagefile is null){
          foreach(exts; [".mpg", ".mpeg", ".avi"]){
            imagefile = exist_multitype(b.bmp_list[i], b.path, option.infile, exts);
            if(imagefile !is null){
              movies[i] = load_movie(imagefile);
              modes[i] = bga_mode.MOVIE;
              writefln("Load %s", convert!(Charset.DEFAULT)(imagefile, Charset.UTF8));
              break;
            }
          }
          if(imagefile is null){
            stderr.writefln("%s is not found.", convert!(Charset.DEFAULT)(b.bmp_list[i], Charset.UTF8));
          }
        }
      }
    }
    if(b.bga_list[i].using){
      modes[i] |= bga_mode.TRIMMING;
    }
  }
}

/**
 *
*/
AudioData load_audio(C)(C str) if(isSomeString!(C)){
  AudioData result;
  uint ret;
  //
  result.format = avformat_alloc_context();
  ret = avformat_open_input(&result.format, cast(char*)(str.toStringz), null, null);
  //
  ret = avformat_find_stream_info(result.format, null);
  //
  for(auto i = 0; i < result.format.nb_streams; i++){
    if(result.format.streams[i].codec.codec_type == AVMediaType.AVMEDIA_TYPE_AUDIO){
      result.context = result.format.streams[i].codec;
      result.index = i;
      break;
    }
  }
  result.codec = avcodec_find_decoder(result.context.codec_id);
  ret = avcodec_open2(result.context, result.codec, null);
  //
  result.stream = result.format.streams[result.index];
  //
  result.time = cast(fractionI)result.stream.time_base * cast(uint)result.stream.duration;
  ret = avcodec_open2(result.context, result.codec, null);
  ret = avio_open(&result.format.pb, result.format.filename.ptr, AVIO_FLAG_READ);
  av_seek_frame(result.format, -1, 0, AVSEEK_FLAG_BACKWARD);
  //
  return result;
}

/**
 *
*/
void change_movie(T : trimming[])(uint before_id, uint after_id, ref Moviedata[size_t] movies, ref T trimmings, ref bga_mode[] modes, fractionL time){
  if(modes[before_id] & bga_mode.TRIMMING){
    if(modes[after_id] & bga_mode.TRIMMING){
      if(trimmings[after_id].number != trimmings[before_id].number){
        if(modes[trimmings[before_id].number] & bga_mode.MOVIE){
          stop_movie(movies[trimmings[before_id].number]);
        }
        if(modes[trimmings[after_id].number] & bga_mode.MOVIE){
          start_movie(movies[trimmings[after_id].number], time);
        }
      }
    }else{
      if(modes[after_id] != trimmings[before_id].number){
        if(modes[trimmings[before_id].number] & bga_mode.MOVIE){
          stop_movie(movies[trimmings[before_id].number]);
        }
        if(modes[after_id] & bga_mode.MOVIE){
          start_movie(movies[after_id], time);
        }
      }
    }
  }else if(modes[before_id] & bga_mode.MOVIE){
    if(modes[after_id] & bga_mode.TRIMMING){
      if(trimmings[after_id].number != before_id){
        stop_movie(movies[before_id]);
        if(modes[trimmings[after_id].number] & bga_mode.MOVIE){
          start_movie(movies[trimmings[after_id].number], time);
        }
      }
    }else{
      stop_movie(movies[before_id]);
      if(modes[after_id] & bga_mode.MOVIE){
        start_movie(movies[after_id], time);
      }
    }
  }else{
    if(modes[after_id] & bga_mode.TRIMMING){
      if(modes[trimmings[after_id].number] & bga_mode.MOVIE){
        start_movie(movies[trimmings[after_id].number], time);
      }
    }else{
      if(modes[after_id] & bga_mode.MOVIE){
        start_movie(movies[after_id], time);
      }
    }
  }
}

/**
 *
 */
bool movie_playing(ref Moviedata[size_t] movies){
  foreach(Moviedata movie; movies){
    if(movie.playing){
      return true;
    }
  }
  return false;
}

/**
 *
*/
void start_movie(ref Moviedata movie, fractionL time){
  //
  movie.playing = true;
  av_seek_frame(movie.format, -1, 0, AVSEEK_FLAG_BACKWARD);
  movie.count = time;
}

/**
 *
*/
void stop_movie(ref Moviedata movie){
  //
  movie.playing = false;
  movie.start = false;
}

/**
 *
*/
Moviedata load_movie(string str){
  Moviedata result;
  uint ret;
  //
  result.format = avformat_alloc_context();
  ret = avformat_open_input(&result.format, cast(char*)(str.toStringz), null, null);
  result.format.flags |= AVFMT_FLAG_NONBLOCK;
  //
  ret = avformat_find_stream_info(result.format, null);
  //
  for(auto i = 0; i < result.format.nb_streams; i++){
    if(result.format.streams[i].codec.codec_type == AVMediaType.AVMEDIA_TYPE_VIDEO){
      result.context = result.format.streams[i].codec;
      result.index = i;
      break;
    }
  }
  result.codec = avcodec_find_decoder(result.context.codec_id);
  ret = avcodec_open2(result.context, result.codec, null);
  //result.context.flags |= CODEC_FLAG_EMU_EDGE;
  //
  result.stream = result.format.streams[result.index];
  //
  result.picture = av_frame_alloc();
  result.picture.width  = result.context.width;
  result.picture.height = result.context.height;
  //
  result.dest = av_frame_alloc();
  result.dest.width  = result.context.width;
  result.dest.height = result.context.height;
  result.swscale = sws_getContext(result.picture.width, result.picture.height, result.context.pix_fmt,
                                  result.picture.width, result.picture.height,
                                  AVPixelFormat.AV_PIX_FMT_RGB24, SWS_BILINEAR, null, null, null);
  ret = av_image_alloc(cast(ubyte*[4])result.dest.data[0..4], cast(int[4])result.dest.linesize[0..4], result.picture.width, result.picture.height, AVPixelFormat.AV_PIX_FMT_RGB24, 32);
  //
  ret = avcodec_open2(result.context, result.codec, null);
  ret = avio_open(&result.format.pb, result.format.filename.ptr, AVIO_FLAG_READ);
  ret = av_image_alloc(cast(ubyte*[4])result.picture.data[0..4], cast(int[4])result.picture.linesize[0..4], result.context.width, result.context.height, result.context.pix_fmt, 32);
  //
  return result;
}

/**
 *
*/
void load_frame(ref Moviedata movie){
  int got_output;
  uint ret;
  //
  load:
  do{
    for(size_t i = 0;; i += 1){
      av_init_packet(&packet);
      ret = av_read_frame(movie.format, &packet);
      if(packet.stream_index == movie.index){
        ret = avcodec_decode_video2(movie.context, movie.picture, &got_output, &packet);
        if(got_output){
          if(!movie.start){
            movie.start = true;
            movie.time = movie.count - fractionL(packet.dts * 1_000_000L, 1) * cast(fractionI)movie.stream.time_base;
          }
          ret = sws_scale(movie.swscale, movie.picture.data.ptr, movie.picture.linesize.ptr, 0, movie.picture.height, movie.dest.data.ptr, movie.dest.linesize.ptr);
        }
        if(packet.size == 0){
          movie.playing = false;
          movie.start = false;
          break load;
        }
        break;
      }
      av_free_packet(&packet);
    }
  }while(!movie.start);
  movie.count = movie.time + fractionL(packet.dts * 1_000_000L, 1) * cast(fractionI)movie.stream.time_base;
}

/**
 *
*/
void delete_movies(ref Moviedata[size_t] movies){
  foreach(ref Moviedata movie; movies){
    sws_freeContext(movie.swscale);
    avcodec_close(movie.context);
    avio_close(movie.format.pb);
    av_frame_free(&movie.picture);
    av_frame_free(&movie.dest);
  }
}

/**
 *
*/
void get_movie_size(ref BMS_data b, ref EncodeData option, ref ImageBitmap[] images, ref Moviedata[size_t] movies, ref bga_mode[] modes){
  foreach(ref int_delta background; b.background_list){
    if(background.type == Object_type.BGA_BASE ||
       background.type == Object_type.BGA_LAYER1 ||
       background.type == Object_type.BGA_LAYER2 ||
       background.type == Object_type.BGA_POOR){
      if(modes[background.value] & bga_mode.TRIMMING){
        if(b.bga_list[background.value].number & ~bga_mode.TRIMMING){
          if(b.bga_list[background.value].dx < 128){
            if(option.bgawidth < (128 - b.bga_list[background.value].dx) * 2){
               option.bgawidth = (128 - b.bga_list[background.value].dx) * 2;
            }
          }
          if(b.bga_list[background.value].dx + (b.bga_list[background.value].xend - b.bga_list[background.value].xstart) >= 128){
            if(option.bgawidth < b.bga_list[background.value].dx + (b.bga_list[background.value].xend - b.bga_list[background.value].xstart) * 2 - 256){
               option.bgawidth = b.bga_list[background.value].dx + (b.bga_list[background.value].xend - b.bga_list[background.value].xstart) * 2 - 256;
            }
          }
          if(b.bga_list[background.value].dy < 0){
            if(option.top < -b.bga_list[background.value].dy){
               option.top = -b.bga_list[background.value].dy;
            }
          }
          if(option.bgaheight < b.bga_list[background.value].dy + (b.bga_list[background.value].yend - b.bga_list[background.value].ystart)){
             option.bgaheight = b.bga_list[background.value].dy + (b.bga_list[background.value].yend - b.bga_list[background.value].ystart);
          }
        }
      }else if(modes[background.value] == bga_mode.MOVIE){
        if(option.bgawidth < movies[background.value].picture.width){
          option.bgawidth = movies[background.value].picture.width;
        }
        if(option.bgaheight < movies[background.value].picture.height){
          option.bgaheight = movies[background.value].picture.height;
        }
      }else if(modes[background.value] == bga_mode.IMAGE){
        if(option.bgawidth < images[background.value].width){
          option.bgawidth = images[background.value].width;
        }
        if(option.bgaheight < images[background.value].height){
          option.bgaheight = images[background.value].height;
        }
      }
    }
  }
}

int main(string[] agev){
  EncodeData option;
  BMS_data b;
  ImageBitmap[] images;
  bga_mode[] modes;
  AudioData audio;
  Moviedata[size_t] movies;
  images.length = 36 * 36;
  modes.length = 36 * 36;
  //
  if(agev.length > 1 && agev[1] == "--help"){
    writeln("BGAEncAdvance");
    writeln("Usage:");
    writeln("BGAEncAdv [option] infile outfile\n");
    writeln("-i[file] choose infile");
    writeln("-o[file] choose outfile");
    writeln("-a[file] choose audiofile");
    writeln("-f[rate] set framerate(default=30, Max=360)");
    writeln("-w[size] set width(default=auto, max=65536)");
    writeln("-h[size] set height(default=auto, max=65536)");
    writeln("-t[size] set top margin(default=0)");
    writeln("-l[size] set layer mode");
    writeln("  0          Misslayer only");
    writeln("  1          Show all layer");
    writeln("  2(default) Standard");
    writeln("-help    print help");
  }else{
    if(agev.length == 1 || (agev.length == 2 && agev[1][0] != '-')){
      option = write_parameter(agev);
    }else{
      option = load_parameter(agev[1..$]);
    }
    //
    if(option.outfile.length == 0){
      option.outfile = dirName(agev[0]) ~ "/out.avi";
    }
    if(exists(option.infile)){
      b = load_BMS(option.infile);
      //
      av_register_all();
      //
      load_images(b, option, images, movies, modes);
      //
      if(option.audiofile != ""){
        audio = load_audio(option.audiofile);
      }
      //
      if(option.width == 0 || option.height == 0){
        get_movie_size(b, option, images, movies, modes);
        if(option.width == 0){
          if(option.bgawidth > 0){
            option.width = option.bgawidth;
          }
        }
        if(option.height == 0){
          if(option.bgaheight > 0){
            option.height = option.bgaheight + option.top;
          }
        }
      }
      if(option.width < 16){
        option.width = 16;
      }else if(option.width > 65536){
        option.width = 65536;
      }
      if(option.height < 16){
        option.height = 16;
      }else if(option.height > 65536){
        option.height = 65536;
      }
      if(option.top > (65536 - option.height) / 2){
        option.top = (65536 - option.height) / 2;
      }
      if(option.framerate > 360){
        option.framerate = 360;
      }
      //
      if(option.audiofile != ""){
        option.min_frames = (audio.time * option.framerate).decimal - 1;
      }else{
        option.min_frames = 0;
      }
      //
      GC.collect();
      save_frame(b, images, movies, audio, option, modes);
      //
      delete_movies(movies);
    }else{
      stderr.writefln("%s is not found.", convert!(Charset.DEFAULT)(option.infile, Charset.UTF8));
    }
  }
  //
  return 0;
}
