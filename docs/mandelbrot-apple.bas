1 REM https://www.calormen.com/jsbasic/
5 HOME:GR
10 WI=40:HE=40:MI=16
20 FOR PY=0 TO HE-1
30 YY=PY/0.40/HE - 1.3
40 FOR PX=0 TO WI-1
50 XX=PX/0.32/WI - 2.2
60 XS=0:YS=0
70 X=0:Y=0
80 IT=0
90 IF IT>=MI OR (XS+YS)>=4.0 THEN GOTO 160
100 Y=X*Y*2.0+YY
110 X=XS-YS+XX
120 XS=X*X
130 YS=Y*Y
140 IT=IT+1
150 GOTO 90
160 COLOR=MI-IT
170 PLOT PX,PY
180 NEXT PX
190 NEXT PY
210 END