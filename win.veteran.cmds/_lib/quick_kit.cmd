@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion




if not "%1"=="-h" goto :start_exec
echo.
echo 使用说明 - %2 脚本.
echo ==============================================================================
echo.
echo 基本用法:
echo   %2                  使用默认用户打开SSH
echo   %2  xx              指定SSH登录用户为xx
echo.
echo VSCode远程打开:
echo   %2  xx   yy         打开远程主机的yy目录 (指定用户xx)
echo   %2  yy/             打开远程主机的yy目录 (默认用户)
echo.
echo VSCode SFTP同步(需要VSCode中安装SFTP sync @Natizyskunk插件):
echo   %2  xx   yy   zz    将远程yy/ 同步到本地zz/ (指定用户xx)
echo   %2  xx/  yy         同上, 用户为默认用户.
echo.
echo SCP传输:
echo   %2  :xx   :yy       将远程xx 复制到远程yy    (默认用户, 使用 scp -3)
echo   %2  :xx   yy:       将远程xx 复制到本地yy    (默认用户)
echo   %2  xx:   :yy       将本地xx 复制到远程yy    (默认用户)
echo   %2  xx:   yy:       将本地xx 复制到本地yy    (默认用户)
echo   %2  myuser  :xx   yy:    (同理, 只是使用指定远程用户名myuser)
echo   %2  myuser  xx:   :yy    (同理)
echo.
exit /b 0
:start_exec








rem -----------------------------------------------------------------------------
rem 本地快捷操作符.
rem -----------------------------------------------------------------------------
if "%1"=="___local___" if not "%2"=="" if "%3"=="" (
    start explorer.exe "%2"
    exit /b 0
)

if "%1"=="___local___" if not "%2"=="" if "%3"=="v" (
    code "%2"
    exit /b 0
)








rem -----------------------------------------------------------------------------
rem 远程操作符: 取各参数到变量中.
rem -----------------------------------------------------------------------------

::%1 = SSH端口 (必填)
::%2 = 远程主机 IP/域名 (必填)
::%3 = 默认SSH用户名 (必填)
::%4 = SSH私钥路径 (可选, 不填则默认 %USERPROFILE%\.ssh\id_rsa)
::%5 / %6 / %7 = 后续功能参数, 用于判断是SCP/SSH/VSCode等.



set "port=%1"
set "host=%2"
set "defUser=%3"
set "sshKeyPath=%4"

REM echo ===%1====%2===%3===%4====%sshKeyPath%===%6===%7====

rem 第5、6、7才是原先脚本的核心判断.
set "arg5=%5"
set "arg6=%6"
set "arg7=%7"

rem -----------------------------------------------------------------------------
rem 远程操作符: 判断首末字符, 用于分析 :xx / xx: / / 结尾 等.
rem -----------------------------------------------------------------------------
set "firstChar5="
set "lastChar5="
set "firstChar6="
set "lastChar6="
set "firstChar7="
set "lastChar7="

if not "%arg5%"=="" set "firstChar5=%arg5:~0,1%"
if not "%arg5%"=="" set "lastChar5=%arg5:~-1%"
if not "%arg6%"=="" set "firstChar6=%arg6:~0,1%"
if not "%arg6%"=="" set "lastChar6=%arg6:~-1%"
if not "%arg7%"=="" set "firstChar7=%arg7:~0,1%"
if not "%arg7%"=="" set "lastChar7=%arg7:~-1%"

set "withColon5=F"
set "withColon6=F"
set "withColon7=F"
if "%firstChar5%"==":" set "withColon5=T"
if "%lastChar5%"==":"  set "withColon5=T"
if "%firstChar6%"==":" set "withColon6=T"
if "%lastChar6%"==":"  set "withColon6=T"
if "%firstChar7%"==":" set "withColon7=T"
if "%lastChar7%"==":"  set "withColon7=T"




rem -----------------------------------------------------------------------------
rem 远程操作符: 添加/删除 key
rem -----------------------------------------------------------------------------
if "%arg5%"=="__add.key__" if "%arg6%"=="" (
    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0quick_kit.ps1" -Port "%port%" -RemoteHost "%host%" -RemoteUser "%defUser%" -SshKeyPath "%sshKeyPath%" -PubKeyPath "%arg6%" -Action "add"
    exit /b
)
if "%arg5%"=="__remove.key__" if "%arg6%"=="" (
    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0quick_kit.ps1" -Port "%port%" -RemoteHost "%host%" -RemoteUser "%defUser%" -SshKeyPath "%sshKeyPath%" -PubKeyPath "%arg6%" -Action "remove"
    exit /b
)
if not "%arg5%"=="" if "%arg6%"=="__add.key__" (
    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0quick_kit.ps1" -Port "%port%" -RemoteHost "%host%" -RemoteUser "%arg5%"    -SshKeyPath "%sshKeyPath%" -PubKeyPath "%arg7%" -Action "add"
    exit /b
)
if not "%arg5%"=="" if "%arg6%"=="__remove.key__" (
    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0quick_kit.ps1" -Port "%port%" -RemoteHost "%host%" -RemoteUser "%arg5%"    -SshKeyPath "%sshKeyPath%" -PubKeyPath "%arg7%" -Action "remove"
    exit /b
)


