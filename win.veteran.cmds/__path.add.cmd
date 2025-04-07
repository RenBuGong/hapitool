@echo off
chcp 65001  >nul
:: -------------------------------------------------------------------------
:: 文件: add_path.bat
:: 用途: 将脚本所在目录添加到当前用户的 PATH(注册表HKCU\Environment) 中。
:: -------------------------------------------------------------------------
setlocal enableextensions

:: 1. 获取脚本自身所在目录(去除末尾的"\")
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" (
    set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
)



:: 2. 从注册表查询用户 PATH 值
set "CurrentUserPath="
set "RegPathType="

for /f "skip=2 tokens=1,2,* delims= " %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
    if /i "%%a"=="Path" (
        set "RegPathType=%%b"
        set "CurrentUserPath=%%c"
    )
)

:: 若不存在 PATH 这个键，CurrentUserPath 可能为空
if not defined CurrentUserPath (
    set "CurrentUserPath="
)

echo 当前用户PATH(原始):
echo %CurrentUserPath%
echo.

:: 3. 判断是否已包含脚本目录 不区分大小写
echo %CurrentUserPath% | find /i "%SCRIPT_DIR%" >nul
if %ERRORLEVEL%==0 (
    echo 当前目录已存在, 无需添加:
    echo %SCRIPT_DIR%
    echo.
    pause
    goto :EOF
)

:: 4. 备份当前PATH(带时间戳)到同目录 __path_backup.log
set "TIME_STAMP=[%date% %time%]"
echo USER-PATH_PRE-ADD %TIME_STAMP%   %CurrentUserPath% >>"%~dp0__path_backup.log"

:: 5. 组装新的PATH
if "%CurrentUserPath%"=="" (
    set "NewUserPath=%SCRIPT_DIR%"
) else (
    set "NewUserPath=%CurrentUserPath%;%SCRIPT_DIR%"
)

echo 准备写入新的PATH:
echo %NewUserPath%
echo.

:: 6. setx 写入注册表
setx Path "%NewUserPath%" >nul
if %ERRORLEVEL% neq 0 (
    echo [错误] 写入注册表失败，脚本退出.
    pause
    goto :EOF
)



echo [完成] 已添加到用户PATH.
echo 提示: 需关闭并重新打开命令提示符才会看到最新PATH生效.
echo.
pause
goto :EOF
