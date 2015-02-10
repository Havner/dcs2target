rem set DCS_FOLDER=C:\Games\DCS
set DCS_FOLDER=..
set LUA_CPATH=%DCS_FOLDER%\bin\lua-?.dll;%DCS_FOLDER%\bin\?.dll
%DCS_FOLDER%\bin\luae.exe dcs2target_parser.lua %DCS_FOLDER% %1 %2 %3 %4 %5 %6 %7 %8 %9
