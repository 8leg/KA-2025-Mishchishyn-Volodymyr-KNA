@ECHO OFF
echo.>test.res
echo === input1.nma ===>>test.res
entry input1.nma >>test.res

fc /b test.res test.ok
