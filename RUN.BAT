@ECHO OFF
CD TESTS
TASM cmp.asm
TLINK cmp
del entry.com >nul
copy %1.com entry.com
echo Testing...
TESTIT
