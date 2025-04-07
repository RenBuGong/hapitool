@echo off
chcp 65001  >nul
setlocal EnableDelayedExpansion
set "TIME_STAMP=[%date% %time%]"
:: 1. 获取当前脚本所在目录，去掉末尾的反斜杠.
set "NEW_PATH=%~dp0"
set "NEW_PATH=%NEW_PATH:~0,-1%"

:: 2. 从注册表读取用户级 PATH (可能包含空格，所以用 tokens=1,2,*)
for /f "tokens=1,2,* skip=2" %%a in ('reg query HKCU\Environment /v PATH 2^>nul') do (
    if /i "%%a"=="PATH" (
        set "USER_PATH=%%c"
    )
)
if not defined USER_PATH (
    echo 没有找到用户级 PATH 环境变量.
    goto :EOF
)

:: 3. 备份当前用户级 PATH 到脚本同目录的 .bak.txt 文件中.
echo USER-PATH_PRE-DEL %TIME_STAMP% %USER_PATH% >> "%~dp0__path_backup.log"
echo 当前用户级 PATH:
echo %USER_PATH%
echo 已备份当前 PATH 到 %~dp0%~n0_remove.bak.txt

:: 4. 将用户 PATH 字符串首尾加分号，便于精确匹配和替换.
set "temp=;%USER_PATH%;"

:: 5. 删除路径：把";目标路径;"替换为";"
set "temp=!temp:;%NEW_PATH%;=;!"

:: 6. 循环去除可能产生的双分号.
:removeDouble
if not "!temp!"=="!temp:;;=;!" (
    set "temp=!temp:;;=;!"
    goto removeDouble
)

:: 7. 移除开头和结尾多余的分号.
if "!temp:~0,1!"==";" set "temp=!temp:~1!"
if "!temp:~-1!"==";" set "temp=!temp:~0,-1!"

:: 8. 更新用户级 PATH
setx PATH "!temp!" >/nul
echo 用户级 PATH 已更新，新值为:
echo !temp!

endlocal
pause
