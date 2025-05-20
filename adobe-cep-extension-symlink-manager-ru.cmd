@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "ADOBE_DIR=%APPDATA%\Adobe\CEP\extensions"
set "CUSTOM_DIR=C:\path\to\your\custom\extensions"

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if %errorlevel% neq 0 (
    echo Требуются права администратора
    echo Запустите от имени администратора
    pause
    exit /b 1
)

:MENU
cls
echo =============================================
echo  СОЗДАНИЕ СИМВОЛИЧЕСКИХ ССЫЛОК ДЛЯ ADOBE CEP
echo =============================================
echo.
echo  1. Создать ссылки для каждой папки
echo  2. Проверить состояние
echo  3. Удалить ссылки на пользовательские папки
echo  4. Выход
echo.
echo  Откуда ^(пользовательская^)   %CUSTOM_DIR%
echo  Куда ^(Adobe^)                %ADOBE_DIR%
echo.
echo =============================================

set choice=
set /p choice=Выбор [1-4]^> 

if "%choice%"=="1" goto MAKE_INDIVIDUAL_LINKS
if "%choice%"=="2" goto CHECK
if "%choice%"=="3" goto REMOVE
if "%choice%"=="4" goto EXIT

echo Неверный выбор
timeout /t 2 >nul
goto MENU

:MAKE_SYMLINK
cls
echo СОЗДАНИЕ СИМВОЛИЧЕСКОЙ ССЫЛКИ
echo.

if not exist "%CUSTOM_DIR%" mkdir "%CUSTOM_DIR%" 2>nul

if exist "%ADOBE_DIR%" (
    set link_type=NONE
    >nul 2>nul dir "%ADOBE_DIR%" | findstr "<SYMLINK" >nul && set "link_type=SYMLINK"
    >nul 2>nul dir "%ADOBE_DIR%" | findstr "<JUNCTION" >nul && set "link_type=JUNCTION"
    
    if "!link_type!"=="SYMLINK" (
        echo Уже есть символическая ссылка
        set delete=
        set /p delete=Удалить ссылку? [y/n]^> 
        
        if /i "!delete!"=="y" (
            rmdir "%ADOBE_DIR%" >nul 2>nul
        ) else (
            echo Отмена
            pause
            goto MENU
        )
    ) else if "!link_type!"=="JUNCTION" (
        echo Уже есть жесткая ссылка
        set delete=
        set /p delete=Удалить ссылку? [y/n]^> 
        
        if /i "!delete!"=="y" (
            rmdir "%ADOBE_DIR%" >nul 2>nul
        ) else (
            echo Отмена
            pause
            goto MENU
        )
    ) else (
        echo ВНИМАНИЕ
        echo Это обычная директория
        echo Для создания ссылки нужно освободить путь
        echo.
        echo 1. Переместить содержимое в пользовательскую директорию 
        echo 2. Удалить директорию
        echo 3. Отмена
        echo.
        set action=
        set /p action=Выберите действие [1-3]^> 
        
        if "!action!"=="1" (
            if not exist "%CUSTOM_DIR%" mkdir "%CUSTOM_DIR%" 2>nul
            echo Перемещение файлов...
            xcopy "%ADOBE_DIR%\*" "%CUSTOM_DIR%\" /E /I /H /Y >nul
            rmdir /s /q "%ADOBE_DIR%" >nul 2>nul
            echo Файлы перемещены
        ) else if "!action!"=="2" (
            echo ВНИМАНИЕ
            echo Все файлы будут удалены
            set confirm=
            set /p confirm=Продолжить? [y/n]^> 
            
            if /i "!confirm!"=="y" (
                rmdir /s /q "%ADOBE_DIR%" >nul 2>nul
            ) else (
                echo Отмена
                pause
                goto MENU
            )
        ) else (
            echo Отмена
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
    echo Успех
) else (
    echo Ошибка
)

pause
goto MENU

:REMOVE
cls
echo УДАЛЕНИЕ ССЫЛОК НА ПОЛЬЗОВАТЕЛЬСКИЕ ПАПКИ
echo.

if not exist "%ADOBE_DIR%" (
    echo Директория Adobe не существует
    pause
    goto MENU
)

if not exist "%CUSTOM_DIR%" (
    echo Пользовательская директория не существует
    pause
    goto MENU
)

echo Поиск ссылок на пользовательские папки...
echo.

set found_links=0
set removed_links=0

set "user_folders="
for /d %%d in ("%CUSTOM_DIR%\*") do (
    set "folder_name=%%~nxd"
    set "user_folders=!user_folders! %%~nxd"
)

if "!user_folders!"=="" (
    echo В пользовательской директории нет папок
    pause
    goto MENU
)

echo Найденные пользовательские папки:
for %%f in (!user_folders!) do (
    echo - %%f
)
echo.

echo Проверка ссылок в директории Adobe...
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
            echo Удаление символической ссылки: !folder_name!
            rmdir "%%d" >nul 2>nul
            set /a removed_links+=1
        ) else (
            echo Пропуск обычной директории: !folder_name!
        )
        set /a found_links+=1
    )
)

