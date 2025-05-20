@echo off
setlocal enabledelayedexpansion

set "ADOBE_DIR=%APPDATA%\Adobe\CEP\extensions"
set "CUSTOM_DIR=C:\path\to\your\custom\extensions"

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if %errorlevel% neq 0 (
    echo Administrator rights required
    echo Please run as administrator
    pause
    exit /b 1
)

:MENU
cls
echo ===================================
echo  ADOBE CEP SYMLINK MANAGEMENT
echo ===================================
echo.
echo  1. Create links for each folder
echo  2. Check status
echo  3. Remove links to custom folders
echo  4. Exit
echo.
echo  Source (custom)   %CUSTOM_DIR%
echo  Target (Adobe)    %ADOBE_DIR%
echo.
echo ===================================

set choice=
set /p choice=Choice [1-4]^> 

if "%choice%"=="1" goto MAKE_INDIVIDUAL_LINKS
if "%choice%"=="2" goto CHECK
if "%choice%"=="3" goto REMOVE
if "%choice%"=="4" goto EXIT

echo Invalid choice
timeout /t 2 >nul
goto MENU

:MAKE_SYMLINK
cls
echo CREATING SYMBOLIC LINK
echo.

if not exist "%CUSTOM_DIR%" mkdir "%CUSTOM_DIR%" 2>nul

if exist "%ADOBE_DIR%" (
    set link_type=NONE
    >nul 2>nul dir "%ADOBE_DIR%" | findstr "<SYMLINK" >nul && set "link_type=SYMLINK"
    >nul 2>nul dir "%ADOBE_DIR%" | findstr "<JUNCTION" >nul && set "link_type=JUNCTION"
    
    if "!link_type!"=="SYMLINK" (
        echo Symbolic link already exists
        set delete=
        set /p delete=Delete link? [y/n]^> 
        
        if /i "!delete!"=="y" (
            rmdir "%ADOBE_DIR%" >nul 2>nul
        ) else (
            echo Canceled
            pause
            goto MENU
        )
    ) else if "!link_type!"=="JUNCTION" (
        echo Junction link already exists
        set delete=
        set /p delete=Delete link? [y/n]^> 
        
        if /i "!delete!"=="y" (
            rmdir "%ADOBE_DIR%" >nul 2>nul
        ) else (
            echo Canceled
            pause
            goto MENU
        )
    ) else (
        echo WARNING
        echo This is a regular directory
        echo To create a link, the path must be freed
        echo.
        echo 1. Move content to custom directory
        echo 2. Delete directory
        echo 3. Cancel
        echo.
        set action=
        set /p action=Choose action [1-3]^> 
        
        if "!action!"=="1" (
            if not exist "%CUSTOM_DIR%" mkdir "%CUSTOM_DIR%" 2>nul
            echo Moving files...
            xcopy "%ADOBE_DIR%\*" "%CUSTOM_DIR%\" /E /I /H /Y >nul
            rmdir /s /q "%ADOBE_DIR%" >nul 2>nul
            echo Files moved
        ) else if "!action!"=="2" (
            echo WARNING
            echo All files will be deleted
            set confirm=
            set /p confirm=Continue? [y/n]^> 
            
            if /i "!confirm!"=="y" (
                rmdir /s /q "%ADOBE_DIR%" >nul 2>nul
            ) else (
                echo Canceled
                pause
                goto MENU
            )
        ) else (
            echo Canceled
            pause
            goto MENU
        )
    )
)

if not exist "%APPDATA%\Adobe\CEP" (
    mkdir "%APPDATA%\Adobe\CEP" 2>nul
)

mklink /D "%ADOBE_DIR%" "%CUSTOM_DIR%" >nul

if %errorlevel% equ 0 (
    echo Success
) else (
    echo Error
)

pause
goto MENU

:REMOVE
cls
echo REMOVING LINKS TO CUSTOM FOLDERS
echo.

if not exist "%ADOBE_DIR%" (
    echo Adobe directory does not exist
    pause
    goto MENU
)

if not exist "%CUSTOM_DIR%" (
    echo Custom directory does not exist
    pause
    goto MENU
)

echo Searching for links to custom folders...
echo.

set found_links=0
set removed_links=0

set "user_folders="
for /d %%d in ("%CUSTOM_DIR%\*") do (
    set "folder_name=%%~nxd"
    set "user_folders=!user_folders! %%~nxd"
)

if "!user_folders!"=="" (
    echo No folders in custom directory
    pause
    goto MENU
)

echo Found custom folders:
for %%f in (!user_folders!) do (
    echo - %%f
)
echo.

echo Checking links in Adobe directory...
echo.

for /d %%d in ("%ADOBE_DIR%\*") do (
    set "folder_name=%%~nxd"
    set "is_user_folder=0"
    
    for %%f in (!user_folders!) do (
        if "!folder_name!"=="%%f" set "is_user_folder=1"
    )
    
    if !is_user_folder!==1 (
        set "link_type=NONE"
        
        fsutil reparsepoint query "%%d" >nul 2>&1
        if !errorlevel! equ 0 (
            set "link_type=SYMLINK"
        )
        
        if "!link_type!"=="SYMLINK" (
            echo Removing symbolic link: !folder_name!
            rmdir "%%d" >nul 2>nul
            set /a removed_links+=1
        ) else (
            echo Skipping regular directory: !folder_name!
        )
        set /a found_links+=1
    )
)

if !found_links!==0 (
    echo No links to custom folders found
) else (
    echo.
    echo Total links found: !found_links!
    echo Links removed: !removed_links!
)

pause
goto MENU

:CHECK
cls
echo STATUS CHECK
echo.

