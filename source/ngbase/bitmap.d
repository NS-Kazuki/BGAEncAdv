/**
 * ビットマップデータを扱うクラスの基礎クラス。
 *
 * This file is part of Nageyari Gamebase.
 * 
 * License:   Public Domain
 * Date:      August 21, 2010
 * Author:    Kazuki Okawa, naka4959@kcn.ne.jp
*/
module ngbase.bitmap;

/**
 * 32ビットカラーを扱う構造体
*/
public struct color{
  ubyte red; /// 赤成分
  ubyte green; /// 緑成分
  ubyte blue; /// 青成分
  ubyte alpha; /// 不透明度
}

/**
 * ファイルフォーマットのエラークラス
*/
class IllegalFormatException : Exception{
  /** 汎用エラークラスにエラーメッセージを送る */
  this(lazy string msg, string file = __FILE__, int line = __LINE__){
    super(msg, file, line);
  }
}

/**
 * ビットマップ全般を扱うクラス
*/
mixin template Bitmap(){
  protected{
    uint bitmap_width; // 画像の幅
    uint bitmap_height; // 画像の高さ
    color[] standard_map; // 実体のポインタ
    uint tex_width; // プログラム上での幅
    uint tex_height; // プログラム上での高さ
  }
  public{
    @property{
      /**
       * 論理幅を取得する
       * 
       * Returns: 
       *  画像データ本来の幅
      */
      uint width(){
        return(bitmap_width);
      }
      /**
       * 論理高さを取得する
       *
       * Returns: 
       *  画像データ本来の高さ
      */
      uint height(){
        return(bitmap_height);
      }
      /**
       * 実際の幅を取得する
       *
       * Returns:
       *  テクスチャ化した画像の幅
      */
      uint texwidth(){
        return(tex_width);
      }
      /**
       * 実際の高さを取得する
       *
       * Returns:
       *  テクスチャ化した画像の高さ
      */
      uint texheight(){
        return(tex_height);
      }
      /**
       * 相対的な幅の取得
       *
       * Returns:
       *  テクスチャ幅に対する本来の幅の割合
      */
      float texcoord_width(){
        return(cast(float)bitmap_width / tex_width);
      }
      /**
       * 相対的な高さの取得
       *
       * Returns: 
       *  テクスチャ高さに対する本来の高さの割合
      */
      float texcoord_height(){
        return(cast(float)bitmap_height / tex_height);
      }
      /**
       * データを取得する
       *
       * Returns:
       *  画像データの先頭アドレス
      */
      color[] data(){
        return(standard_map);
      }
    }
    /*
     * 特定の座標を示す添字を求める
     *
     * Params:
     *  y = y座標
     *  x = x座標
     *
     * Returns:
     *  指定した座標を示す添字
    */
    size_t data_position(size_t y, size_t x){
      return(y * tex_width + x);
    }
    /* 解放 */
    ~this(){
    }
  }
  protected{
    /*
     * テクスチャとして使える最小の数を求める
     *
     * Params:
     *  size = 計算に使う数
     *
     * Returns:
     *  引数より大きい，最小の2の乗
    */
    @safe static uint texsize(uint size){
      uint result;
      result = 1;
      while(result < size){
        result *= 2;
      }
      return(result);
    }
    unittest{
      writefln("Unittest Bitmap.texsize");
      assert(texsize(48) == 64);
      assert(texsize(32) == 32);
    }
    /*
     * 画像の格納領域を，二次元配列で作成する
     * 格納している形式は，透明度を含む32ビットカラー
     * 先頭に各列の先頭アドレスのポインタを格納する領域を確保し，
     * それを介して各ピクセルのデータを取得する構造とする
    */
    void create_bitmap(){
      tex_width = texsize(bitmap_width);
      tex_height = texsize(bitmap_height);
      standard_map.length = tex_width * tex_height;
    }
  }
}
