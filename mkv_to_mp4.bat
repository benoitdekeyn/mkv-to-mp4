
@echo off
setlocal enabledelayedexpansion

echo.
echo This program is a .mkv to .mp4 converter with subtitles burner onto the video itself.
echo It uses ffmpeg to process the files, so you first need to install it on your computer.
echo The final video .mp4 will include the subtitles in the original pictures themselves.
echo.
echo.

REM Check if ffmpeg is installed (to do later)

echo So first, you need to ensure that all the files you want to convert have the same streams (audio, video, subtitles)
echo If you want to convert a file, write the relative or absolute path with the file name and extension. (ex : C:\Users\John\Videos\myvideo.mkv)
echo If you want to convert a set of files, just write the relative or absolute path (ex : C:\Users\John\Videos)
echo If you want to convert files of all the sub-folders, type *** at the end of the path (ex : C:\Users\John\Videos\***)

set current_directory=%cd%

:input_path
cd %current_directory%

echo.

set /p input_path=Enter the file or folder path : 
set "folder_path="
set is_1_file=0

REM Check if the last character is a backslash and remove it
if "%input_path:~-1%"=="\" (
    set input_path=%input_path:~0,-1%
)

REM Check if the input path is correct, and if it is a file or a folder
if exist "%input_path%" (

    if exist "%input_path%\*" (
        REM This is a folder
        set is_1_file=0
        set folder_path=%input_path%

    ) else (
        REM This is a file
        set is_1_file=1
        REM get the path of the file and remove the backslash
        for %%A in ("%input_path%") do set folder_path=%%~dpA
        set folder_path=!folder_path:~0,-1!
    )

) else (
    echo Can't find this folder or file, please try something else.
    goto input_path
)

REM Change the current directory to the folder path, to use easily relative paths
cd %folder_path%



REM Now, we'll check the mkv files, if there is and if they have the same streams



REM Check if there are .mkv files in the folder or if the file is a .mkv file

REM Here the future list of names of the mkv files to convert
set "file_names="
set files_count=0

if %is_1_file%==1 (

    if "%input_path:~-4%" NEQ ".mkv" (
        echo This is not a .mkv file, please try something else.
        goto input_path
    )
    REM We add only the filename and extension to the list of file names
    for %%A in ("%input_path%") do set "file_names=!file_names!%%~nxA;"
    set files_count=1

) else (
    REM Loop through all the .mkv files in the folder
    for %%A in (*.mkv) do (
        REM We add only the filename and extension to the list of file names
        set "file_names=!file_names!%%~nxA;"
        set /a files_count+=1
    )
    if !files_count!==0 (
        echo There is no .mkv file in this folder, please try something else.
        goto input_path
    )
)
REM remove the last semicolon
set "file_names=!file_names:~0,-1!"

echo.
echo %files_count% files selected : 
for /f "delims=;" %%F in ("!file_names!") do (
    echo - %%F
)
echo.

REM Now we are in the folder path, and have the list of file names and the number of files to convert

REM Choose the right audio and subtitle streams

set audio_count=0
set sub_count=0

REM Put into first_file, the first file of the list
set "first_file="
for /f "tokens=1 delims=;" %%A in ("!file_names!") do set first_file=%%A


REM Get the number of audio and subtitle streams in the first file
for /f %%A in ('ffmpeg -i "%first_file%" 2^>^&1 ^| findstr /r "Stream.*Audio" ^| find /c /v ""') do set audio_count=%%A
for /f %%A in ('ffmpeg -i "%first_file%" 2^>^&1 ^| findstr /r "Stream.*Subtitle" ^| find /c /v ""') do set sub_count=%%A

if !audio_count! EQU 0 (
    echo There is no audio stream in %first_file%, please try with another set of files.
    goto input_path
)

if !sub_count! EQU 0 (
    echo There is no subtitle stream in %first_file%, please try with another set of files.
    goto input_path
)

REM if we have several files to compare the compatibility of streams, we loop through the files
if is_1_file==0 (
    for /f "delims=;" %%F in ("!file_names!") do (
        for /f %%A in ('ffmpeg -i "%%F" 2^>^&1 ^| findstr /r "Stream.*Audio" ^| find /c /v ""') do set temp_audio_count=%%A
        for /f %%A in ('ffmpeg -i "%%F" 2^>^&1 ^| findstr /r "Stream.*Subtitle" ^| find /c /v ""') do set temp_sub_count=%%A
        if !temp_audio_count! NEQ !audio_count! (
            echo The audio streams are not the same in your .mkv files, please try with another set of files.
            echo There are !temp_audio_count! audio streams in %%F, whereas %fisrt_file% have !audio_count! audio streams
            goto input_path
        ) else (
            if !temp_sub_count! NEQ !sub_count! (
                echo There are !temp_sub_count! subtitle streams in %%F, whereas %fisrt_file% have !sub_count! subtitle streams
                goto input_path
            )
        )
    )
    echo There are !audio_count! audio and !sub_count! subtitle streams in your mkv file
) else (
    echo There are !audio_count! audio and !sub_count! subtitle streams in your mkv files.
)


