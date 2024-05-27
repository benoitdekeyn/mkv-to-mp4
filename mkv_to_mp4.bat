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


:input_path
echo.
set /p input_path_file=Enter the file or folder path : 
echo.
REM Check if the last character is a backslash and remove it
if "%input_path_file:~-1%"=="\" (
    set input_path_file=%input_path_file:~0,-1%
)

REM Check if the folder or file is founded and correct
IF EXIST "%input_path_file%" (
    IF EXIST "%input_path_file%\*" (
        REM This is a directory.
        set files_count=0
        for /f %%A in ('dir /b "%input_path_file%\*.mkv" 2^>nul ^| findstr /r /v "^$" ^| find /c /v ""') do set files_count=%%A
        if !files_count!==0 (
            echo There is no .mkv file in this folder, please try something else.
            goto input_path
        )
        set current_file=%input_path_file%\*.mkv
        echo !files_count! .mkv files found in this folder.
    ) ELSE (
        REM This is a file.
        IF "%input_path_file:~-4%" NEQ ".mkv" (
            echo This is not a .mkv file, please try something else.
            goto input_path
        )
        set current_file=%input_path_file%
        echo 1 file selected
    )
) ELSE (
    echo Can't find this folder or file, please try something else.
    goto input_path
)
    
REM Choose the right audio and subtitle streams

REM Detect the number of audio and subtitle streams
for /f %%A in ('ffmpeg -i "%current_file%" 2^>^&1 ^| findstr /r "Stream.*Audio" ^| find /c /v ""') do set audio_count=%%A
for /f %%A in ('ffmpeg -i "%current_file%" 2^>^&1 ^| findstr /r "Stream.*Subtitle" ^| find /c /v ""') do set sub_count=%%A

REM check if all the files of a folder have the same streams (do it later)
echo.
echo There are %audio_count% audio and %sub_count% subtitle streams in your mkv file(s)

REM display the audio and subtitle streams with their ID and Title
echo Each audio or subtitle stream have an ID (1, 2, 3...) and a language : 
for /f "delims=" %%A in ('ffmpeg -i "%current_file%" 2^>^&1 ^| findstr /r "Stream.*Audio | Stream.*Subtitle"') do (
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
set /p audio_id=Choose the stream ID for audio track (1, 2, 3...) : 
set /p sub_id=Choose the stream ID for subtitles (1, 2, 3...) : 

