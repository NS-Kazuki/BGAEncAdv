module loader.error;

/**
 * エラークラス
*/
class LoadException : Exception{
  /** 汎用エラークラスにエラーメッセージを送る */
  this(lazy string msg, string file = __FILE__, int line = __LINE__){
    super(msg, file, line);
  }
}

class ReadException : Exception{
  /** 汎用エラークラスにエラーメッセージを送る */
  this(lazy string msg, string file = __FILE__, int line = __LINE__){
    super(msg, file, line);
  }
}