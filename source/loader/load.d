module loader.load;

import core.exception;
import std.algorithm;
import std.bigint;
import std.conv;
import std.path;
import std.random;
import std.stdio;
import std.string;
import std.traits;
import std.uni;
import std.utf;

import util.fraction;
import util.array;
import util.code;
import util.math;
import util.toint;

import loader.data;
import loader.error;
import loader.charfile;

alias std.string.join join;
alias std.string.CaseSensitive CaseSensitive;

private{
  version(WIDE){
    version(LittleEndian){
      immutable Charset CONVERTCODE = Charset.UTF16LE;
    }
    version(BigEndian){
      immutable Charset CONVERTCODE = Charset.UTF16BE;
    }
    alias cchar = wchar;
    alias cstring = wstring;
  }else{
    immutable Charset CONVERTCODE = Charset.UTF8;
    alias cchar = char;
    alias cstring = string;
  }

  string SUBTITLE_START = "-~([<\"";
  string SUBTITLE_END = "-~)]>\"";

  string[] DIFFICULTY_EASY = ["Easy", "Beginner", "Light", "Simple", "5Button", "[B]", "(B)"];
  string[] DIFFICULTY_NORMAL = ["Normal", "Standard", "[N]", "(N)"];
  string[] DIFFICULTY_HARD = ["Hyper", "Hard", "Extend", "[H]", "(H)"];
  string[] DIFFICULTY_MANIAC = ["Maniac", "Extra", "EX"];
  string[] DIFFICULTY_INSANE = ["Insane", "Another", "Plus", "[A]", "(A)"];

  string[] ENCODE = ["ASCII", "SHIFT-JIS", "UHC", "UTF-8", "UTF-16LE", "UTF-16BE", "UTF-32LE", "UTF-32BE"];
}

/**
 * 
*/
BMS_data load_BMS(string fname){
  BMS_data bms;
  BMS_temp bmstemp;
  bool nestmode;
  //
  bms = new BMS_data();
  bmstemp.charset = getEncode(fname);
  //
  writefln("ENCODE: %s", ENCODE[bmstemp.charset]);
  nestmode = get_nestmode(fname, bmstemp.charset);
  //
  bmstemp.LNobject.length = 4;
  bmstemp.LNobject.length = 0;
  bms.subartist.length = 4;
  bms.subartist.length = 0;
  //
  if(fname.extension() == ".pms"){
    bms.playstyle = playstyle.NINESP;
  }
  road_command(fname, nestmode, bms, bmstemp);
  //
  create_timeline(bms, bmstemp);
  //
  return bms;
}

