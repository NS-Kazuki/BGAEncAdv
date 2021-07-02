module loader.data;

import util.fraction;
import util.code;
import loader.charfile;

import std.bigint;
import std.stdio;

struct line_list{
  uint type;
  uint value;
  BigInt position;
  //
  int opCmp(ref const line_list obj) const{
    if(position == obj.position){
      if(type == Object_type.STOP && obj.type == Object_type.STOP){
        return 0;
      }else if(type == Object_type.STOP){
        return 1;
      }else if(obj.type == Object_type.STOP){
        return -1;
      }
      if((type == Object_type.BPM || type == Object_type.EXBPM) && (obj.type == Object_type.BPM || obj.type == Object_type.EXBPM)){
        return 0;
      }else if(type == Object_type.BPM || type == Object_type.EXBPM){
        return 1;
      }else if(obj.type == Object_type.BPM || obj.type == Object_type.EXBPM){
        return -1;
      }
      return obj.type - type;
    }else{
      return (cast(line_list)this).position.opCmp((cast(line_list)obj).position);
    }
  }
}

// 配置変換オプションの影響を受けるオブジェ
struct delta_show{
  uint type;
  uint value;
  ulong time;
  fractionL position;
}

// 配置変換オプションの影響を受けないオブジェ
struct delta_hide(T){
  uint type;
  T value;
  ulong time;
}

struct line_data{
  uint type;
  uint[] line;
}

struct exwav{
  string name;
  fractionI panpot;
  fractionI volume;
  fractionI freq;
}

struct exbmp{
  string name;
  argb color;
}

union argb{
  ubyte[4] values;
  struct{
    ubyte a;
    ubyte r;
    ubyte g;
    ubyte b;
  }
}

struct trimming{
  bool using;
  union{
    int[7] values;
    struct{
      uint number;
      int xstart;
      int ystart;
      int xend;
      int yend;
      int dx;
      int dy;
    }
  }
}

enum Object_upper{
  SETTING        = 0x00,
  VISIBLE_1P     = 0x01,
  VISIBLE_2P     = 0x02,
  INVISIBLE_1P   = 0x03,
  INVISIBLE_2P   = 0x04,
  LONGNOTE_1P    = 0x05,
  LONGNOTE_2P    = 0x06,
  SETTING_EX     = 0x09,
  SETTING_EX2    = 0x0A,
  PACKAGE_1P     = 0x0B,
  PACKAGE_2P     = 0x0C,
  LANDMINE_1P    = 0x0D,
  LANDMINE_2P    = 0x0E,
  SETTING_EX3    = 0x10,
  TERMINAL_1P    = 0x11,
  TERMINAL_2P    = 0x12
}

