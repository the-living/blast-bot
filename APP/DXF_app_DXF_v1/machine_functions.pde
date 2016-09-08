//------------------------------------------------------------------------------
// MACHINE FUNCTIONS
//------------------------------------------------------------------------------
// Functions for emulating or interfacing with robot

// DETERMINE FEEDRATE
//----------------------------------------
// Calculate actual feedrate from given command
// based on known machine limits (from firmware)
float determineFeedrate( float dx, float dy, float f ) {
  //speed limits hard-coded into machine firmware
  float max_x_vel = 300.0;
  float max_y_vel = 80.0;
  
  float vec = sqrt( dx*dx + dy*dy );
  float vx = min( max_x_vel, f * dx / vec );
  float vy = min( max_y_vel, f * dy / vec );
  
  return sqrt( vx*vx + vy*vy);
}

//ATAN3
//----------------------------------------
// Return angle from a given dx/dy
float atan3( float dy, float dx ){
  float a = atan2(dy,dx);
  if( a < 0 ) a += TWO_PI;
  return a;
}

// CALCULATE MOVE TIME
//----------------------------------------
// Calculate time it would take to move to
// a given point at a given speed
float calcLineTime(PVector newPt, PVector lastPt, float f_){
  float duration;
  
  float dx = newPt.x - lastPt.x;
  float dy = newPt.y - lastPt.y;
  float l = sqrt(dx*dx + dy*dy);
  
  if( l == 0 ){
    duration = 0.0;
    //println("TOO SHORT");
  } else{
    f_ = min(f_, determineFeedrate( dx, dy, f_ ) );
    duration = l / f_;
    //println("l/f: " + l + "/" + f_);
  }
  return duration;
}