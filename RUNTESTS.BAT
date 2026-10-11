@echo off
rem Run the UXCBASIC tests in tests\, headless. BUILD.BAT builds UXC.
rem   RUNTESTS           run them all
rem   RUNTESTS SKEL ...  run only the tests named
setlocal
set PY=C:\Users\Admin\AppData\Local\Programs\Python\Python313\python.exe
cd /d "%~dp0"
if not exist "build\UXC.PRG" goto missing
"%PY%" tests.py %*
pause
goto :eof
:missing
echo RUNTESTS: no build\UXC.PRG. Run BUILD first.
pause