enum Object_type{
  BGM            = 0x00 * 36 + 0x01,
  BAR            = 0x00 * 36 + 0x02,
  BPM            = 0x00 * 36 + 0x03,
  BGA_BASE       = 0x00 * 36 + 0x04,
  BGA_POOR       = 0x00 * 36 + 0x06,
  BGA_LAYER1     = 0x00 * 36 + 0x07,
  EXBPM          = 0x00 * 36 + 0x08,
  STOP           = 0x00 * 36 + 0x09,
  BGA_LAYER2     = 0x00 * 36 + 0x0A,
  ALPHA_BASE     = 0x00 * 36 + 0x0B,
  ALPHA_LAYER1   = 0x00 * 36 + 0x0C,
  ALPHA_LAYER2   = 0x00 * 36 + 0x0D,
  ALPHA_POOR     = 0x00 * 36 + 0x0E,
  //
  VISIBLE_1P     = 0x01 * 36 + 0x00,
  VISIBLE1_1P    = 0x01 * 36 + 0x01,
  VISIBLE2_1P    = 0x01 * 36 + 0x02,
  VISIBLE3_1P    = 0x01 * 36 + 0x03,
  VISIBLE4_1P    = 0x01 * 36 + 0x04,
  VISIBLE5_1P    = 0x01 * 36 + 0x05,
  VISIBLESC_1P   = 0x01 * 36 + 0x06,
  VISIBLEFP_1P   = 0x01 * 36 + 0x07,
  VISIBLE6_1P    = 0x01 * 36 + 0x08,
  VISIBLE7_1P    = 0x01 * 36 + 0x09,
  //
  VISIBLE_2P     = 0x02 * 36 + 0x00,
  VISIBLE1_2P    = 0x02 * 36 + 0x01,
  VISIBLE2_2P    = 0x02 * 36 + 0x02,
  VISIBLE3_2P    = 0x02 * 36 + 0x03,
  VISIBLE4_2P    = 0x02 * 36 + 0x04,
  VISIBLE5_2P    = 0x02 * 36 + 0x05,
  VISIBLESC_2P   = 0x02 * 36 + 0x06,
  VISIBLEFP_2P   = 0x02 * 36 + 0x07,
  VISIBLE6_2P    = 0x02 * 36 + 0x08,
  VISIBLE7_2P    = 0x02 * 36 + 0x09,
  //
  INVISIBLE_1P   = 0x03 * 36 + 0x00,
  INVISIBLE1_1P  = 0x03 * 36 + 0x01,
  INVISIBLE2_1P  = 0x03 * 36 + 0x02,
  INVISIBLE3_1P  = 0x03 * 36 + 0x03,
  INVISIBLE4_1P  = 0x03 * 36 + 0x04,
  INVISIBLE5_1P  = 0x03 * 36 + 0x05,
  INVISIBLESC_1P = 0x03 * 36 + 0x06,
  INVISIBLEFP_1P = 0x03 * 36 + 0x07,
  INVISIBLE6_1P  = 0x03 * 36 + 0x08,
  INVISIBLE7_1P  = 0x03 * 36 + 0x09,
  //
  INVISIBLE_2P   = 0x04 * 36 + 0x00,
  INVISIBLE1_2P  = 0x04 * 36 + 0x01,
  INVISIBLE2_2P  = 0x04 * 36 + 0x02,
  INVISIBLE3_2P  = 0x04 * 36 + 0x03,
  INVISIBLE4_2P  = 0x04 * 36 + 0x04,
  INVISIBLE5_2P  = 0x04 * 36 + 0x05,
  INVISIBLESC_2P = 0x04 * 36 + 0x06,
  INVISIBLEFP_2P = 0x04 * 36 + 0x07,
  INVISIBLE6_2P  = 0x04 * 36 + 0x08,
  INVISIBLE7_2P  = 0x04 * 36 + 0x09,
  //
  LONGNOTE_1P    = 0x05 * 36 + 0x00,
  LONGNOTE1_1P   = 0x05 * 36 + 0x01,
  LONGNOTE2_1P   = 0x05 * 36 + 0x02,
  LONGNOTE3_1P   = 0x05 * 36 + 0x03,
  LONGNOTE4_1P   = 0x05 * 36 + 0x04,
  LONGNOTE5_1P   = 0x05 * 36 + 0x05,
  LONGNOTESC_1P  = 0x05 * 36 + 0x06,
  LONGNOTEFP_1P  = 0x05 * 36 + 0x07,
  LONGNOTE6_1P   = 0x05 * 36 + 0x08,
  LONGNOTE7_1P   = 0x05 * 36 + 0x09,
  //
  LONGNOTE_2P    = 0x06 * 36 + 0x00,
  LONGNOTE1_2P   = 0x06 * 36 + 0x01,
  LONGNOTE2_2P   = 0x06 * 36 + 0x02,
  LONGNOTE3_2P   = 0x06 * 36 + 0x03,
  LONGNOTE4_2P   = 0x06 * 36 + 0x04,
  LONGNOTE5_2P   = 0x06 * 36 + 0x05,
  LONGNOTESC_2P  = 0x06 * 36 + 0x06,
  LONGNOTEFP_2P  = 0x06 * 36 + 0x07,
  LONGNOTE6_2P   = 0x06 * 36 + 0x08,
  LONGNOTE7_2P   = 0x06 * 36 + 0x09,
  // 実験用項目、本体側での複音実装
  PACKAGE_1P     = 0x0B * 36 + 0x00,
  PACKAGE1_1P    = 0x0B * 36 + 0x01,
  PACKAGE2_1P    = 0x0B * 36 + 0x02,
  PACKAGE3_1P    = 0x0B * 36 + 0x03,
  PACKAGE4_1P    = 0x0B * 36 + 0x04,
  PACKAGE5_1P    = 0x0B * 36 + 0x05,
  PACKAGESC_1P   = 0x0B * 36 + 0x06,
  PACKAGEFP_1P   = 0x0B * 36 + 0x07,
  PACKAGE6_1P    = 0x0B * 36 + 0x08,
  PACKAGE7_1P    = 0x0B * 36 + 0x09,
  //
  PACKAGE_2P     = 0x0C * 36 + 0x00,
  PACKAGE1_2P    = 0x0C * 36 + 0x01,
  PACKAGE2_2P    = 0x0C * 36 + 0x02,
  PACKAGE3_2P    = 0x0C * 36 + 0x03,
  PACKAGE4_2P    = 0x0C * 36 + 0x04,
  PACKAGE5_2P    = 0x0C * 36 + 0x05,
  PACKAGESC_2P   = 0x0C * 36 + 0x06,
  PACKAGEFP_2P   = 0x0C * 36 + 0x07,
  PACKAGE6_2P    = 0x0C * 36 + 0x08,
  PACKAGE7_2P    = 0x0C * 36 + 0x09,
  //
  LANDMINE_1P    = 0x0D * 36 + 0x00,
  LANDMINE1_1P   = 0x0D * 36 + 0x01,
  LANDMINE2_1P   = 0x0D * 36 + 0x02,
  LANDMINE3_1P   = 0x0D * 36 + 0x03,
  LANDMINE4_1P   = 0x0D * 36 + 0x04,
  LANDMINE5_1P   = 0x0D * 36 + 0x05,
  LANDMINESC_1P  = 0x0D * 36 + 0x06,
  LANDMINEFP_1P  = 0x0D * 36 + 0x07,
  LANDMINE6_1P   = 0x0D * 36 + 0x08,
  LANDMINE7_1P   = 0x0D * 36 + 0x09,
  //
  LANDMINE_2P    = 0x0E * 36 + 0x00,
  LANDMINE1_2P   = 0x0E * 36 + 0x01,
  LANDMINE2_2P   = 0x0E * 36 + 0x02,
  LANDMINE3_2P   = 0x0E * 36 + 0x03,
  LANDMINE4_2P   = 0x0E * 36 + 0x04,
  LANDMINE5_2P   = 0x0E * 36 + 0x05,
  LANDMINESC_2P  = 0x0E * 36 + 0x06,
  LANDMINEFP_2P  = 0x0E * 36 + 0x07,
  LANDMINE6_2P   = 0x0E * 36 + 0x08,
  LANDMINE7_2P   = 0x0E * 36 + 0x09,
  //
  TEXT           = 0x09 * 36 + 0x09,
  JUDGE          = 0x0A * 36 + 0x00,
  ARGB_BASE      = 0x0A * 36 + 0x01,
  ARGB_LAYER1    = 0x0A * 36 + 0x02,
  ARGB_LAYER2    = 0x0A * 36 + 0x03,
  ARGB_POOR      = 0x0A * 36 + 0x04,
  BGA_KEYBOUND   = 0x0A * 36 + 0x05,
  OPTION         = 0x0A * 36 + 0x06,
  // 内部で生成されるオブジェクト
  LINE           = 0x10 * 36 + 0x00,
  RESTART        = 0x10 * 36 + 0x09,
  //
  TERMINAL_1P    = 0x11 * 36 + 0x00,
  TERMINAL1_1P   = 0x11 * 36 + 0x01,
  TERMINAL2_1P   = 0x11 * 36 + 0x02,
  TERMINAL3_1P   = 0x11 * 36 + 0x03,
  TERMINAL4_1P   = 0x11 * 36 + 0x04,
  TERMINAL5_1P   = 0x11 * 36 + 0x05,
  TERMINALSC_1P  = 0x11 * 36 + 0x06,
  TERMINALFP_1P  = 0x11 * 36 + 0x07,
  TERMINAL6_1P   = 0x11 * 36 + 0x08,
  TERMINAL7_1P   = 0x11 * 36 + 0x09,
  //
  TERMINAL_2P    = 0x12 * 36 + 0x00,
  TERMINAL1_2P   = 0x12 * 36 + 0x01,
  TERMINAL2_2P   = 0x12 * 36 + 0x02,
  TERMINAL3_2P   = 0x12 * 36 + 0x03,
  TERMINAL4_2P   = 0x12 * 36 + 0x04,
  TERMINAL5_2P   = 0x12 * 36 + 0x05,
  TERMINALSC_2P  = 0x12 * 36 + 0x06,
  TERMINALFP_2P  = 0x12 * 36 + 0x07,
  TERMINAL6_2P   = 0x12 * 36 + 0x08,
  TERMINAL7_2P   = 0x12 * 36 + 0x09
}

