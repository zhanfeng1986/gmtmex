@echo off
REM ----------------------------------------------------
REM
REM	Copyright (c) 1991-2015 by P. Wessel, W. H. F. Smith, R. Scharroo, and J. Luis
REM	See LICENSE.TXT file for copying and redistribution conditions.
REM
REM	This program is free software; you can redistribute it and/or modify
REM	it under the terms of the GNU Lesser General Public License as published by
REM	the Free Software Foundation; version 3 or any later version.
REM
REM	This program is distributed in the hope that it will be useful,
REM	but WITHOUT ANY WARRANTY; without even the implied warranty of
REM	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM	GNU Lesser General Public License for more details.
REM
REM	Contact info: gmt.soest.hawaii.edu
REM --------------------------------------------------------------------
REM --------------------------------------------------------------------------------------
REM
REM This is a compile batch that builds the GMTMEX. Contrary to the 'mex' command it doesn't
REM need you to setup a compiler within MATLAB, which means you can use any of the MS or
REM Intel compilers (a luxury that you don't have with the 'mex' command).
REM
REM If a WIN64 version is targeted than both GMT & netCDF Libs must have been build in 64-bits as well.
REM
REM
REM Usage: open the command window and run this batch from there.
REM 	   NOTE: you must make some edits to the setup below.
REM
REM --------------------------------------------------------------------------------------

REM ------------- Set the compiler (set to 'icl' to use the Intel compiler) --------------
SET CC=cl
REM ------------- Set the Visual Studio version (VC12 (VS2013), VC14 (VS2015) or VC15 (VS2017))
SET VC="VC12"
REM ------------- Set it to 32 or 64 to build under 64-bits or 32-bits respectively.
SET BITS=64
REM ------------- Set to 5 or 6 depending on the GMT version
SET MAJOR_VER="6"
REM ------------- Set to "yes" if you want to build a debug version
SET DEBUG="no"
REM ------------- If set to "yes", linkage is done against ML6.5 Libs
SET R13="no"
REM --------------------------------------------------------------------------------------

IF %R13%=="yes" SET BITS=32

REM -------------- Set GMT & NetCDF lib and include ----------------------------
IF %VC% == "VC12" (
SET  GMT_LIB=c:\progs_cygw\GMTdev\gmt5\compileds\gmt%MAJOR_VER%\VC12_%BITS%\lib\gmt.lib
SET  GMT_INC=c:\progs_cygw\GMTdev\gmt5\compileds\gmt%MAJOR_VER%\VC12_%BITS%\include\gmt
) ELSE (
SET  GMT_LIB=c:\progs_cygw\GMTdev\gmt5\compileds\gmt%MAJOR_VER%\VC14_%BITS%\lib\gmt.lib
SET  GMT_INC=c:\progs_cygw\GMTdev\gmt5\compileds\gmt%MAJOR_VER%\VC14_%BITS%\include\gmt
)
REM ----------------------------------------------------------------------------

REM ------------------ Sets the MATLAB libs and include path ----------------------------
IF %R13%=="yes" (

SET MATLIB=C:\SVN\pracompila\MAT65\lib\win32\microsoft
SET MATINC=C:\SVN\pracompila\MAT65\include
SET _MX_COMPAT=
SET MEX_EXT="dll"

) ELSE (

IF %BITS%==64 (
SET MATLIB=C:\SVN\pracompila\ML2010a_w64\lib\win64\microsoft
SET MATINC=C:\SVN\pracompila\ML2010a_w64\include
SET _MX_COMPAT=-DMX_COMPAT_32
SET MEX_EXT="mexw64"

) ELSE (

SET MATLIB=C:\SVN\pracompila\ML2009b_w32\lib\win32\microsoft
SET MATINC=C:\SVN\pracompila\ML2009b_w32\include
SET _MX_COMPAT=-DMX_COMPAT_32
SET MEX_EXT="mexw32"
) )

REM -------------- Pick up the right compiler ----------------------------------
IF %BITS%==64 (

IF %VC%=="VC12" call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64
IF %VC%=="VC14" call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64
IF %VC%=="VC15" call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat" amd64

) ELSE (

IF %VC%=="VC12" call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86
IF %VC%=="VC14" call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86
IF %VC%=="VC15" call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars32.bat" x86

)

REM ____________________________________________________________________________
REM ___________________ STOP EDITING HERE ______________________________________


SET LDEBUG=
IF %DEBUG%=="yes" SET LDEBUG=/debug

SET COMPFLAGS=/Zp8 /GR /EHs /D_CRT_SECURE_NO_DEPRECATE /D_SCL_SECURE_NO_DEPRECATE /D_SECURE_SCL=0 /DMATLAB_MEX_FILE -DGMT_MAJOR_VERSION=%MAJOR_VER% /nologo /MD
SET OPTIMFLAGS=/Ox /Oy- /DNDEBUG
IF %DEBUG%=="yes" SET OPTIMFLAGS=/Z7

IF %BITS%==64 SET arc=X64
IF %BITS%==32 SET arc=X86
SET LINKFLAGS=/dll /export:mexFunction /LIBPATH:%MATLIB% libmx.lib libmex.lib libmat.lib /MACHINE:%arc% kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /incremental:NO %LDEBUG%

REM -------------------------------------------------------------------------------------------------------
%CC% /c -DWIN32 %COMPFLAGS% -W4 -I%MATINC% -I%GMT_INC% %OPTIMFLAGS% %_MX_COMPAT% -DLIBRARY_EXPORTS -DGMT_MATLAB gmtmex_parser.c gmtmex.c
link  /out:"gmtmex.%MEX_EXT%" %LINKFLAGS% %GMT_LIB% /implib:templib.x gmtmex_parser.obj gmtmex.obj

del *.obj *.exp templib.x

pause
