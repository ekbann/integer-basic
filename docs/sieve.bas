5 REM ERATOSTHENES SIEVE PRIME NUMBER PROGRAM IN BASIC 
10 SIZE = 8190
20 DIM FLAGS% (8191)
30 PRINT "ONLY 1 ITERATION"
50 COUNT = 0
60 FOR I = 0 TO SIZE
70 FLAGS% (I) = 1
80 NEXT I
90 FOR I = 0 TO SIZE
100 IF FLAGS% (I) = 0 THEN 180
110 PRIME = I+I + 3
120 K = I + PRIME
130 IF K > SIZE THEN 170
140 FLAGS% (K) = 0
150 K = K + PRIME
160 GOTO 130
170 COUNT = COUNT + 1
180 NEXT I
190 PRINT COUNT," PRIMES"