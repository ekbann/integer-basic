10 REM BRESENHAM'S CIRCLE ALGORITHM
20 MGR
30 RADIUS = 25
40 X0 = 40
50 Y0 = 30
60 COLOR = 4
70 X = 0
80 Y = RADIUS
90 D = 3-(2*RADIUS)
100 GOSUB 5000
110 FOR I = 1 TO 63
120 IF X<=Y THEN GOSUB 1000
130 GOSUB 2000
140 GOSUB 5000
150 NEXT I
160 END
1000 X = X + 1
1010 IF X=Y THEN END
1020 RETURN
2000 IF D<0 THEN GOTO 3000
2010 GOSUB 4000
2020 RETURN

3000 D = D + (4*X) + 6
3010 GOTO 2020

4000 Y = Y - 1
4010 D = D + 4 * (X-Y) + 10
4020 RETURN

5000 REM PLOT QUADRANT POINTS
5002 PLOT xc+x, yc+y
5003 PLOT xc-x, yc+y
5004 PLOT xc+x, yc-y
5005 PLOT xc-x, yc-y
5006 PLOT xc+y, yc+x
5007 PLOT xc-y, yc+x
5008 PLOT xc+y, yc-x
5009 PLOT xc-y, yc-x
5010 RETURN