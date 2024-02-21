@echo off
echo ================================ Begin ================================
echo=
set Default_msg=更新博客
set "Input_msg="
set "Submit_msg="
echo  (1) 拉取远端文件
echo ═══════════════════════════════════════════════════
echo 拉取中...
echo=
git pull
echo=
echo 拉取成功！
echo=
echo  (2) 查看文件状态
echo ═══════════════════════════════════════════════════
git status
echo=
echo ┌—————————————————————┐
echo │  Untracked  ：新添加文件，未加入本地仓库 │
echo │  Modified   ：已修改文件，未进行其他操作 │
echo │  Staged     ：已暂存文件，才加入本地仓库 │ 
echo │  Unmodified ：未修改文件，已加入本地仓库 │
echo └—————————————————————┘
echo=
echo  (3) 提交本地文件
echo ═══════════════════════════════════════════════════
echo  ﹡输入 0，提交信息默认为「更新博客」。
echo  ﹡多条提交信息，请用「逗号」隔开。
echo  ﹡提交信息含有「空格」时，文件上传失败。
echo=
set /p Input_msg=提交信息：
echo=
if %Input_msg% equ 0 (
	set Submit_msg=%Default_msg%
) else (
	set Submit_msg=%Input_msg%
)
git add .
git commit -m "%Submit_msg%"
git push
echo=
echo  (4) 本次更新内容：
echo ═══════════════════════════════════════════════════
set remain=%Submit_msg%
:loop
for /f "tokens=1* delims=，" %%a in ("%remain%") do (
	echo ├  %%a
	set remain=%%b
)
if defined remain goto :loop
echo=
echo ================================= End =================================
pause