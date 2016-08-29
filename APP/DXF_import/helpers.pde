float floatFormat( float f, int digits ){
  return round(f * pow(10,digits)) / pow(10, digits);
}

float floatFormatS( String s, int digits ){
  return round( float(s) * pow(10,digits)) / pow(10, digits);
}