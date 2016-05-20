###G00 - MOVE TO POSITION
* X = X Position in MM (FLOAT)
* Y = Y Position in MM (FLOAT)
* F = Feedrate in MM/S (FLOAT)
* `G00 X100.0 Y50.0 F50.0`

###G01 - BLAST LINE TO POSITION
* X = X Position in MM (FLOAT)
* Y = Y Position in MM (FLOAT)
* F = Feedrate in MM/S (FLOAT)
* `G01 X100.0 Y50.0 F50.0`

###G02 - BLAST CLOCKWISE ARC TO POSITION
* I = X Position of Arc Center in MM (FLOAT)
* J = Y Position of Arc Center in MM (FLOAT)
* X = X Destination in MM (FLOAT)
* Y = Y Destination in MM (FLOAT)
* F = Feedrate in MM/S (FLOAT)
* `G02 I100.0 J50.0 X200.0 Y50.0 F100.0`

###G03 - BLAST COUNTER-CLOCKWISE ARC TO POSITION
* See G02

###G04 - PAUSE (BLAST OFF)
* P = Pause Duration in Milliseconds (FLOAT)
* `G04 P1500.0`

###G05 - DWELL (BLAST ON)
* P = Pause Duration in Milliseconds (FLOAT)
* `G05 P1500.0`

---
###D01 - UPDATE DIMENSION LIMITS
* T = Top Limit in MM (FLOAT)
* B = Bottom Limit in MM (FLOAT)
* R = Right Limit in MM (FLOAT)
* L = Left Limit in MM (FLOAT)
* `D01 T50.0 B-50.0 R100.0 L-100.0`

###D05 - UPDATE MICROSTEP SETTINGS
* X = X-axis Microsteps (INT)
* Y = Y-axis Microsteps (INT)
* `D05 X4 Y8`

###D10 - UPDATE FEEDRATE
* F = FeedRate (FLOAT)
* A = Acceleration Toggle (0/1)
* B = Bias Toggle (0/1)
* `D10 F150.0 A0 B1`

###D30 - POSITION AND SETTING REPORT
* `D30`

---
###M00 - ABSOLUTE MOVE
* X = Distance to move along X-axis in MM (FLOAT)
* Y = Distance to move along Y-axis in MM (FLOAT
* `M00 X-100.0 Y0.0`

###M10 - JOG X AXIS FORWARD
* S = Jog Multiplier (FLOAT)
* `M10 S5.0`

###M11 - JOG X AXIS BACKWARD
* S = Jog Multiplier (FLOAT)
* `M11 S10.0`

###M20 - JOG Y AXIS FORWARD
* S = Jog Multiplier (FLOAT)
* `M20 S5.0`

###M21 - JOG Y AXIS BACKWARD
* S = Jog Multiplier (FLOAT)
* `M21 S10.0`

###M50 - BLAST ON
* `M50`

###M51 - BLAST OFF
* `M51`

###M60 - AIR ON
* `M60`

###M61 - AIR OFF
* `M61`

###M100 - Teleport to (x,y)
* X = X Position in MM (FLOAT)
* Y = Y Position in MM (FLOAT)
* `M100 X10.0 Y50.0`
* `M100 //Teleport to (0,0)`