@echo off
setlocal enabledelayedexpansion
rem ***************************************************************************************
rem SPLTTING COMPUTERNAME: PCBEG=FIRST 7 CHARACTERS(SalesPC) / PCEND=LAST 2 CHARACTERS(01)
rem CHANGE THIS VARIABLE TO MATCH YOUR NAMING SCHEME.
rem ***************************************************************************************
set PCBEG=%computername:~0,13%
set PCEND=%computername:~13,2%
rem ***************************************************************************************
rem FOR MDTSHARE VARIABLE, REPLACE VALUE WITH IP/HOSTNAME OF YOUR MDT SERVER
rem ***************************************************************************************
set MDTSHARE=\\anc-mdt01\DeploymentShare$\ComputerNames
set LOGPATH=C:\Windows\Temp\DeploymentLogs
set PANTHER=C:\Windows\Panther
set PCNAME=%PCBEG%%PCEND%
rem echo ALLOWING 30 SECONDS FOR PREVIOUS MACHINE TO JOIN DOMAIN BEFORE RUNNING NSLOOKUP
rem timeout /t 30 /nobreak
rem echo.
rem echo PERFORMING NSLOOKUP ON %COMPUTERNAME%
rem echo -------------------------------------
rem timeout /t 4 >nul
rem echo.
rem nslookup %COMPUTERNAME% | find /i "name"
rem IF %ERRORLEVEL% EQU 0 (goto FOUND) else goto NOTFOUND
rem ***************************************************************************************
rem DISPLAY CURRENT COMPUTERNAME AND SET PCNAME VARIABLE
rem ***************************************************************************************
:START
cls
echo CURRENT HOSTNAME IS %COMPUTERNAME%
timeout /t 4 >nul
echo.
goto LOGCHECK
rem ***************************************************************************************
rem DETERMINE IF A FILE NAMED %COMPUTERNAME%.TXT EXISTS IN THE MDT DEPLOYMENT SHARE
rem ***************************************************************************************
:LOGCHECK
If exist %MDTSHARE%\%COMPUTERNAME%.txt (goto FOUND) else goto UNFOUND
rem ***************************************************************************************
rem IF THE FILE EXISTS, TELL THE USER AND PROCEED TO RETRYLOGCHECK STEP
rem ***************************************************************************************
:FOUND
echo A MACHINE WITH THIS HOSTNAME HAS ALREADY BEEN JOINED TO THE DOMAIN
goto RETRYLOGCHECK
rem ***************************************************************************************
rem IF THE FILE DOESN'T EXIST, TELL THE USER AND PROCEED TO CREATELOG STEP
rem ***************************************************************************************
:UNFOUND
echo.
echo NO MACHINE WITH THIS HOSTNAME HAS BEEN JOINED TO THE DOMAIN
timeout /t 4 >nul
goto CREATELOG
rem ***************************************************************************************
rem CREATE A FILE NAMED %PCNAME%.TXT, AND PROCEED TO VERIFY STEP
rem NOTE - SETUPACT.log FILE IS BEING COPIED AND RENAMED TO THE HOSTNAME OF THE MACHINE
rem FOR THE /USER SWITCH, ENTER THE NAME AND PASSWORD OF AN ACCOUNT THAT CAN AUTHENTICATE TO
YOUR NETWORK SHARE
rem ***************************************************************************************
:CREATELOG
net use %MDTSHARE% /user:anc-mdt01\BuildAccount P@ssw0rd1
xcopy %PANTHER%\setupact.log %MDTSHARE% /y /c /z /i
ren %MDTSHARE%\setupact.log %PCNAME%.txt
If exist %MDTSHARE%\%PCNAME%.txt (goto VERIFY) else goto UNFOUND
rem ***************************************************************************************
rem VERIFY THAT %PCNAME%.TXT NOW EXISTS AND EXIT SCRIPT
rem ***************************************************************************************
:VERIFY
echo THE FILE %PCNAME%.txt EXISTS
goto END
rem *************************************************************************************************
rem DISPLAY NEXT AVAILABLE HOSTNAME. IF A FILE BY THAT NAME EXISTS, PROCEED TO TRYAGAIN STEP.
IF IT DOESN'T EXIST, RENAME PC TO THAT NAME
rem *************************************************************************************************
:RETRYLOGCHECK
echo.
echo NEXT AVAILABLE HOSTNAME IS %PCNAME%
timeout /t 2 >nul
echo.
echo LOOKING FOR FILE %PCNAME%.TXT.........
timeout /t 2 >nul
echo.
If exist %MDTSHARE%\%PCNAME%.txt (goto TRYAGAIN) else goto CHANGE
rem ***************************************************************************************
rem INCREASE %PCEND% VALUE BY 1 THEN PROCEED TO RETRYLOGCHECK STEP
rem ***************************************************************************************
:TRYAGAIN
echo.
set /a "PCEND=PCEND+1"
set PCNAME=%PCBEG%0%PCEND%
goto RETRYLOGCHECK
rem ***************************************************************************************
rem RENAME MACHINE TO %PCNAME% THEN PROCEED TO DISPLAY STEP IF SUCCESSFUL
rem ***************************************************************************************
:CHANGE
echo.
echo.
timeout /t 2 >nul
echo ATTEMPTING TO CHANGE HOSTNAME TO %PCNAME%........
timeout /t 2 >nul
echo
wmic computersystem where name='%COMPUTERNAME%' rename %PCNAME% | find /i "return" | find /i "0"
IF !ERRORLEVEL! EQU 0 (goto DISPLAY) else goto ERRORCHECK
rem ***************************************************************************************
rem IF "RETURNVALUE"=5(Access is Denied) THEN INFORM USER TO RUN SCRIPT AS ADMIN and exit
rem ***************************************************************************************
:ERRORCHECK
wmic computersystem where name='%COMPUTERNAME%' rename %PCNAME% | find /i "return" | find /i "5"
IF !ERRORLEVEL! EQU 0 (goto UAC) else goto UHOH
:UAC
wmic computersystem where name='%COMPUTERNAME%' rename %PCNAME% | find /i "return"
echo UNABLE TO RENAME THE MACHINE. PLEASE RUN THIS SCRIPT AS ADMINISTRATOR
goto END
rem ***************************************************************************************
rem IF THERE IS AN ERROR WHILE RENAMING MACHINE, CHANGE COLOR TO RED, INFORM USER & EXIT
rem ***************************************************************************************
:UHOH
color c0
echo.
echo.
echo AN ERROR OCCURRED WHILE TRYING TO RENAME THE MACHINE. PLEASE SEE ERROR LOG
wmic computersystem where name='%COMPUTERNAME%' rename %PCNAME% | find /i "return" >
%SYSTEMDRIVE%\RenameErrorLog.txt
goto END
rem ***************************************************************************************
rem DISPLAY NEW COMPUTERNAME TO USER AND PROCEED TO CREATELOG STEP
rem ***************************************************************************************
:DISPLAY
echo
set REG="reg query
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName /v ComputerName |
find /i "%PCEND%""
for /f "tokens=3 delims= " %%G in ('%REG%') DO echo COMPUTERNAME HAS BEEN CHANGED TO %%G
goto CREATELOG
rem ***************************************************************************************
rem EXIT SCRIPT AND PROCEED TO NEXT STEP IN MDT TASK SEQUENCE
rem ***************************************************************************************
:END
echo PROCEEDING TO NEXT PHASE OF MDT TASK SEQUENCE
rem goto START
exit
