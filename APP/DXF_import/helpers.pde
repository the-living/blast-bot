//CHECKSUM GENERATOR
//Used to ensure no data loss in transfer
//when issuing multiple commands
String generateChecksum(String line) {
  byte checksum=0;
  for ( int i=0; i<line.length (); ++i ) {
    checksum ^= line.charAt(i);
  }
  return "*"+((int)checksum);
}

float floatFormat( float f, int digits ){
  return round(f * pow(10,digits)) / pow(10, digits);
}

float floatFormatS( String s, int digits ){
  return round( float(s) * pow(10,digits)) / pow(10, digits);
}

float parseNumber(String s, String C, float f) {
  int index = s.indexOf(C);

  if ( index == -1 ) {
    return f;
  }

  int endIndex = s.indexOf(" ", index);

  if ( endIndex == -1 ) {
    endIndex = s.length();
  }  

  String val = s.substring( index+1, endIndex );

  return float(val);
}

String parseString( String s, String C, String d) {
  int index = s.indexOf(C);

  if ( index == -1 ) {
    return d;
  }

  int endIndex = s.indexOf(" ", index);

  if ( endIndex == -1 ) {
    endIndex = s.length();
  }  

  String val = s.substring( index+1, endIndex );

  return val;
}