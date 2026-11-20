@echo off
chcp 65001 >nul
setlocal EnableExtensions
title FARO .fls в E57 для программы Скан
rem ================================================================
rem  FARO .fls  ->  E57  (через бесплатный CloudCompare)
rem  Как пользоваться:
rem   1) положите этот файл в папку со сканами (где Scan_001.fls ...)
rem      и запустите двойным щелчком,
rem      ИЛИ перетащите папку со сканами прямо на этот файл.
rem   2) готовые .e57 появятся в подпапке _E57 рядом со сканами.
rem  Уже сконвертированные сканы пропускаются - можно запускать повторно.
rem  При запуске выбирается плотность:
rem   1 - прореживание до 1 см (по умолчанию; Скану для сшивки и плана хватает),
rem       результат в подпапке _E57;
rem   2 - полная плотность FARO, без прореживания (для выгрузки единого
rem       сшитого облака во всех точках; файлы в разы больше),
rem       результат в подпапке _E57_full.
rem  Режим можно задать и вторым параметром: fls_to_e57.bat "папка" full
rem ================================================================

set "SRC=%~dp0"
if not "%~1"=="" set "SRC=%~f1\"
rem --- плотность: 1 - до 1 см, 2 - полная ---
set "MODE="
if /i "%~2"=="full" set "MODE=2"
if /i "%~2"=="1cm" set "MODE=1"
if not defined MODE (
  echo.
  echo  Плотность точек:
  echo    1 - прореживать до 1 см  ^(быстро, для сшивки и плана^)
  echo    2 - полная плотность FARO ^(все точки, файлы в разы больше^)
  choice /c 12 /n /t 15 /d 1 /m " Выберите 1 или 2 [через 15 с - 1]: "
  if errorlevel 2 ( set "MODE=2" ) else ( set "MODE=1" )
)
if "%MODE%"=="2" (
  set "DST=%SRC%_E57_full"
  set "SUBS="
  set "DENS=полная, без прореживания"
) else (
  set "DST=%SRC%_E57"
  set "SUBS=-SS SPATIAL 0.01"
  set "DENS=до 1 см"
)
set "TMP1=%SystemDrive%\E57tmp"
set "LOG=%DST%\_log.txt"

rem --- ищем CloudCompare ---
set "CC="
for %%P in ("%ProgramFiles%\CloudCompare\CloudCompare.exe" "%ProgramFiles(x86)%\CloudCompare\CloudCompare.exe" "C:\CloudCompare\CloudCompare.exe" "D:\CloudCompare\CloudCompare.exe" "E:\CloudCompare\CloudCompare.exe" "%LOCALAPPDATA%\Programs\CloudCompare\CloudCompare.exe" "%~dp0CloudCompare\CloudCompare.exe") do if not defined CC if exist %%P set "CC=%%~P"
if not defined CC for /f "delims=" %%X in ('where CloudCompare.exe 2^>nul') do if not defined CC set "CC=%%X"
if not defined CC (
  echo.
  echo  Не найден CloudCompare.
  echo  Установите его бесплатно: https://www.cloudcompare.org/release/  ^(Windows installer, 64 bit^)
  echo  - в установщике оставьте все плагины включёнными ^(нужен плагин FARO^).
  echo  Или вставьте сюда полный путь к CloudCompare.exe и нажмите Enter:
  set /p "CC=> "
)
set "CC=%CC:"=%"
if not exist "%CC%" ( echo  Файл не найден: %CC% & pause & exit /b 1 )
echo  CloudCompare: %CC%
echo  Сканы:        %SRC%
echo  Результат:    %DST%
echo  Плотность:    %DENS%
echo.

if not exist "%DST%" mkdir "%DST%"
if not exist "%TMP1%" mkdir "%TMP1%"
set /a OK=0, SKIP=0, ERR=0, N=0

rem FARO хранит скан либо папкой «Scan_001.fls», либо одним файлом - берём оба варианта
for /d %%D in ("%SRC%*.fls") do call :one "%%~fD" "%%~nD"
for %%F in ("%SRC%*.fls") do if not exist "%%~fF\" call :one "%%~fF" "%%~nF"

echo.
echo  ============================================
if %N%==0 echo  В папке нет сканов .fls: %SRC%
echo  Готово. Сконвертировано: %OK%, уже были: %SKIP%, ошибок: %ERR%
echo  Файлы E57: %DST%
if not %ERR%==0 echo  Подробности ошибок: %LOG%
echo  ============================================
rd "%TMP1%" 2>nul
pause
exit /b 0

:one
set /a N+=1
set "IN=%~1"
set "NAME=%~2"
if exist "%DST%\%NAME%.e57" ( echo  [уже есть] %NAME% & set /a SKIP+=1 & goto :eof )
rem если внутри папки-скана есть одноимённый .fls - открываем его
if exist "%IN%\%NAME%.fls" if not exist "%IN%\%NAME%.fls\" set "IN=%IN%\%NAME%.fls"
echo  [%time:~0,8%] %NAME% ...
>>"%LOG%" echo ===== %NAME% =====
if exist "%TMP1%\%NAME%.e57" del /q "%TMP1%\%NAME%.e57"
rem пути с пробелами CloudCompare сохраняет криво - пишем во временную папку без пробелов
"%CC%" -SILENT -AUTO_SAVE OFF -O "%IN%" %SUBS% -C_EXPORT_FMT E57 -NO_TIMESTAMP -SAVE_CLOUDS FILE "%TMP1%\%NAME%.e57" >>"%LOG%" 2>&1
if exist "%TMP1%\%NAME%.e57" (
  move /y "%TMP1%\%NAME%.e57" "%DST%\%NAME%.e57" >nul
  echo              готово
  set /a OK+=1
) else (
  echo              ОШИБКА - см. _log.txt в папке результата
  set /a ERR+=1
)
goto :eof
