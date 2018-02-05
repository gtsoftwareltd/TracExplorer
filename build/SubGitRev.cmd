@echo off
setlocal

if "%2" == "" (
  echo Usage: SubGitRev WorkingCopyPath [SrcVersionFile DstVersionFile]
  echo.
  echo Params:
  echo WorkingCopyPath    :   path to a Subversion working copy.
  echo SrcVersionFile     :   path to a template file containing keywords.
  echo DstVersionFile     :   path to save the resulting parsed file.
  echo.
  echo SrcVersionFile is then copied to DstVersionFile but the placeholders
  echo are replaced with information about the working copy as follows:
  echo.
  echo ${REV_COUNT}     Revision number
  echo ${REV_DATE}      Revision date     
  echo ${REV_HASH}      Revision hash
  echo ${REV_URL}       Repository URL
  echo ${REV_DIRTY}     'M' when there are any changes in current worktree
  echo ${REV_STAGED}    'S' when there are any staged uncommited changes
  echo ${APP_REV}       ${REV_DIRTY}{REV_STAGED}${REV_COUNT}-${REV_HASH}
  
  exit /b 1
)

PATH=%SystemRoot%\Sysnative;%PATH%
FOR /F "tokens=2*" %%A IN ('REG.EXE QUERY "HKLM\Software\GitForWindows" /V "InstallPath" 2^>NUL ^| FIND "REG_SZ"') DO SET GITPATH=%%B

"%GITPATH%\bin\git" -C %1 rev-list HEAD --count > tmp.tmp 2>nul
set /p REV_COUNT=<tmp.tmp

if "%REV_COUNT%" == "" (
  echo Not int GIT repository
  del tmp.tmp
  endlocal
  exit /b 1
)

"%GITPATH%\bin\git" -C %1 log -1 --date=iso-local --pretty=format:%%cd > tmp.tmp
set /p REV_DATE=<tmp.tmp

"%GITPATH%\bin\git" -C %1 log -1 --pretty=format:%%h --abbrev=8 > tmp.tmp
set /p REV_HASH=<tmp.tmp

"%GITPATH%\bin\git" -C %1 ls-remote --get-url > tmp.tmp
set /p REV_URL=<tmp.tmp

del tmp.tmp

"%GITPATH%\bin\git" -C %1 diff --exit-code --quiet
if %errorlevel% == 0 (
  set REV_DIRTY=
) else (
  set REV_DIRTY=M
)

"%GITPATH%\bin\git" -C %1 diff-index --cached --quiet HEAD
if %errorlevel% == 0 (
  set REV_STAGED=
) else (
  set REV_STAGED=S
)

set APP_REV=%REV_DIRTY%%REV_STAGED%%REV_COUNT%-%REV_HASH%

echo Revision: "%APP_REV%"

"%GITPATH%\bin\sh" -c envsubst < %2 > tmp.tmp

:: Update file only when changed
fc "%3" tmp.tmp > nul 2>nul
if errorlevel 1 (
  copy tmp.tmp "%3" > nul
)

del tmp.tmp
endlocal
exit /b 0