enum playstyle{
  FIVE        = 0x00, // 11～17
  SEVEN       = 0x01, // 11～19
  TEN         = 0x02, // 11～17,21～27
  FOURTEEN    = 0x03, // 11～19,21～29
  NINESP      = 0x04, // 11～15,22～25
  NINEDP      = 0x05, // 11～19
  EIGHTEEN    = 0x06, // 11～19,21～29
  DSC_FPP     = 0x07, // DSC / FPP
  NINE_FP     = 0x08, // OCT / FP
  THIRTEEN_FP = 0x09  // OCT / FP
}

alias delta_hide!(int) int_delta;
alias delta_hide!(long) long_delta;
alias delta_hide!(fractionI) fractionI_delta;
alias delta_hide!(fractionL) fractionL_delta;
alias delta_hide!(argb) argb_delta;
alias delta_hide!(trimming) trimming_delta;
alias delta_hide!(string) string_delta;

/// BMSプレイ時に使うデータ
class BMS_data{
  public{
    string banner;
    string stagefile;
    string backbmp;
    string level;
    string title;
    string subtitle;
    string artist;
    string[] subartist;
    string maker;
    string genre;
    string comment;
    string path;
    string[] option;
    //
    uint playstyle = 0;
    int difficulty = -1;
    //
    bool poor_overray = false;
    //
    string[36*36] wav_list;
    string[36*36] bmp_list;
    trimming[36*36] bga_list;
    delta_show[] note_list;
    //
    int_delta[] background_list;
    fractionI_delta[] BPM_list;
    fractionI_delta[] stop_list;
    string_delta[] text_list;
    argb_delta[] argb_list;
    fractionI_delta[] rank_list;
    delta_show[] bar_list;
    //
    ulong last_time;
    //
    fractionI rank = {100};
    fractionL total = {0};
    fractionI volwav = {1};
    fractionI startBPM = {130};
    fractionI baseBPM;
    fractionL maxBPM;
    fractionI minBPM;
    fractionI HSmaxBPM;
    fractionI HSminBPM;
    //
    Character character;
  }
}

/// BMS解析用の一時データ
struct BMS_temp{
  fractionI[uint] BPM_list;
  fractionI[uint] stop_list;
  fractionI[uint] rank_list;
  string[uint] wav_list;
  exwav[][uint] exwav_list;
  string[uint] bmp_list;
  exbmp[uint] exbmp_list;
  string[uint] text_list;
  argb[uint] argb_list;
  line_data[][1000] line_list;
  size_t[1000] list_size;
  //
  fractionL[size_t] meter_list;
  //
  uint[] LNobject;
  Charset charset;
  bool oct_fp = false;
}