if not exist "%ADOBE_DIR%" (
    echo Adobe directory does not exist
    pause
    goto MENU
)

if not exist "%CUSTOM_DIR%" (
    echo Custom directory does not exist
    pause
    goto MENU
)

echo Main directories:
echo - Custom: %CUSTOM_DIR%
echo - Adobe: %ADOBE_DIR%

set link_type=NONE
set link_info=
set link_target=

fsutil reparsepoint query "%ADOBE_DIR%" >nul 2>&1
if !errorlevel! equ 0 (
    set "link_type=SYMLINK"
    for /f "tokens=*" %%a in ('dir "%ADOBE_DIR%" ^| findstr "<SYMLINK"') do set "link_info=%%a"
    if "!link_info!"=="" (
        for /f "tokens=*" %%a in ('dir "%ADOBE_DIR%" ^| findstr "<JUNCTION"') do set "link_info=%%a"
    )
    
    for /f "tokens=* delims=" %%I in ('dir /al "%ADOBE_DIR%\.." ^| findstr "%ADOBE_DIR:\=\\%"') do (
        set "full_link=%%I"
        set "link_target=!full_link:*[=!"
        set "link_target=!link_target:]=!"
    )
)

if "!link_type!"=="SYMLINK" (
    echo.
    echo Adobe directory status:
    echo Type: Symbolic link
    echo Points to: !link_target!
)

echo.
echo ===================================
echo Subfolders in custom directory:
echo ===================================
set subfolder_count=0
for /d %%d in ("%CUSTOM_DIR%\*") do (
    set "folder_name=%%~nxd"
    echo.
    echo Folder: !folder_name!
    echo Full path: %%~fd
    set /a subfolder_count+=1
)

if !subfolder_count!==0 (
    echo.
    echo No subfolders
)

echo.
echo ===================================
echo Subfolders in Adobe directory:
echo ===================================
set subfolder_count=0
for /d %%d in ("%ADOBE_DIR%\*") do (
    set "folder_name=%%~nxd"
    set "folder_type=Regular directory"
    set "folder_target="
    
    fsutil reparsepoint query "%%d" >nul 2>&1
    if !errorlevel! equ 0 (
        set "folder_type=Symbolic link"
        
        for /f "tokens=* delims=" %%I in ('dir /al "%%d\.." ^| findstr "%%~nxd"') do (
            set "full_link=%%I"
            set "folder_target=!full_link:*[=!"
            set "folder_target=!folder_target:]=!"
        )
        
        if "!folder_target!"=="" (
            for /f "tokens=* delims=" %%J in ('fsutil reparsepoint query "%%d" ^| findstr "Print Name"') do (
                set "folder_target=%%J"
                set "folder_target=!folder_target:*: =!"
            )
            
            if "!folder_target!"=="" (
                set "folder_target=Unknown"
            )
        )
    )
    
    echo.
    echo Folder: !folder_name!
    echo Type: !folder_type!
    echo Full path: %%~fd
    if "!folder_type!"=="Symbolic link" echo Points to: !folder_target!
    set /a subfolder_count+=1
)

if !subfolder_count!==0 (
    echo.
    echo No subfolders
)

pause
goto MENU

:MAKE_INDIVIDUAL_LINKS
cls
echo CREATING INDIVIDUAL SYMBOLIC LINKS
echo.

if not exist "%CUSTOM_DIR%" (
    echo Custom directory does not exist. Creating...
    mkdir "%CUSTOM_DIR%" 2>nul
)

if not exist "%ADOBE_DIR%" (
    echo Adobe directory does not exist. Creating...
    mkdir "%APPDATA%\Adobe\CEP" 2>nul
    mkdir "%ADOBE_DIR%" 2>nul
)

echo Creating symbolic links for each folder...
echo.

set created_links=0
set skipped_links=0

for /d %%d in ("%CUSTOM_DIR%\*") do (
    set "folder_name=%%~nxd"
    set "target_link=%ADOBE_DIR%\!folder_name!"
    
    if exist "!target_link!" (
        set link_type=NONE
        >nul 2>nul dir "!target_link!" | findstr "<SYMLINK" >nul && set "link_type=SYMLINK"
        >nul 2>nul dir "!target_link!" | findstr "<JUNCTION" >nul && set "link_type=JUNCTION"
        
        if "!link_type!"=="SYMLINK" (
            echo Symbolic link already exists: !folder_name!
            set /a skipped_links+=1
        ) else if "!link_type!"=="JUNCTION" (
            echo Junction link already exists: !folder_name!
            set /a skipped_links+=1
        ) else (
            echo Regular directory found: !folder_name!
            set replace=
            set /p replace=Replace with symbolic link? [y/n]^> 
            
            if /i "!replace!"=="y" (
                rmdir /s /q "!target_link!" >nul 2>nul
                mklink /D "!target_link!" "%%d" >nul
                if !errorlevel! equ 0 (
                    echo Created symbolic link: !folder_name!
                    set /a created_links+=1
                ) else (
                    echo Error creating link: !folder_name!
                )
            ) else (
                echo Skipped: !folder_name!
                set /a skipped_links+=1
            )
        )
    ) else (
        mklink /D "!target_link!" "%%d" >nul
        if !errorlevel! equ 0 (
            echo Created symbolic link: !folder_name!
            set /a created_links+=1
        ) else (
            echo Error creating link: !folder_name!
        )
    )
)

echo.
echo Total links created: !created_links!
echo Skipped: !skipped_links!

if !created_links!==0 (
    if !skipped_links!==0 (
        echo No folders in custom directory
    )
)

pause
goto MENU

:EXIT
cls
echo Exit
exit /b 0 