private{
  /*
   *
  */
  void road_command(string fname, bool nestmode, BMS_data bms, ref BMS_temp bmstemp){
    uint mode;
    uint linum;
    File f;
    //
    int[] random;
    int[] switch_random;
    int[] switch_bottom;
    uint random_point = 0;
    int switch_point = -1;
    int skip_point = 0;
    bool[] skip;
    bool[] block_skip;
    bool defskip = false;
    //
    cchar[][] lines;
    //
    random.length = 8;
    skip.length = 8;
    block_skip.length = 8;
    switch_random.length = 8;
    switch_bottom.length = 8;
    random[] = 1;
    skip[0] = false;
    skip[1..$] = true;
    block_skip[] = false;
    switch_random[] = 1;
    switch_bottom[] = 0;
    //
    f = File(fname, ACCESSIBLE.READ);
    while(!f.eof){
      linum += 1;
      if(get_size(bmstemp.charset) == 1){
        char[] temp;
        f.readln(temp);
        mode = read_line(convert!(CONVERTCODE)(replace_vaild(temp, bmstemp.charset), bmstemp.charset), lines);
      }else if(get_size(bmstemp.charset) == 2){
        throw new ReadException("Sorry, \"readLineW\" is not exist.");
      }else if(get_size(bmstemp.charset) == 4){
        throw new ReadException("Sorry, \"readLineD\" is not exist.");
      }
      try{
        if(lines[0].modeIndex("SETRONDAM", CaseSensitive.no) == 0){
          stderr.writefln("FILE:%s line: %d", fname, linum);
          stderr.writeln("Misstype command, use \"RANDOM\".");
          if(skip[skip_point] == false){
            if(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) == "SETRONDAM"){
              if(lines[1].isDigit()){
                random[random_point] = lines[1].toDigit();
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[1])));
              }
            }else{
              if(lines[0][("SETRONDAM".length)..$].isDigit()){
                random[random_point] = lines[0][("SETRONDAM".length)..$].toDigit();
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[0][("SETRONDAM".length)..$])));
              }
            }
          }
        //
        }else if(lines[0].modeIndex("SETRANDOM", CaseSensitive.no) == 0){
          if(skip[skip_point] == false){
            if(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) == "SETRANDOM"){
              if(lines[1].isDigit()){
                random[random_point] = lines[1].toDigit();
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[1])));
              }
            }else{
              if(lines[0][("SETRANDOM".length)..$].isDigit()){
                random[random_point] = lines[0][("SETRANDOM".length)..$].toDigit();
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[0][("SETRANDOM".length)..$])));
              }
            }
          }
        //
        }else if(lines[0].modeIndex("RONDAM", CaseSensitive.no) == 0){
          stderr.writefln("FILE:%s line: %d", fname, linum);
          stderr.writeln("Misstype command, use \"RANDOM\".");
          if(skip[skip_point] == false){
            if(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) == "RONDAM"){
              if(lines[1].isDigit()){
                random[random_point] = uniform(0, lines[1].toDigit()) + 1;
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[1])));
              }
            }else{
              if(lines[0][("RONDAM".length)..$].isDigit()){
                random[random_point] = uniform(0, lines[0][("RONDAM".length)..$].toDigit()) + 1;
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[0][("RONDAM".length)..$])));
              }
            }
          }
        //
        }else if(lines[0].modeIndex("RANDOM", CaseSensitive.no) == 0){
          if(skip[skip_point] == false){
            if(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) == "RANDOM"){
              if(lines[1].isDigit()){
                random[random_point] = uniform(0, lines[1].toDigit()) + 1;
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[1])));
              }
            }else{
              if(lines[0][("RANDOM".length)..$].isDigit()){
                random[random_point] = uniform(0, lines[0][("RANDOM".length)..$].toDigit()) + 1;
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[0][("RANDOM".length)..$])));
              }
            }
          }
        //
        }else if(lines[0].modeIndex("ENDIF", CaseSensitive.no) == 0 || lines[0].modeIndex("IFEND", CaseSensitive.no) == 0){
          if(lines[0].modeIndex("IFEND", CaseSensitive.no) == 0){
            stderr.writefln("FILE:%s line: %d", fname, linum);
            stderr.writeln("Misstype command, use \"ENDIF\".");
          }
          if(switch_point < 0 || random_point > switch_bottom[switch_point]){
            random[random_point] = 1;
            skip[skip_point] = true;
            block_skip[skip_point] = false;
            if(nestmode == true){
              random_point -= 1;
              skip_point -= 1;
            }else{
              random_point = 0;
              skip_point = 0;
            }
          }else{
            throw(new LoadException("No stack."));
          }
        //
        }else if(lines[0].modeIndex("END", CaseSensitive.no) == 0){
          if(lines.length >= 2 && lines[1].modeConvert(ConvertType.UPPER | ConvertType.EN) == "IF"){
            stderr.writefln("FILE:%s line: %d", fname, linum);
            stderr.writeln("Misstype command, use \"ENDIF\".");
            if(switch_point < 0 || random_point > switch_bottom[switch_point]){
              random[random_point] = 1;
              skip[skip_point] = true;
              block_skip[skip_point] = false;
              if(nestmode == true){
                random_point -= 1;
                skip_point -= 1;
              }else{
                random_point = 0;
                skip_point = 0;
              }
            }else{
              throw(new LoadException("No stack."));
            }
          }
        //
        }else if(lines[0].modeIndex("ELSEIF", CaseSensitive.no) == 0){
          if(random_point > 0 && skip[skip_point-1] == false){
            if(block_skip[skip_point] == false){
              if(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) == "ELSEIF"){
                if(lines[1].isDigit()){
                  if(skip[skip_point] == false && (random[random_point-1] != lines[1].toDigit())){
                    block_skip[skip_point] = true;
                  }
                  skip[skip_point] = (random[random_point-1] != lines[1].toDigit());
                }else{
                  throw(new LoadException(format("%s is invalid value.", lines[1])));
                }
              }else{
                if(lines[0][("ELSEIF".length)..$].isDigit()){
                  if(skip[skip_point] == false && (random[random_point-1] != lines[0][("ELSEIF".length)..$].toDigit())){
                    block_skip[skip_point] = true;
                  }
                  skip[skip_point] = (random[random_point-1] != lines[0][("ELSEIF".length)..$].toDigit());
                }else{
                  throw(new LoadException(format("%s is invalid value.", lines[0][("ELSEIF".length)..$])));
                }
              }
            }else if(defskip == true){
              writefln("%s is never selected.", lines.join());
            }
          }else{
            throw(new LoadException("No stack."));
          }
        //
        }else if(lines[0].modeIndex("IF", CaseSensitive.no) == 0){
          if(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) == "IF"){
            if(lines[1].isDigit()){
              if(nestmode == true){
                random_point += 1;
                skip_point += 1;
              }else{
                random_point = 1;
                skip_point = 1;
              }
              if(random_point >= random.length){
                random.length *= 2;
                random[random_point..$] = 1;
              }
              if(skip_point >= skip.length){
                skip.length *= 2;
                block_skip.length *= 2;
                skip[skip_point..$] = true;
                block_skip[skip_point..$] = false;
              }
              if(skip[skip_point-1] == false){
                skip[skip_point] = (random[random_point-1] != lines[1].toDigit());
              }
            }else{
              throw(new LoadException(format("%s is invalid value.", lines[1])));
            }
          }else{
            if(lines[0][("IF".length)..$].isDigit()){
              if(nestmode == true){
                random_point += 1;
                skip_point += 1;
              }else{
                random_point = 1;
                skip_point = 1;
              }
              if(random_point >= random.length){
                random.length *= 2;
                random[random_point..$] = 1;
              }
              if(skip_point >= skip.length){
                skip.length *= 2;
                block_skip.length *= 2;
                skip[skip_point..$] = true;
                block_skip[skip_point..$] = false;
              }
              if(skip[skip_point-1] == false){
                skip[skip_point] = (random[random_point-1] != lines[0][("IF".length)..$].toDigit());
              }
            }else{
              throw(new LoadException(format("%s is invalid value.", lines[0][("IF".length)..$])));
            }
          }
        //
        }else if(lines[0].modeIndex("ELSE", CaseSensitive.no) == 0){
          if(random_point > 0 && skip[skip_point-1] == false){
            if(lines[1].modeIndex("IF", CaseSensitive.no) == 0){
              stderr.writefln("FILE:%s line: %d", fname, linum);
              writeln("Misstype command, use \"ELSEIF\".");
              if(block_skip[skip_point] == false){
                if(lines.length > 2){
                  if(lines[2].isDigit()){
                    if(skip[skip_point] == false && (random[random_point-1] != lines[2].toDigit())){
                      block_skip[skip_point] = true;
                    }
                    skip[skip_point] = (random[random_point-1] != lines[2].toDigit());
                  }else{
                    throw(new LoadException(format("%s is invalid value.", lines[2])));
                  }
                }else{
                  if(lines[1].modeConvert(ConvertType.UPPER | ConvertType.EN) == "IF"){
                    throw(new LoadException(format("%s is invalid value.", lines[1][("IF".length)..$])));
                  }else{
                    if(lines[1].isDigit()){
                      if(skip[skip_point] == false && (random[random_point-1] != lines[1][("IF".length)..$].toDigit())){
                        block_skip[skip_point] = true;
                      }
                      skip[skip_point] = (random[random_point-1] != lines[1][("IF".length)..$].toDigit());
                    }else{
                      throw(new LoadException(format("%s is invalid value.", lines[1][("IF".length)..$])));
                    }
                  }
                }
              }else if(defskip == true){
                stderr.writefln("FILE:%s line: %d", fname, linum);
                writefln("%s is never selected.", lines.join());
              }
            }else{
              if(block_skip[skip_point] == false){
                skip[skip_point] ^= true;
                if(skip[skip_point] == true){
                  block_skip[skip_point] = true;
                }
                defskip = true;
              }else if(defskip == true){
                stderr.writefln("FILE:%s line: %d", fname, linum);
                writefln("%s is never selected.", lines.join());
              }
            }
          }else{
            throw(new LoadException("No stack."));
          }
        //
        }else if(lines[0].modeIndex("SWITCH", CaseSensitive.no) == 0){
          if(skip[skip_point] == false){
            if(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) != "SWITCH"){
              if(lines[1].isDigit()){
                switch_point += 1;
                skip_point += 1;
                if(switch_point >= switch_random.length){
                  switch_random.length *= 2;
                  switch_bottom.length *= 2;
                  switch_random[switch_point..$] = 1;
                  switch_bottom[switch_point..$] = 0;
                }
                if(skip_point >= skip.length){
                  skip.length *= 2;
                  block_skip.length *= 2;
                  skip[skip_point..$] = true;
                  block_skip[skip_point..$] = false;
                }
                switch_random[switch_point] = uniform(0, lines[1].toDigit()) + 1;
                switch_bottom[switch_point] = random_point;
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[1])));
              }
            }else{
              if(lines[0][("SWITCH".length)..$].isDigit()){
                switch_point += 1;
                skip_point += 1;
                if(switch_point >= switch_random.length){
                  switch_random.length *= 2;
                  switch_bottom.length *= 2;
                  switch_random[switch_point..$] = 1;
                  switch_bottom[switch_point..$] = 0;
                }
                if(skip_point >= skip.length){
                  skip.length *= 2;
                  block_skip.length *= 2;
                  skip[skip_point..$] = true;
                  block_skip[skip_point..$] = false;
                }
                switch_random[switch_point] = uniform(0, lines[0][("SWITCH".length)..$].toDigit()) + 1;
                switch_bottom[switch_point] = random_point;
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[0][("SWITCH".length)..$])));
              }
            }
          }
        }else if(lines[0].modeIndex("SETSWITCH", CaseSensitive.no) == 0){
          if(skip[skip_point] == false){
            if(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) != "SETSWITCH"){
              if(lines[1].isDigit()){
                switch_point += 1;
                skip_point += 1;
                if(switch_point >= switch_random.length){
                  switch_random.length *= 2;
                  switch_bottom.length *= 2;
                  switch_random[switch_point..$] = 1;
                  switch_bottom[switch_point..$] = 0;
                }
                if(skip_point >= skip.length){
                  skip.length *= 2;
                  skip[skip_point..$] = true;
                }
                switch_random[switch_point] = lines[1].toDigit();
                switch_bottom[switch_point] = random_point;
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[1])));
              }
            }else{
              if(lines[0][("SETSWITCH".length)..$].isDigit()){
                switch_point += 1;
                skip_point += 1;
                if(switch_point >= switch_random.length){
                  switch_random.length *= 2;
                  switch_bottom.length *= 2;
                  switch_random[switch_point..$] = 1;
                  switch_bottom[switch_point..$] = 0;
                }
                if(skip_point >= skip.length){
                  skip.length *= 2;
                  skip[skip_point..$] = true;
                }
                switch_random[switch_point] = lines[0][("SETSWITCH".length)..$].toDigit();
                switch_bottom[switch_point] = random_point;
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[0][("SETSWITCH".length)..$])));
              }
            }
          }
        }else if(lines[0].modeIndex("CASE", CaseSensitive.no) == 0){
          if(block_skip[skip_point] == false){
            if(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) != "CASE"){
              if(lines[1].isDigit()){
                skip[skip_point] = (switch_random[switch_point] != lines[1].toDigit());
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[1])));
              }
            }else{
              if(lines[0][("CASE".length)..$].isDigit()){
                skip[skip_point] = (switch_random[switch_point] != lines[0][("CASE".length)..$].toDigit());
              }else{
                throw(new LoadException(format("%s is invalid value.", lines[0][("CASE".length)..$])));
              }
            }
          }else if(defskip == true){
            stderr.writefln("FILE:%s line: %d", fname, linum);
            writefln("%s is never selected.", lines.join());
          }
        }else if(lines[0].modeIndex("DEF", CaseSensitive.no) == 0 || lines[0].modeIndex("DEFAULT", CaseSensitive.no) == 0){
          if(block_skip[skip_point] == false){
            skip[skip_point] = false;
            defskip = true;
          }else if(defskip == true){
            stderr.writefln("FILE:%s line: %d", fname, linum);
            writefln("%s is never selected.", lines.join());
          }
        }else if(lines[0].modeIndex("SKIP", CaseSensitive.no) == 0){
          if(skip[skip_point] == false && block_skip[skip_point] == false){
            block_skip[skip_point] = true;
            random_point = switch_bottom[switch_point];
          }
        }else if(lines[0].modeIndex("ENDSW", CaseSensitive.no) == 0){
          if(switch_point >= 0){
            skip[skip_point] = true;
            block_skip[skip_point] = false;
            random_point = switch_bottom[switch_point];
            switch_point -= 1;
            skip_point -= 1;
          }else{
            throw(new LoadException("No stack."));
          }
        }else{
          if(skip[skip_point] == false && block_skip[skip_point] == false){
            // ここから別処理
            load(mode, lines, bms, bmstemp);
          }
        }
      }catch(UnicodeException e){
        stderr.writefln("FILE:%s line: %d\nERROR:illegal sequence.", fname, linum);
      }catch(LoadException e){
        stderr.writefln("FILE:%s line: %d\nERROR:%s", fname, linum, e.msg);
      }catch(Exception e){
        stderr.writefln("FILE:%s line: %d\nUNKNOWN ERROR.", fname, linum);
      }
      debug{
        if(mode > 0 && (lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) == "SWITCH" ||lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) == "SETSWITCH" || skip[skip_point] == false) && block_skip[skip_point] == false){
          try{
            validate(lines[0]);
            if(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN) != "IF" || random[random_point] == lines[1].toDigit()){
              writef("line%d: ", linum);
              foreach(str; lines){
                write(str);
                write(" ");
              }
              if(lines[0].modeIndex("RONDAM", CaseSensitive.no) == 0 || lines[0].modeIndex("RANDOM", CaseSensitive.no) == 0 ||
                 lines[0].modeIndex("SETRONDAM", CaseSensitive.no) == 0 || lines[0].modeIndex("SETRANDOM", CaseSensitive.no) == 0){
                writef("set(%d)", random[random_point]);
              }
              if(lines[0].modeIndex("SWITCH", CaseSensitive.no) == 0 || lines[0].modeIndex("SETSWITCH", CaseSensitive.no) == 0){
                writef("set(%d)", switch_random[switch_point]);
              }
              writeln();
            }
          }catch(Exception e){
            writef("line%d: ", linum);
            foreach(str; lines){
              write(str);
              write(" ");
            }
            writeln();
          }
        }
      }
    }
    f.close();
  }
  /*
   * 制御文以外の構文を読み取る
  */
  void load(uint mode, ref cchar[][] lines, BMS_data bms, ref BMS_temp bmstemp){
    if(mode == 1 || mode == 2){
      switch(lines[0].modeConvert(ConvertType.UPPER | ConvertType.EN)){
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
        bms.stagefile = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "BANNER":
        bms.banner = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "BACKBMP":
        bms.backbmp = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "PLAYLEVEL":
        bms.level = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "DIFFICULTY":
        if(lines[1].isDigit()){
          bms.difficulty = lines[1].toDigit(true);
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      case "TITLE":
        bms.title = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "SUBTITLE":
        bms.subtitle = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "ARTIST":
        bms.artist = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "SUBARTIST":
        bms.subartist.length += 1;
        bms.subartist[$-1] = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "MAKER":
        bms.maker = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "GENLE":
        stderr.writeln("Misstype command, use \"GENRE\".");
        bms.genre = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "GENRE":
        bms.genre = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "COMMENT":
        if(lines[1][0] == '"'){
          lines[1] = lines[1][1..$];
        }
        if(lines[$-1][$-1] == '"'){
          lines[$-1].length -= 1;
        }
        bms.comment = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "PATH_WAV":
        bms.path = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
        break;
      case "CHARFILE":
        // 後で
        break;
      case "BPM":
        if(lines[1].isFraction() && lines[1].toFraction!(int, typeof(lines[1])) > 0){
          bms.startBPM = lines[1].toFraction!(int, typeof(lines[1]));
        }else{
          throw(new LoadException(format("%s is invalid value.", lines[1])));
        }
        break;
      case "BASEBPM":
        if(lines[1].isFraction() && lines[1].toFraction!(int, typeof(lines[1])) > 0){
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
        uint j;
        uint i;
        foreach(c; lines[1]){
          if((c.toEN >= '0' && c.toEN <= '9') || (c.toEN >= 'A' && c.toEN <= 'Z') || (c.toEN >= 'a' && c.toEN <= 'z')){
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
              }else if(bmstemp.line_list[linum][bmstemp.list_size[linum]].line.length <= j){
                bmstemp.line_list[linum][bmstemp.list_size[linum]].line.length *= 2;
              }
              if(type == Object_type.BPM ||
                 type == Object_type.ALPHA_BASE ||
                 type == Object_type.ALPHA_LAYER1 ||
                 type == Object_type.ALPHA_LAYER2 ||
                 type == Object_type.ALPHA_POOR){
                bmstemp.line_list[linum][bmstemp.list_size[linum]].line[j] = toHex(buf);
              }else{
                bmstemp.line_list[linum][bmstemp.list_size[linum]].line[j] = toDecimal(buf);
              }
              j += 1;
            }else{
              buf[0] = c;
            }
            odd ^= true;
          }
        }
        if(odd){
          stderr.writefln("Sequence is odd.");
        }
        if(bmstemp.line_list[linum].length > 0 && j > 0){
          bmstemp.line_list[linum][bmstemp.list_size[linum]].line.length = j;
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
        bms.wav_list[num] = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0]))); 
      }
    }else if(lines[0].modeIndex("EXWAV", CaseSensitive.no) == 0){
      // まだ
    }else if(lines[0].modeIndex("BMP", CaseSensitive.no) == 0){
      if(lines[0][("BMP".length)..$].isDecimal()){
        num = lines[0][("BMP".length)..$].toDecimal();
        bms.bmp_list[num] = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
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
            if(isWhite(lines[j][0]) || lines[j][0].toEN == ','){
              if(!isWhite(lines[j-1][0]) && lines[j-1][0].toEN != ','){
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
            if(isWhite(lines[j][0]) || (!isWhite(lines[j-1][0]) &&  lines[j-1][0].toEN != ',')){
              if(!isWhite(lines[j-1][0]) && lines[j-1][0].toEN != ','){
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
          if(isWhite(lines[j][0]) || lines[j][0].toEN == ','){
            if(!isWhite(lines[j-1][0]) && lines[j-1][0].toEN != ','){
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
      if(lines[1].isFraction()){
        bmstemp.BPM_list[num] = lines[1].toFraction!(int, typeof(lines[1]));
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0])));
      }
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
       bmstemp.text_list[num] = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0])));
      }
    }else if(lines[0].modeIndex("SONG", CaseSensitive.no) == 0){
      stderr.writeln("Obsolete command, use \"TEXT\".");
      if(lines[0][("SONG".length)..$].isDecimal()){
        num = lines[0][("SONG".length)..$].toDecimal();
        bmstemp.text_list[num] = convert!(Charset.UTF8)(lines[1..$].join(), CONVERTCODE);
      }else{
        throw(new LoadException(format("%s is invalid value.", lines[0])));
      }
    }else if(lines[0].modeIndex("CHANGEOPTION", CaseSensitive.no) == 0){
      // 網羅がめんどい
    }
  }
  /*
   * 行読み込み
  */
  uint read_line(cstring line, ref cchar[][] lines){
    uint j;
    uint k;
    uint mode;
    //
    lines.length = 2;
    lines[1].length = 0;
    for(size_t i = 0; i < line.length; i += 1){
      if(mode > 0){
        if(i >= lines[j].length){
          lines[j].length *= 2;
        }
        switch(mode){
        case 1:
          if(isWhite(line[i])){
            mode += 1;
            lines[0].length = k;
            lines[1].length = 16;
            j += 1;
            k = 0;
            while(i + 1 < line.length && isWhite(line[i+1])){
              i += 1;
            }
          }else if(line[i].toEN == ':'){
            mode += 2;
            lines[0].length = k;
            lines[1].length = 32;
            j += 1;
            k = 0;
          }else{
            lines[j][k] = line[i];
            k += 1;
          }
          break;
        case 2:
          if(isWhite(line[i]) || line[i].toEN == ','){
            lines[j].length = k;
            j += 1;
            if(j >= lines.length){
              lines.length += 4;
              lines[j].length = 16;
              lines[j+1].length = 16;
              lines[j+2].length = 16;
              lines[j+3].length = 16;
            }
            lines[j][0] = line[i];
            k = 1;
          }else{
            if(isWhite(lines[j][0]) || lines[j][0].toEN == ','){
              lines[j].length = k;
              j += 1;
              if(j >= lines.length){
                lines.length += 4;
                lines[j].length = 16;
                lines[j+1].length = 16;
                lines[j+2].length = 16;
                lines[j+3].length = 16;
              }
              k = 0;
            }
            lines[j][k] = line[i];
            k += 1;
          }
          break;
        case 3:
          lines[j][k] = line[i];
          k += 1;
          break;
        default:
          break;
        }
      }else{
        if(line[i].toEN == '#'){
          lines[0].length = 16;
          mode += 1;
          k = 0;
        }
        if(line[i] == '/'){
          if(i + 1 < line.length && line[i+1] == '/'){
            break;
          }
        }
      }
    }
    lines[j].length = k;
    if(j > 0){
      lines.length = j + 1;
    }
    return mode;
  }
  /*
   * 設定
  */
  void create_timeline(BMS_data bms, ref BMS_temp bmstemp){
    fractionB bpm_LCM;
    uint stop_LCM = 1;
    BigInt gauge_LCM;
    ulong bar_bottom = 1;
    BigInt delta;
    fractionI currentBPM;
    //
    uint note_size;
    uint background_size;
    uint BPM_size;
    uint stop_size;
    uint text_size;
    uint argb_size;
    uint rank_size;
    uint bar_size;
    bool[72] LNmode = false;
    bms.note_list.length = 128;
    bms.background_list.length = 256;
    bms.BPM_list.length = 8;
    bms.stop_list.length = 8;
    bms.text_list.length = 8;
    bms.argb_list.length = 8;
    bms.rank_list.length = 8;
    bms.bar_list.length = 64;
    //
    bpm_LCM = bms.startBPM;
    gauge_LCM = 1;
    currentBPM = bms.startBPM;
    bms.maxBPM = bms.startBPM;
    bms.minBPM = bms.startBPM;
    bms.HSmaxBPM = bms.startBPM;
    bms.HSminBPM = bms.startBPM;
    // ゲージ分解能
    foreach(size_t linum; 0..1000){
      if(linum in bmstemp.meter_list){
        bar_bottom = get_LCM(bar_bottom, bmstemp.meter_list[linum].denominator);
      }
      foreach(i; 0..bmstemp.list_size[linum]){
        if(bmstemp.line_list[linum][i].type == Object_type.BPM){
          foreach(bpm; bmstemp.line_list[linum][i].line){
            if(bpm > 0){
              bpm_LCM = get_LCM(bpm_LCM, bpm);
            }
          }
        }
        if(bmstemp.line_list[linum][i].type == Object_type.EXBPM){
          foreach(bpm; bmstemp.line_list[linum][i].line){
            if(bpm > 0 && (bpm in bmstemp.BPM_list)){
              bpm_LCM = get_LCM(bpm_LCM, bmstemp.BPM_list[bpm]);
            }
          }
        }
        if(bmstemp.line_list[linum][i].type == Object_type.STOP){
          foreach(stop; bmstemp.line_list[linum][i].line){
            if(stop > 0){
              if(stop in bmstemp.stop_list){
                stop_LCM = get_LCM(stop_LCM, bmstemp.stop_list[stop].denominator);
              }
            }
          }
        }
        gauge_LCM = get_LCM(gauge_LCM, bmstemp.line_list[linum][i].line.length);
      }
    }
    if((gauge_LCM * bar_bottom) % stop_LCM != 0){
      gauge_LCM = get_LCM(gauge_LCM, stop_LCM);
    }
    fractionB temp;
    temp = bpm_LCM * gauge_LCM;
    delta = temp.numerator * temp.denominator * bar_bottom;
    // パス
    BigInt gauge_point;
    BigInt total_position;
    fractionL position;
    gauge_point = (bpm_LCM / bms.startBPM).numerator;
    position.denominator = bar_bottom;
    foreach(size_t linum; 0..1000){
      /*
       一旦ライン上に全て置き、その後補正をかける
      */
      ulong bar_length;
      BigInt gauge_length;
      uint n = 0;
      line_list[] linelist;
      if(linum in bmstemp.meter_list){
        bar_length = bar_bottom / bmstemp.meter_list[linum].denominator * bmstemp.meter_list[linum].numerator;
      }else{
        bar_length = bar_bottom;
      }
      gauge_length = bar_length * gauge_LCM;
      linelist = [];
      linelist.length = 32;
      foreach(i; 0..bmstemp.list_size[linum]){
        foreach(j; 0..bmstemp.line_list[linum][i].line.length){
          BigInt time = gauge_length * j / cast(uint)(bmstemp.line_list[linum][i].line.length);
          uint value = bmstemp.line_list[linum][i].line[j];
          if(value > 0){
            linelist[n] = line_list(bmstemp.line_list[linum][i].type, value, time);
            n += 1;
            if(linelist.length <= n){
              linelist.length *= 2;
            }
          }
        }
      }
      linelist.length = n;
      linelist.sort;
      //
      BigInt last_position;
      foreach(i; 0..linelist.length){
        total_position += (linelist[i].position - last_position) * gauge_point;
        last_position = linelist[i].position;
        switch(linelist[i].type){
        case Object_type.BGM:
          if(bms.wav_list[linelist[i].value].length > 0 && same_front(linelist, i) == false){
            ulong time;
            time = (total_position * 240_000_000 / delta).toLong;
            if(currentBPM < 0){
              time = long.max;
            }
            bms.background_list[background_size] = int_delta(Object_type.BGM, linelist[i].value, time);
            background_size += 1;
            if(bms.background_list.length <= background_size){
              bms.background_list.length *= 2;
            }
          }
          break;
        case Object_type.BGA_BASE:
        case Object_type.BGA_LAYER1:
        case Object_type.BGA_LAYER2:
        case Object_type.BGA_POOR:
          if(kaburi(linelist, i) == false){
            if(currentBPM > 0){
              bms.background_list[background_size] = int_delta(linelist[i].type, linelist[i].value, (total_position * 240_000_000 / delta).toLong);
              background_size += 1;
              if(bms.background_list.length <= background_size){
                bms.background_list.length *= 2;
              }
            }
          }
          break;
        case Object_type.ALPHA_BASE:
        case Object_type.ALPHA_LAYER1:
        case Object_type.ALPHA_LAYER2:
        case Object_type.ALPHA_POOR:
          if(kaburi(linelist, i) == false){
            if(currentBPM > 0){
              bms.background_list[argb_size] = int_delta(linelist[i].type, linelist[i].value, (total_position * 240_000_000 / delta).toLong);
              argb_size += 1;
              if(bms.argb_list.length <= argb_size){
                bms.argb_list.length *= 2;
              }
            }
          }
          break;
        case Object_type.BPM:
          if(kaburi(linelist, i) == false){
            if(currentBPM > 0){
              gauge_point = (bpm_LCM / linelist[i].value).numerator;
              currentBPM = fractionI(linelist[i].value, 1);
              bms.BPM_list[BPM_size] = fractionI_delta(Object_type.BPM,currentBPM, (total_position * 240_000_000 / delta).toLong);
              BPM_size += 1;
              if(bms.BPM_list.length <= BPM_size){
                bms.BPM_list.length *= 2;
              }
              if(currentBPM > bms.maxBPM){
                bms.maxBPM = currentBPM;
              }else if(currentBPM < bms.minBPM){
                bms.minBPM = currentBPM;
              }
            }
          }
          break;
        case Object_type.EXBPM:
          if(kaburi(linelist, i) == false){
            if(linelist[i].value in bmstemp.BPM_list){
              if(currentBPM > 0){
                gauge_point = (bpm_LCM / bmstemp.BPM_list[linelist[i].value]).numerator;
                currentBPM = bmstemp.BPM_list[linelist[i].value];
                bms.BPM_list[BPM_size] = fractionI_delta(Object_type.BPM, bmstemp.BPM_list[linelist[i].value], (total_position * 240_000_000 / delta).toLong);
                BPM_size += 1;
                if(bms.BPM_list.length <= BPM_size){
                  bms.BPM_list.length *= 2;
                }
                if(currentBPM > bms.maxBPM){
                  bms.maxBPM = currentBPM;
                }else if(currentBPM < bms.minBPM){
                  bms.minBPM = currentBPM;
                }
              }
            }else{
              stderr.writefln("BPM%s is undefined.", linelist[i].value.to!(string)(36));
            }
          }
          break;
        case Object_type.STOP:
          if(kaburi(linelist, i) == false){
            if(currentBPM > 0){
              if(linelist[i].value in bmstemp.stop_list){
                fractionB temp2;
                temp2 = bmstemp.stop_list[linelist[i].value];
                total_position += (temp2 * gauge_LCM * bar_bottom * gauge_point).numerator;
                bms.stop_list[stop_size] = fractionI_delta(Object_type.STOP, bmstemp.stop_list[linelist[i].value], (total_position * 240_000_000 / delta).toLong);
                stop_size += 1;
                if(bms.stop_list.length <= stop_size){
                  bms.stop_list.length *= 2;
                }
                //
                bms.stop_list[stop_size] = fractionI_delta(Object_type.RESTART, fractionI(0, 1), (total_position * 240_000_000 / delta).toLong);
                stop_size += 1;
                if(bms.stop_list.length <= stop_size){
                  bms.stop_list.length *= 2;
                }
              }else{
                stderr.writefln("STOP%s is undefined.", linelist[i].value.to!(string)(36));
              }
            }
          }
          break;
        case Object_type.TEXT:
          if(kaburi(linelist, i) == false){
            if(linelist[i].value in bmstemp.text_list){
              bms.text_list[text_size] = string_delta(Object_type.TEXT, bmstemp.text_list[linelist[i].value], (total_position * 240_000_000 / delta).toLong);
              stop_size += 1;
              if(bms.text_list.length <= text_size){
                bms.text_list.length *= 2;
              }
            }else{
              stderr.writefln("TEXT%s is undefined.", linelist[i].value.to!(string)(36));
            }
          }
          break;
        case Object_type.JUDGE:
          if(kaburi(linelist, i) == false){ 
            if(linelist[i].value in bmstemp.rank_list){
              bms.rank_list[rank_size] = fractionI_delta(Object_type.JUDGE, bmstemp.rank_list[linelist[i].value], (total_position * 240_000_000 / delta).toLong);
              stop_size += 1;
              if(bms.rank_list.length <= rank_size){
                bms.rank_list.length *= 2;
              }
            }else{
              stderr.writefln("DEFEXRANK%s is undefined.", linelist[i].value.to!(string)(36));
            }
          }
          break;
        case Object_type.ARGB_BASE:
        case Object_type.ARGB_LAYER1:
        case Object_type.ARGB_LAYER2:
        case Object_type.ARGB_POOR:
          if(linelist[i].value in bmstemp.argb_list){
            if(kaburi(linelist, i) == false){
              bms.argb_list[argb_size] = argb_delta(linelist[i].type, bmstemp.argb_list[linelist[i].value], (total_position * 240_000_000 / delta).toLong);
              argb_size += 1;
              if(bms.argb_list.length <= argb_size){
                bms.argb_list.length *= 2;
              }
            }
          }else{
            stderr.writefln("ARGB%s is undefined.", linelist[i].value.to!(string)(36));
          }
          break;
        case Object_type.BGA_KEYBOUND:
          // いずれ
          break;
        case Object_type.OPTION:
          // いずれ
          break;
        default:
          fractionL temp2;
          ulong time;
          temp2.numerator = (linelist[i].position / get_GCD(linelist[i].position, gauge_length)).toLong;
          temp2.denominator = (gauge_length / get_GCD(linelist[i].position, gauge_length)).toLong;
          temp2.reduct();
          if(kaburi(linelist, i) == false){
            time = (total_position * 240_000_000 / delta).toLong;
            if(currentBPM < 0){
              time = long.max;
            }
            if(linelist[i].type / 36 == Object_upper.LONGNOTE_1P){
              if(LNmode[linelist[i].type - Object_type.LONGNOTE_1P] == true){
                bms.note_list[note_size] = delta_show(linelist[i].type + (Object_type.TERMINAL_1P - Object_type.LONGNOTE_1P), linelist[i].value, time, position + temp2);
              }else{
                bms.note_list[note_size] = delta_show(linelist[i].type, linelist[i].value, time, position + temp2);
              }
              LNmode[linelist[i].type - Object_type.LONGNOTE_1P] ^= true;
            }else if(linelist[i].type / 36 == Object_upper.LONGNOTE_2P){
              if(LNmode[linelist[i].type - Object_type.LONGNOTE_2P + 36] == true){
                bms.note_list[note_size] = delta_show(linelist[i].type + (Object_type.TERMINAL_2P - Object_type.LONGNOTE_2P), linelist[i].value, time, position + temp2);
              }else{
                bms.note_list[note_size] = delta_show(linelist[i].type, linelist[i].value, time, position + temp2);
              }
              LNmode[linelist[i].type - Object_type.LONGNOTE_2P + 36] ^= true;
            }else{
              bms.note_list[note_size] = delta_show(linelist[i].type, linelist[i].value, time, position + temp2);
              if(bmstemp.LNobject.include(linelist[i].value)){
                sizediff_t k;
                k = before_note(bms.note_list, bms.note_list[note_size].type, note_size);
                if(k > 0){
                  switch(bms.note_list[k].type / 36){
                  case Object_upper.VISIBLE_1P:
                    bms.note_list[k].type += Object_type.LONGNOTE_1P - Object_type.VISIBLE_1P;
                    LNmode[linelist[i].type % 36] = false;
                    bms.note_list[note_size].type = bms.note_list[note_size].type % 36 + Object_type.TERMINAL_1P;
                    break;
                  case Object_upper.LONGNOTE_1P:
                    LNmode[linelist[i].type % 36] = false;
                    bms.note_list[note_size].type = bms.note_list[note_size].type % 36 + Object_type.TERMINAL_1P;
                    break;
                  case Object_upper.VISIBLE_2P:
                    bms.note_list[k].type += Object_type.LONGNOTE_2P - Object_type.VISIBLE_2P;
                    bms.note_list[note_size].type = bms.note_list[note_size].type % 36 + Object_type.TERMINAL_2P;
                    LNmode[linelist[i].type % 36 + 36] = false;
                    break;
                  case Object_upper.LONGNOTE_2P:
                    bms.note_list[note_size].type = bms.note_list[note_size].type % 36 + Object_type.TERMINAL_2P;
                    LNmode[linelist[i].type % 36 + 36] = false;
                    break;
                  default:
                    break;
                  }
                }
              }
            }
            note_size += 1;
            if(bms.note_list.length <= note_size){
              bms.note_list.length *= 2;
            }
            if(linelist[i].type / 36 == Object_upper.VISIBLE_1P ||
               linelist[i].type / 36 == Object_upper.VISIBLE_2P ||
               linelist[i].type / 36 == Object_upper.LONGNOTE_1P ||
               linelist[i].type / 36 == Object_upper.LONGNOTE_2P ||
               linelist[i].type / 36 == Object_upper.TERMINAL_1P ||
               linelist[i].type / 36 == Object_upper.TERMINAL_2P){
              if(currentBPM > bms.HSmaxBPM){
                bms.HSmaxBPM = currentBPM;
              }
              if(currentBPM > 0 && currentBPM < bms.HSminBPM){
                bms.HSminBPM = currentBPM;
              }
            }
            // 7鍵判定
            if((bms.playstyle == playstyle.FIVE ||
                bms.playstyle == playstyle.TEN ||
                bms.playstyle == playstyle.NINE_FP) &&
               (linelist[i].type % 36 == 0x08 ||
                linelist[i].type % 36 == 0x09)){
              bms.playstyle += 1;
            }
            // DP判定
            if(bms.playstyle < playstyle.TEN || bms.playstyle == playstyle.DSC_FPP ||
               bms.playstyle == playstyle.NINESP || bms.playstyle == playstyle.NINEDP){
              if(linelist[i].type / 36 == Object_upper.VISIBLE_2P ||
                linelist[i].type / 36 == Object_upper.INVISIBLE_2P ||
                linelist[i].type / 36 == Object_upper.LONGNOTE_2P ||
                linelist[i].type / 36 == Object_upper.TERMINAL_2P ||
                linelist[i].type / 36 == Object_upper.LANDMINE_2P){
                if(bms.playstyle == playstyle.NINESP){
                  if(linelist[i].type % 36 == 0x02 ||
                     linelist[i].type % 36 == 0x03 ||
                     linelist[i].type % 36 == 0x04 ||
                     linelist[i].type % 36 == 0x05){
                    bms.playstyle = playstyle.NINEDP;
                  }else{
                    bms.playstyle = playstyle.EIGHTEEN;
                  }
                }else if(bms.playstyle == playstyle.NINEDP){
                  if(linelist[i].type % 36 == 0x01 ||
                     linelist[i].type % 36 == 0x06 ||
                     linelist[i].type % 36 == 0x07 ||
                     linelist[i].type % 36 == 0x08 ||
                     linelist[i].type % 36 == 0x09){
                    bms.playstyle = playstyle.EIGHTEEN;
                  }
                }else{
                  if(bms.playstyle != playstyle.DSC_FPP || linelist[i].type % 36 != 0x06){
                    bms.playstyle += 2;
                  }
                }
              }else{
                if(bms.playstyle == playstyle.NINEDP &&
                  (linelist[i].type % 36 == 0x06 ||
                   linelist[i].type % 36 == 0x07 ||
                   linelist[i].type % 36 == 0x08 ||
                   linelist[i].type % 36 == 0x09)){
                  bms.playstyle = playstyle.EIGHTEEN;
                }
              }
            }
            // OCT/FP判定
            if(bmstemp.oct_fp && (bms.playstyle == playstyle.SEVEN || bms.playstyle == playstyle.TEN || bms.playstyle == playstyle.FOURTEEN)){
              bms.playstyle += 6;
            }
          }
          break;
        }
      }
      if(linum in bmstemp.meter_list){
        position.numerator += bar_length;
      }else{
        position.numerator += bar_bottom;
      }
      //
      total_position += (gauge_length - last_position) * gauge_point;
      bms.bar_list[bar_size] = delta_show(Object_type.LINE, 0, (total_position * 240_000_000 / delta).toLong, position);
      bar_size += 1;
      if(bms.bar_list.length <= bar_size){
        bms.bar_list.length *= 2;
      }
    }
    // サイズ調整
    bms.note_list.length = note_size;
    bms.background_list.length = background_size;
    bms.BPM_list.length = BPM_size;
    bms.stop_list.length = stop_size;
    bms.text_list.length = text_size;
    bms.argb_list.length = argb_size;
    bms.rank_list.length = rank_size;
    bms.bar_list.length = bar_size;
    // 閉じ忘れLN除去
    foreach(size_t i; 0..36){
      size_t n;
      if(LNmode[i] == true){
        n = before_note(bms.note_list, Object_type.LONGNOTE_1P + cast(uint)i + 1, note_size);
        bms.note_list[n].type -= Object_type.LONGNOTE_1P - Object_type.VISIBLE_1P;
      }
      if(LNmode[i+36] == true){
        n = before_note(bms.note_list, Object_type.LONGNOTE_2P + cast(uint)i + 1, note_size);
        bms.note_list[n].type -= Object_type.LONGNOTE_2P - Object_type.VISIBLE_2P;
      }
    }
    // baseBPMの設定
    if(bms.baseBPM.numerator == 0){
      bms.baseBPM = bms.startBPM;
    }
    // TITLEからSUBTITLEを分離
    if(bms.title.length >= 2 && bms.subtitle.length == 0){
      sizediff_t c;
      c = SUBTITLE_END.lastIndexOf(bms.title[$-1]);
      if(c >= 0){
        writefln("debug %s, %d", bms.title, c);
        for(sizediff_t i = bms.title.length - 2; i > 0; i -= 1){
          if(bms.title[i] == SUBTITLE_START[c]){
            bms.subtitle = bms.title[i..$];
            bms.title.length = i;
            break;
          }
        }
      }
    }
    // DIFFICULTYを自動分析
    if(bms.difficulty == -1){
      if(DIFFICULTY_EASY.includePart(bms.subtitle)){
        bms.difficulty = 1;
      }else if(DIFFICULTY_NORMAL.includePart(bms.subtitle)){
        bms.difficulty = 2;
      }else if(DIFFICULTY_HARD.includePart(bms.subtitle)){
        bms.difficulty = 3;
      }else if(DIFFICULTY_MANIAC.includePart(bms.subtitle)){
        bms.difficulty = 4;
      }else if(DIFFICULTY_INSANE.includePart(bms.subtitle)){
        bms.difficulty = 5;
      }else{
        bms.difficulty = 2;
      }
    }
  }
  /*
   * 後に重複する
  */
  bool kaburi(ref line_list[] linelist, size_t start){
    foreach(i; (start + 1)..linelist.length){
      if(linelist[start].position < linelist[i].position){
        return false;
      }
      if(linelist[start].type == linelist[i].type){
        return true;
      }
    }
    return false;
  }
  /*
   * 同音
  */
  bool same_front(ref line_list[] linelist, size_t start){
    for(sizediff_t i = (start - 1); i >= 0; i -= 1){
      if(linelist[start].position > linelist[i].position){
        return false;
      }
      if((linelist[i].type / 36 == Object_upper.VISIBLE_1P ||
          linelist[i].type / 36 == Object_upper.LONGNOTE_1P ||
          linelist[i].type / 36 == Object_upper.TERMINAL_1P ||
          linelist[i].type / 36 == Object_upper.VISIBLE_2P ||
          linelist[i].type / 36 == Object_upper.LONGNOTE_2P ||
          linelist[i].type / 36 == Object_upper.TERMINAL_2P) &&
         linelist[start].value == linelist[i].value){
        return true;
      }
    }
    return false;
  }
  /*
   * 同レーンにある直前のノートタイプ
  */
  size_t before_note(ref delta_show[] linelist, uint type, size_t start){
    for(sizediff_t i = (start - 1); i >= 0; i -= 1){
      if(type % 36 == linelist[i].type % 36){
        if(((linelist[i].type / 36) & 1) == 1){
          if(linelist[i].type / 36 == Object_upper.VISIBLE_1P ||
             linelist[i].type / 36 == Object_upper.LONGNOTE_1P ||
             linelist[i].type / 36 == Object_upper.TERMINAL_1P){
            return i;
          }
        }else{
          if(linelist[i].type / 36 == Object_upper.VISIBLE_2P ||
             linelist[i].type / 36 == Object_upper.LONGNOTE_2P ||
             linelist[i].type / 36 == Object_upper.TERMINAL_2P){
            return i;
          }
        }
      }
    }
    return -1;
  }
  /*
   * ネストモードの判定
   * 
  */
  bool get_nestmode(C)(C fname, Charset charset) if(isSomeString!(C)){
    File f;
    int nest;
    cstring line;
    //
    f = File(fname, ACCESSIBLE.READ);
    nest = 0;
    while(!f.eof){
      if(get_size(charset) == 1){
        char[] temp;
        f.readln(temp);
        line = convert!(CONVERTCODE)(replace_vaild(temp, charset), charset);
      }else if(get_size(charset) == 2){
        throw new ReadException("Sorry, \"readLineW\" is not exist.");
      }else if(get_size(charset) == 4){
        throw new ReadException("Sorry, \"readLineD\" is not exist.");
      }
      if(line.modeIndex("#IF", CaseSensitive.no) >= 0 ||
         line.modeIndex("#SWITCH", CaseSensitive.no) >= 0){
        nest += 1;
      }else if(line.modeIndex("#ENDIF", CaseSensitive.no) >= 0 ||
               line.modeIndex("#END IF", CaseSensitive.no) >= 0 ||
               line.modeIndex("#IFEND", CaseSensitive.no) >= 0 ||
               line.modeIndex("#ENDSW", CaseSensitive.no) >= 0){
        nest -= 1;
      }
    }
    f.close();
    return (nest == 0);
  }
}
