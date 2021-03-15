G0 G90 G49 M5

IF[#4120EQ#4320]GOTO999

(Set the tool change position values in metric)
#100001=1778     (Y pre pos)
#100002=2190.97  (Y final pos)
#100003=-52.2528 (Z pos)
#100004=0

(convert tool change position based on active units)
IF[71EQ#4006] GOTO 10
IF[21EQ#4006] GOTO 10
   #100001=#100001/25.4
   #100002=#100002/25.4
   #100003=#100003/25.4
   #100004=#100004/25.4
N10

##LANGUAGE AC
   // deactivate softlimits and activate hard limits for the tool change
   activateSoftLimitCheck(FALSE);
##LANGUAGE NATIVE

(prepos)
G0 G53 Z0.0
G0 G53 Y[#100001]

(final pos)
G0 G53 Y[#100002]
G0 G53 Z[#100003]

(find pocket number tool is residing in)
(set #15000 to target pocket)
#1=1
WHILE[#1LE30]DO1
    IF[#[15000+#1]NE#4120]GOTO99
        #15000=#1
        GOTO100
    N99 #1=#1+1
END1
N100

##LANGUAGE AC
INT nToolID;
nToolID = getVariable("#4120");
STRING R_AXIS;
R_AXIS = "R"+getVariable("#15000");
STRING EXCHANGE_POCKET;
EXCHANGE_POCKET = "POCKET_"+getVariable("#15000");
STRING EXCHANGE_JCT;
EXCHANGE_JCT = "T"+getVariable("#15000");
STRING PARENT;
PARENT = EXCHANGE_POCKET+"@"+EXCHANGE_JCT;

IF(nToolID>0);
    setNextTool(getToolNameByNumber(nToolID),"S");
ENDIF;

//rotate ATC to new tool position
move(AXIS, "V", -12*(getVariable("#15000")-1), 0.4);
move(AXIS, R_AXIS, 90, 0.4);

//rotate ATC arm
move(AXIS, "C9", 89.9, 0.4);
move(AXIS, "C9", 90, 0.4);

//remove current tool in spindle, if exists
IF(exist(getCurrentTool("S")));
    grasp(getCurrentTool("S"), "ATC_POCKET_A@A");
ENDIF;

//if a new tool is to be loaded
IF(exist(getNextTool("S")));
    grasp(getNextTool("S"), "ATC_POCKET_B@B");
ENDIF;

//exchange tools between spindle and ATC pocket
move(AXIS, "Z9", -114.3, 0.5);
move(AXIS, "C9", 269.9, 0.5);
move(AXIS, "C9", 270, 0.5);
move(AXIS, "Z9", 0, 0.5);

//transfer incoming tool to spindle
IF(exist(getNextTool("S")));
    release(getNextTool("S"), getSpindleObject("S"));
ENDIF;

//transfer outgoing tool to ATC pocket
IF(exist(getCurrentTool("S")));
    release(getCurrentTool("S"), PARENT);
ENDIF;

//home ATC arm
move(AXIS, "C9", 0, 0.5);

//retract the ATC pocket
move(AXIS, R_AXIS, 0, 0.4);

//activate new tool
IF(exist(getNextTool("S")));
    activateNextTool("S");
ENDIF;

##LANGUAGE NATIVE

(save position of old tool)
#[15000+#15000]=#4320

(write tool number in spindle)
#4320=#4120

G0 G53 Y[#100001]

##LANGUAGE AC
     //activate softlimits and activate hard limits for the tool change
   activateSoftLimitCheck(TRUE);
##LANGUAGE NATIVE

N999
M99
