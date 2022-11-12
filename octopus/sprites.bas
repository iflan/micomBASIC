1 REM^^^^^^^^^^^^^^^^^^^^^^^^^   < Display Sprites       >   vvvvvvvvvvvvvvvvvvvvvvvvv
10 LOMEM:28000:REM Don't clobber the ML routines
20 HGR
30 PA=768:REM Address of sprite parameters
40 HCOLOR=3:FOR Y=0 TO 191:HPLOT 0,Y TO 279,Y:NEXT
100 REM 4x16 Sprite display
110 SH=16:SW=4
120 SA=(96*256):REM $6000
200 REM Even byte display
210 SX=2:SY=8
220 GOSUB 300
230 REM Odd byte display
240 SA=(96*256):SX=SX+9:SY=8
250 GOSUB 300
260 END
300 REM Sprites
310 SW=4
320 FOR I = 1 TO 8:GOSUB 1000:GOSUB 500:NEXT
330 RETURN
500 REM Increase SY and SA
510 SY=SY+SH+1:SA=SA+SW*SH
520 RETURN
1000 REM Show the sprite
1010 AH=INT(SA/256):AL=SA-(AH*256)
1020 POKE PA,SX: POKE PA+1,SY
1030 POKE PA+2,SH: POKE PA+3,SW
1040 POKE PA+4,AL: POKE PA+5,AH
1050 CALL PA+16
1060 RETURN
