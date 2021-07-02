module loader.loadS;

import std.string;
import std.uni;
import std.stdio;
import std.traits;

import util.fraction;
import util.code;
import util.toint;

import loader.data;
import loader.error;

version(WIDE){}
else{
  immutable Charset CONVERTCODE = Charset.UTF8;
  alias cchar = char;
  alias cstring = string;

  package:
  /*
   * 制御文以外の構文を読み取る
  */
  void load(uint mode, ref cchar[][] lines, BMS_data bms, ref BMS_temp bmstemp){
    if(mode == 1 || mode == 2){
      switch(lines[0].modeConvert(ConvertType.UPPER)){
      //
      case "PLAYER":
        if(lines[1].isDigit()){
          if(bms.playstyle < playstyle.NINESP){
            if(lines[1].toDigit() >= 2){
              bms.playstyle = playstyle.TEN;
            }else{
              bms.playstyle = playstyle.FIVE;
            }
          }
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      case "RANK":
        if(lines[1].isFraction()){
          bms.rank = lines[1].toFraction!(int, typeof(lines[1])) * 25 + 50;
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      case "DEFEXRANK":
        if(lines[1].isFraction()){
          bms.rank = lines[1].toFraction!(int, typeof(lines[1]));
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      case "TOTAL":
        if(lines[1].isFraction()){
          bms.total = lines[1].toFraction!(long, typeof(lines[1]));
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      case "VOLWAV":
        if(lines[1].isFraction()){
          bms.volwav = lines[1].toFraction!(int, typeof(lines[1]))(true) / 100;
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      case "STAGEFILE":
        bms.stagefile = cast(string)(lines[1..$].join());
        break;
      case "BANNER":
        bms.banner = cast(string)(lines[1..$].join());
        break;
      case "BACKBMP":
        bms.backbmp = cast(string)(lines[1..$].join());
        break;
      case "PLAYLEVEL":
        bms.level = cast(string)(lines[1..$].join());
        break;
      case "DIFFICULTY":
        if(lines[1].isDigit()){
          bms.difficulty = lines[1].toDigit(true);
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      case "TITLE":
        bms.title = cast(string)(lines[1..$].join());
        break;
      case "SUBTITLE":
        bms.subtitle = cast(string)(lines[1..$].join());
        break;
      case "ARTIST":
        bms.artist = cast(string)(lines[1..$].join());
        break;
      case "SUBARTIST":
        bms.subartist.length += 1;
        bms.subartist[$-1] = cast(string)(lines[1..$].join());
        break;
      case "MAKER":
        bms.maker = cast(string)(lines[1..$].join());
        break;
      case "GENLE":
        stderr.writeln("Misstype command, use \"GENRE\".");
        bms.genre = cast(string)(lines[1..$].join());
        break;
      case "GENRE":
        bms.genre = cast(string)(lines[1..$].join());
        break;
      case "COMMENT":
        if(lines[1][0] == '"'){
          lines[1] = lines[1][1..$];
        }
        if(lines[$-1][$-1] == '"'){
          lines[$-1].length -= 1;
        }
        bms.comment = cast(string)(lines[1..$].join());
        break;
      case "PATH_WAV":
        bms.path = cast(string)(lines[1..$].join());
        break;
      case "CHARFILE":
        // 後で
        break;
      case "BPM":
        if(lines[1].isFraction()){
          bms.startBPM = lines[1].toFraction!(int, typeof(lines[1]));
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      case "BASEBPM":
        if(lines[1].isFraction()){
          bms.baseBPM = lines[1].toFraction!(int, typeof(lines[1]));
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      case "LNOBJ":
        bmstemp.LNobject.length += 1;
        bmstemp.LNobject[$-1] = lines[1].toDecimal();
        break;
      case "OCT/FP":
        bmstemp.oct_fp = true;
        break;
      case "OPTION":
        // まだ
        break;
      case "WAVCMD":
        // まだ
        break;
      case "POORBGA":
        if(lines[1].isDigit()){
          bms.poor_overray = (lines[1].toDigit(true) > 0);
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      default:
        load_XX(lines, bms, bmstemp);
        break;
      }
      //
    }else if(mode == 3){
      uint linum;
      uint type;
      cchar[2] buf;
      bool odd;
      if(lines[0].length > 2){
        linum = lines[0][0..$-2].toDigit();
        type = lines[0][$-2..$].toDecimal();
      }else if(lines[0].length == 2){
        linum = lines[0][0..1].toDigit();
        type = lines[0][1..$].toDecimal();
      }
      if(type == Object_type.BAR){
        if(lines[1].isFraction()){
          bmstemp.meter_list[linum] = lines[1].toFraction!(long, typeof(lines[1]));
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
      }else{
        uint i;
        foreach(c; lines[1]){
          if((c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')){
            if(odd){
              buf[1] = c;
              if(bmstemp.line_list[linum].length == 0){
                bmstemp.line_list[linum].length = 16;
              }
              if(bmstemp.line_list[linum].length <= bmstemp.list_size[linum]){
                bmstemp.line_list[linum].length *= 2;
              }
              if(bmstemp.line_list[linum][bmstemp.list_size[linum]].line.length == 0){
                bmstemp.line_list[linum][bmstemp.list_size[linum]].type = type;
                bmstemp.line_list[linum][bmstemp.list_size[linum]].line.length = 16;
              }else if(bmstemp.line_list[linum][bmstemp.list_size[linum]].line.length <= i){
                bmstemp.line_list[linum][bmstemp.list_size[linum]].line.length *= 2;
              }
              if(type == Object_type.BPM ||
                 type == Object_type.ALPHA_BASE ||
                 type == Object_type.ALPHA_LAYER1 ||
                 type == Object_type.ALPHA_LAYER2 ||
                 type == Object_type.ALPHA_POOR){
                bmstemp.line_list[linum][bmstemp.list_size[linum]].line[i] = toHex(buf);
              }else{
                bmstemp.line_list[linum][bmstemp.list_size[linum]].line[i] = toDecimal(buf);
              }
              i += 1;
            }else{
              buf[0] = c;
            }
            odd ^= true;
          }
        }
        if(odd){
          stderr.writefln("Sequence is odd.");
        }
        if(bmstemp.line_list[linum].length > 0 && i > 0){
          bmstemp.line_list[linum][bmstemp.list_size[linum]].line.length = i;
          bmstemp.list_size[linum] += 1;
        }
      }
    }
  }

  /*
   *
  */
  void load_XX(ref cchar[][] lines, BMS_data bms, ref BMS_temp bmstemp){
    uint num;
    if(lines[0].modeIndex("WAV", CaseSensitive.no) == 0){
      if(lines[0][("WAV".length)..$].isDecimal()){
        num = lines[0][("WAV".length)..$].toDecimal();
        bms.wav_list[num] = cast(string)(lines[1..$].join());
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0]))); 
      }
    }else if(lines[0].modeIndex("EXWAV", CaseSensitive.no) == 0){
      // まだ
    }else if(lines[0].modeIndex("BMP", CaseSensitive.no) == 0){
      if(lines[0][("BMP".length)..$].isDecimal()){
        num = lines[0][("BMP".length)..$].toDecimal();
        bms.bmp_list[num] = cast(string)(lines[1..$].join());
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0]))); 
      }
    }else if(lines[0].modeIndex("EXBMP", CaseSensitive.no) == 0){
      // まだ
    }else if(lines[0].modeIndex("BGA", CaseSensitive.no) == 0){
      uint i = 0;
      if(lines[0][("BGA".length)..$].isDecimal()){
        num = lines[0][("BGA".length)..$].toDecimal();
        bms.bga_list[num].using = true;
        if(lines[1].isDecimal()){
          bms.bga_list[num].values[0] = lines[1].toDecimal();
          foreach(j; 2..(lines.length)){
            if(isWhite(lines[j][0]) || lines[j][0] == ','){
              if(!isWhite(lines[j-1][0]) && lines[j-1][0] != ','){
                i += 1;
              }
              if(i > 6){
                break;
              }
            }else if(lines[j].isDigit() == true){
              bms.bga_list[num].values[i] = lines[j].toDigit();
            }else{
              throw(new LoadException(format("%s is invalid value.", lines[j])));
            }
          }
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1]))); 
        }
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0]))); 
      }
    }else if(lines[0].modeIndex("@BGA", CaseSensitive.no) == 0){
      uint i = 0;
      if(lines[0][("@BGA".length)..$].isDecimal()){
        num = lines[0][("@BGA".length)..$].toDecimal();
        bms.bga_list[num].using = true;
        if(lines[1].isDecimal()){
          bms.bga_list[num].values[0] = lines[1].toDecimal();
          foreach(j; 1..(lines.length)){
            if(isWhite(lines[j][0]) || (!isWhite(lines[j-1][0]) &&  lines[j-1][0] != ',')){
              if(!isWhite(lines[j-1][0]) && lines[j-1][0] != ','){
                i += 1;
              }
              if(i > 6){
                break;
              }
            }else if(lines[j].isDigit() == true){
              bms.bga_list[num].values[i] = lines[j].toDigit();
            }else{
              throw(new LoadException(format("%s is invalid value.", lines[j])));
            }
          }
          bms.bga_list[num].xend += bms.bga_list[num].xstart;
          bms.bga_list[num].yend += bms.bga_list[num].ystart;
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1]))); 
        }
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0]))); 
      }
    }else if(lines[0].modeIndex("SWBGA", CaseSensitive.no) == 0){
      // まだ
    }else if(lines[0].modeIndex("ARGB", CaseSensitive.no) == 0){
      uint i = 0;
      if(lines[0][("ARGB".length)..$].isDecimal()){
        num = lines[0][("ARGB".length)..$].toDecimal();
        bmstemp.argb_list[num] = argb();
        bmstemp.argb_list[num].values[] = 0xFF;
        foreach(j; 1..(lines.length)){
          if(isWhite(lines[j][0]) || lines[j][0] == ','){
            if(!isWhite(lines[j-1][0]) && lines[j-1][0] != ','){
              i += 1;
            }
            if(i > 4){
              break;
            }
          }else if(lines[j].isDigit() == true){
            bmstemp.argb_list[num].values[i] = cast(ubyte)lines[j].toDigit();
          }else{
            bmstemp.argb_list.remove(num);
            throw(new LoadException(format("%s is invalid value.", lines[j])));
          }
        }
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0]))); 
      }
    }else if(lines[0].modeIndex("BPM", CaseSensitive.no) == 0){
      num = lines[0][("BPM".length)..$].toDecimal();
      bmstemp.BPM_list[num] = lines[1].toFraction!(int, typeof(lines[1]));
    }else if(lines[0].modeIndex("EXBPM", CaseSensitive.no) == 0){
      stderr.writeln("Obsolete command, use \"BPM\".");
      num = lines[0][("EXBPM".length)..$].toDecimal();
      if(lines[1].isFraction()){
        bmstemp.BPM_list[num] = lines[1].toFraction!(int, typeof(lines[1]));
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0])));
      }
    }else if(lines[0].modeIndex("STOP", CaseSensitive.no) == 0){
      if(lines[0][("STOP".length)..$].isDecimal()){
        num = lines[0][("STOP".length)..$].toDecimal();
        if(lines[1].isFraction()){
          bmstemp.stop_list[num] = lines[1].toFraction!(int, typeof(lines[1]))(true) / 192;
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0])));
      }
    }else if(lines[0].modeIndex("EXRANK", CaseSensitive.no) == 0){
      if(lines[0][("EXRANK".length)..$].isDecimal()){
        num = lines[0][("EXRANK".length)..$].toDecimal();
        if(lines[1].isFraction()){
          bmstemp.rank_list[num] = lines[1].toFraction!(int, typeof(lines[1]));
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0])));
      }
    }else if(lines[0].modeIndex("TEXT", CaseSensitive.no) == 0){
      if(lines[0][("TEXT".length)..$].isDecimal()){
        num = lines[0][("TEXT".length)..$].toDecimal();
       bmstemp.text_list[num] = cast(string)(lines[1..$].join());
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0])));
      }
    }else if(lines[0].modeIndex("SONG", CaseSensitive.no) == 0){
      stderr.writeln("Obsolete command, use \"TEXT\".");
      if(lines[0][("SONG".length)..$].isDecimal()){
        num = lines[0][("SONG".length)..$].toDecimal();
        bmstemp.text_list[num] = cast(string)(lines[1..$].join());
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0])));
      }
    }else if(lines[0].modeIndex("CHANGEOPTION", CaseSensitive.no) == 0){
      // 網羅がめんどい
    }
  }
}