if !found_links!==0 (
    echo Ссылок на пользовательские папки не найдено
) else (
    echo.
    echo Всего найдено ссылок: !found_links!
    echo Удалено ссылок: !removed_links!
)

pause
goto MENU

:CHECK
cls
echo ПРОВЕРКА СОСТОЯНИЯ
echo.

if not exist "%ADOBE_DIR%" (
    echo Директория Adobe не существует
    pause
    goto MENU
)

if not exist "%CUSTOM_DIR%" (
    echo Пользовательская директория не существует
    pause
    goto MENU
)

echo Основные директории:
echo - Пользовательская: %CUSTOM_DIR%
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
    echo Статус директории Adobe:
    echo Тип: Символическая ссылка
    echo Указывает на: !link_target!
)

echo.
echo ===================================
echo Подпапки в пользовательской директории:
echo ===================================
set subfolder_count=0
for /d %%d in ("%CUSTOM_DIR%\*") do (
    set "folder_name=%%~nxd"
    echo.
    echo Папка: !folder_name!
    echo Полный путь: %%~fd
    set /a subfolder_count+=1
)

if !subfolder_count!==0 (
    echo.
    echo Нет подпапок
)

echo.
echo ===================================
echo Подпапки в директории Adobe:
echo ===================================
set subfolder_count=0
for /d %%d in ("%ADOBE_DIR%\*") do (
    set "folder_name=%%~nxd"
    set "folder_type=Обычная директория"
    set "folder_target="
    
    fsutil reparsepoint query "%%d" >nul 2>&1
    if !errorlevel! equ 0 (
        set "folder_type=Символическая ссылка"
        
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
                set "folder_target=Неизвестно"
            )
        )
    )
    
    echo.
    echo Папка: !folder_name!
    echo Тип: !folder_type!
    echo Полный путь: %%~fd
    if "!folder_type!"=="Символическая ссылка" echo Указывает на: !folder_target!
    set /a subfolder_count+=1
)

if !subfolder_count!==0 (
    echo.
    echo Нет подпапок
)

pause
goto MENU

:MAKE_INDIVIDUAL_LINKS
cls
echo СОЗДАНИЕ ОТДЕЛЬНЫХ СИМВОЛИЧЕСКИХ ССЫЛОК
echo.

if not exist "%CUSTOM_DIR%" (
    echo Пользовательская директория не существует. Создание...
    mkdir "%CUSTOM_DIR%" 2>nul
)

if not exist "%ADOBE_DIR%" (
    echo Директория Adobe не существует. Создание...
    mkdir "%APPDATA%\Adobe\CEP" 2>nul
    mkdir "%ADOBE_DIR%" 2>nul
)

echo Создание символических ссылок для каждой папки...
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
            echo Уже существует символическая ссылка: !folder_name!
            set /a skipped_links+=1
        ) else if "!link_type!"=="JUNCTION" (
            echo Уже существует жесткая ссылка: !folder_name!
            set /a skipped_links+=1
        ) else (
            echo Обнаружена обычная директория: !folder_name!
            set replace=
            set /p replace=Заменить на символическую ссылку? [y/n]^> 
            
            if /i "!replace!"=="y" (
                rmdir /s /q "!target_link!" >nul 2>nul
                mklink /D "!target_link!" "%%d" >nul
                if !errorlevel! equ 0 (
                    echo Создана символическая ссылка: !folder_name!
                    set /a created_links+=1
                ) else (
                    echo Ошибка создания ссылки: !folder_name!
                )
            ) else (
                echo Пропущено: !folder_name!
                set /a skipped_links+=1
            )
        )
    ) else (
        mklink /D "!target_link!" "%%d" >nul
        if !errorlevel! equ 0 (
            echo Создана символическая ссылка: !folder_name!
            set /a created_links+=1
        ) else (
            echo Ошибка создания ссылки: !folder_name!
        )
    )
)

echo.
echo Всего создано ссылок: !created_links!
echo Пропущено: !skipped_links!

if !created_links!==0 (
    if !skipped_links!==0 (
        echo Нет папок в пользовательской директории
    )
)

pause
goto MENU

:EXIT
cls
echo Выход
exit /b 0 