rem -----------------------------------------------------------------------------
rem 远程操作符: 默认用户.
rem -----------------------------------------------------------------------------

rem 如果没有给 arg5~7, 就是最简单的 SSH 登录(用默认用户 + 指定Key)
if "%arg5%"=="" if "%arg6%"=="" if "%arg7%"=="" (
    echo "SSH: %defUser%@%host% -p %port% (key=%sshKeyPath%)"
    ssh -i "%sshKeyPath%" %defUser%@%host% -p %port%
    exit /b 0
)



rem 远程to远程 :xx  :yy
if "%firstChar5%"==":" if "%firstChar6%"==":" if "%arg7%"=="" (
    set "src=%arg5:~1%"
    set "dst=%arg6:~1%"
    echo scp -3: %defUser%@%host%:!src!  to  %defUser%@%host%:!dst!
    scp -3 -i "%sshKeyPath%" -P %port% -r %defUser%@%host%:"!src!" %defUser%@%host%:"!dst!"
    exit /b 0
)
rem 远程to本地 :xx  yy:

if "%firstChar5%"==":" if "%lastChar6%"==":" if "%arg7%"=="" (
    echo %arg5%
    echo %arg6%
    set "src=%arg5:~1%"
    set "dst=%arg6:~0,-1%"
    echo scp: %defUser%@%host%:!src!  to  !dst!
    scp -i "%sshKeyPath%" -P %port% -r %defUser%@%host%:"!src!" "!dst!"
    exit /b 0
)

rem 本地to远程 xx:  :yy
if "%lastChar5%"==":" if "%firstChar6%"==":" if "%arg7%"=="" (
    set "src=%arg5:~0,-1%"
    set "dst=%arg6:~1%"
    echo scp: !src!  to  %defUser%@%host%:!dst!
    scp -i "%sshKeyPath%" -P %port% -r "!src!" %defUser%@%host%:"!dst!"
    exit /b 0
)
rem 本地to本地 xx:  yy:
if "%lastChar5%"==":" if "%lastChar6%"==":" if "%arg7%"=="" (
    set "src=%arg5:~0,-1%"
    set "dst=%arg6:~0,-1%"
    echo scp: !src!  to  !dst!
    scp -i "%sshKeyPath%" -P %port% -r "!src!" "!dst!"
    exit /b 0
)





rem arg5 以 / 结尾, 且 arg6/arg7 为空 to VSCode远程打开(默认用户 + 指定Key)
if "%lastChar5%"=="/" if "%arg6%"=="" if "%arg7%"=="" (
    echo "VSCode远程打开: %arg5%"
    for /f "delims=" %%a in ('ssh -i "%sshKeyPath%" %defUser%@%host% -o ServerAliveInterval=60 -p %port% echo $HOME') do (
        set "opssshresult=%%a"
    )
    code --remote=ssh-remote+%defUser%@%host%:%port% !opssshresult!/%arg5%
    exit /b 0
)
rem arg5 以 / 结尾, arg6 不空, arg7空 to SFTP 同步(默认用户 + 指定Key)
if "%lastChar5%"=="/" if not "%arg6%"=="" if not "%firstChar6%"==":" if "%arg7%"=="" (
    if not exist "%arg6%\.vscode" mkdir "%arg6%\.vscode"
    if not exist "%arg6%\.vscode\SFTP.json" (
        (
        echo {
        echo     "name": "%arg6%.%defUser%",
        echo     "host": "%host%",
        echo     "protocol": "sftp",
        echo     "port": %port%,
        echo     "username": "%defUser%",
        echo     "privateKeyPath": "%sshKeyPath%",
        echo     "remotePath": "%arg5%",
        echo     "uploadOnSave": true,
        echo     "useTempFile": false,
        echo     "openSsh": false
        echo }
        ) > "%arg6%\.vscode\SFTP.json"
    )
    echo "SFTP已设置同步, 需要安装插件: SFTP by Natizyskunk"
    code "%arg6%"
    exit /b 0
)
rem arg5 以 / 开头, 且 arg6/arg7 为空 to VSCode远程打开(默认用户 + 指定Key)
if "%firstChar5%"=="/" if "%arg6%"=="" if "%arg7%"=="" (
    echo "VSCode open remote: %arg5%"
    for /f "delims=" %%a in ('ssh -i "%sshKeyPath%" %defUser%@%host% -o ServerAliveInterval=60 -p %port% echo $HOME') do (
        set "opssshresult=%%a"
    )
    code --remote=ssh-remote+%defUser%@%host%:%port% !opssshresult!/%arg5%
    exit /b 0
)
rem arg5 以 / 开头, arg6 不空, arg7空 to SFTP 同步(默认用户 + 指定Key)
if "%firstChar5%"=="/" if not "%arg6%"=="" if not "%firstChar6%"==":" if "%arg7%"=="" (
    if not exist "%arg6%\.vscode" mkdir "%arg6%\.vscode"
    if not exist "%arg6%\.vscode\SFTP.json" (
        (
        echo {
        echo     "name": "%arg6%.%defUser%",
        echo     "host": "%host%",
        echo     "protocol": "sftp",
        echo     "port": %port%,
        echo     "username": "%defUser%",
        echo     "privateKeyPath": "%sshKeyPath%",
        echo     "remotePath": "%arg5%",
        echo     "uploadOnSave": true,
        echo     "useTempFile": false,
        echo     "openSsh": false
        echo }
        ) > "%arg6%\.vscode\SFTP.json"
    )
    echo "SFTP已设置同步, 需要安装插件: SFTP by Natizyskunk"
    code "%arg6%"
    exit /b 0
)










