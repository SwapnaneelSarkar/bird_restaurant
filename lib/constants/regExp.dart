
class RegexPatterns{
  static RegExp onlyText  =  RegExp(r'^[a-zA-Z]+(?: [a-zA-Z]+)*$');
  static RegExp phone  =  RegExp(r'^[0-9]{10}$');
  static RegExp onlyNumber  =  RegExp(r'^[0-9]+$');
  static RegExp email  = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static RegExp pincode =  RegExp(r'^[0-9]{6}$');
  static RegExp notEmpty =  RegExp(r'^.+$');
}