REM display the audio and subtitle streams with their ID and Title
echo Each audio or subtitle stream have an ID (1, 2, 3...) and a language : 

for /f "delims=" %%A in ('ffmpeg -i "%first_file%" 2^>^&1 ^| findstr /r "Stream.*Audio | Stream.*Subtitle"') do (
    for /f "tokens=2,3,4 delims=:()" %%B in ("%%A") do (
        set "lang=%%C"
        if "%%C"=="fre" (set "lang=French")
        if "%%C"=="eng" (set "lang=English")
        if "%%C"=="ger" (set "lang=German")
        if "%%C"=="ita" (set "lang=Italian")
        if "%%C"=="spa" (set "lang=Spanish")
        if "%%C"=="dut" (set "lang=Dutch")
        if "%%C"=="por" (set "lang=Portuguese")
        if "%%C"=="rus" (set "lang=Russian")
        if "%%C"=="jpn" (set "lang=Japanese")
        if "%%C"=="chi" (set "lang=Chinese")
        if "%%C"=="kor" (set "lang=Korean")
        echo Stream %%B: %%D - !lang!
    )
)
echo.

set /p audio_id=Choose the stream ID for audio (1, 2, 3...) : 
set /p sub_id=Choose the stream ID for subtitles (1, 2, 3...) : 

REM Now we will convert the files

REM First step is to extract the subtitles into a .srt file for each file of the list
REM The srt files will be in a subfolder and named as the original file with a .srt instead of .mkv

REM Create the subfolder
set "sub_folder=subtitles"
if not exist "%sub_folder%" mkdir "%sub_folder%"

set counter=0
REM Loop through the list of files to extract the subtitles
for /f "delims=;" %%A in ("!file_names!") do (
    set /a counter+=1
    set "current_mkv_file=%%~nxA"
    set "current_sub_file=%sub_folder%\%%~nA.srt"
    powershell -Command "Write-Host 'Extraction of subtitles from !current_mkv_file! to !current_sub_file! :' -ForegroundColor Blue"
    ffmpeg -i "!current_mkv_file!" -map 0:%sub_id% "!current_sub_file!"
    if exist !current_sub_file! (
        powershell -Command "Write-Host '############ %%~nA.srt successfully created (!counter!/%files_count%) ############' -ForegroundColor Green"
    ) else (
        powershell -Command "Write-Host 'Failed to create !current_sub_file!' -ForegroundColor Red" 
        pause
        exit
    )
)

echo.
echo.
powershell -Command "Write-Host '---------------- ALL SUBTITLES SUCCESSFULLY EXTRACTED ----------------' -ForegroundColor Green"
echo.
echo.

REM Now we will convert the files to .mp4 with the subtitles burned into the video

REM Create the subfolder
set "mp4_folder=mp4 converted"

if exist "%mp4_folder%" (
   powershell -Command "Write-Host 'The folder "%mp4_folder%" already exists, the files will be overwritten.' -ForegroundColor Yellow"
    set /p "overwrite=Do you want to continue ? (y/n) : "
    if /i "%overwrite%" NEQ "y" (
        rmdir /s /q "%mp4_folder%"
        mkdir "%mp4_folder%"
    ) else (
        powershell -Command "Write-Host 'Processus aborted by the user.' -ForegroundColor Red"
        pause
        goto input_path
    )
) else (
    mkdir "%mp4_folder%"
)

set counter=0
REM Loop through the list of files to convert them
for /f "delims=;" %%A in ("!file_names!") do (
    set /a counter+=1
    set "current_mkv_file=%%~nxA"
    set "current_mp4_file=%mp4_folder%\%%~nA.mp4"
    powershell -Command "Write-Host 'Creation of !current_mp4_file! :' -ForegroundColor Blue"
    ffmpeg -i "!current_mkv_file!" -map 0:v -map 0:%audio_id% -vf subtitles="!sub_folder!/%%~nA.srt" "!current_mp4_file!"
    if exist !current_mp4_file! (
        echo.
        powershell -Command "Write-Host '############ %%~nxA successfully converted (!counter!/%files_count%) ############' -ForegroundColor Green"
        echo.
    ) else (
        powershell -Command "Write-Host 'Failed to create !current_mp4_file! ' -ForegroundColor Red"
        pause
        exit
    )
)

REM delete the subtitles folder
rmdir /s /q "%sub_folder%"


echo.
echo.
powershell -Command "Write-Host '---------------------- ALL FILES SUCCESSFULLY CONVERTED ------------------------' -ForegroundColor Green"
echo.
echo.


REM Open the folder with the converted files
explorer "%mp4_folder%"

pause