rem %arg5% 为空，以及: /开通结尾的情况都处理完了，剩下即不为空且不以 : / 开头或结尾.


rem %6 %7 都为空: 指定用户SSH登录.
if "%arg6%"=="" if "%arg7%"=="" (
    echo "指定用户SSH: %arg5%@%host%  -p %port%, key=%sshKeyPath%"
    ssh -i "%sshKeyPath%" %arg5%@%host% -p %port%
    exit /b 0
)


rem 远程to远程 :xx  :yy
if "%firstChar6%"==":" if "%firstChar7%"==":" (
    set "src=%arg6:~1%"
    set "dst=%arg7:~1%"
    echo scp -3: %arg5%@%host%:!src!  to  %arg5%@%host%:!dst!
    scp -3 -i "%sshKeyPath%" -P %port% -r %arg5%@%host%:"!src!" %arg5%@%host%:"!dst!"
    exit /b 0
)
rem 远程to本地 :xx  yy:
if "%firstChar6%"==":" if "%lastChar7%"==":" (
    set "src=%arg6:~1%"
    set "dst=%arg7:~0,-1%"
    echo scp: %arg5%@%host%:!src!  to  !dst!
    scp -i "%sshKeyPath%" -P %port% -r %arg5%@%host%:"!src!" "!dst!"
    exit /b 0
)
rem 本地to远程 xx:  :yy
if "%lastChar6%"==":" if "%firstChar7%"==":" (
    set "src=%arg6:~0,-1%"
    set "dst=%arg7:~1%"
    echo scp: !src!  to  %arg5%@%host%:!dst!
    scp -i "%sshKeyPath%" -P %port% -r "!src!" %arg5%@%host%:"!dst!"
    exit /b 0
)
rem 本地to本地 xx:  yy:
if "%lastChar6%"==":" if "%lastChar7%"==":" (
    set "src=%arg6:~0,-1%"
    set "dst=%arg7:~0,-1%"
    echo scp: !src!  to  !dst!
    scp -i "%sshKeyPath%" -P %port% -r "!src!" "!dst!"
    exit /b 0
)






rem 情况: 指定用户VSCode打开远程目录.
if not "%lastChar6%"=="x" if "%arg7%"=="" (
    echo "指定用户VSCode打开: %arg5%@%host%:%arg6%"
    for /f "delims=" %%a in ('ssh -i "%sshKeyPath%" %arg5%@%host% -o ServerAliveInterval=60 -p %port% echo $HOME') do (
        set "opssshresult=%%a"
    )
    code --remote=ssh-remote+%arg5%@%host%:%port% !opssshresult!/%arg6%
    exit /b 0
)
rem 情况: 指定用户SFTP同步配置.
if not "%lastChar6%"=="" if not "%arg7%"=="" if not "%firstChar7%"==":" (
    if not exist "%arg7%\.vscode" mkdir "%arg7%\.vscode"
    if not exist "%arg7%\.vscode\SFTP.json" (
        (
        echo {
        echo     "name": "%arg7%.%arg5%",
        echo     "host": "%host%",
        echo     "protocol": "sftp",
        echo     "port": %port%,
        echo     "username": "%arg5%",
        echo     "privateKeyPath": "%sshKeyPath%",
        echo     "remotePath": "%arg6%",
        echo     "uploadOnSave": true,
        echo     "useTempFile": false,
        echo     "openSsh": false
        echo }
        ) > "%arg7%\.vscode\SFTP.json"
    )
    echo "SFTP已设置同步(需要安装: SFTP by Natizyskunk)"
    code "%arg7%"
    exit /b 0
)




echo 无法识别的参数组合，请检查输入.
exit /b 1
