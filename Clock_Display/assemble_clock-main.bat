@echo off

REM md ..\bin
REM md ..\bin\debug
REM md ..\bin\debug\roms

:start
del *.lst
64tass --m65816 clock-main.asm -D TARGET=1 --long-address --flat  -b -o clock-main.bin --list clock-main.lst
64tass --m65816 clock-main.asm -D TARGET=2 --long-address --flat  --intel-hex -o clock-main.hex --list clock-main_hex.lst
if errorlevel 1 goto fail

REM copy clock-main.hex ..\bin\debug\roms
REM copy clock-main.lst ..\bin\debug\roms

:fail
choice /m "Try again?"
if errorlevel 2 goto end
goto start

:end
echo END OF LINE
