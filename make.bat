@echo off
del "release\*.*" /q
cd "app_header"
"dcc32.exe" "header.dpr"
if exist "..\release\header.exe" (
	"..\components\upx.exe" -9 "..\release\header.exe"
	ren "..\release\header.exe" "webstore.hdr"
	cd "..\app_webstore"
	"dcc32.exe" "webstore.dpr"
	copy "..\components\zipmaster\dll\delzip190.dll" "..\release\delzip190.dll"
	if exist "..\release\webstore.exe" (
		del "..\release\*.dcu" /q
		"..\release\webstore.exe"
	) else (
		echo "ERROR: webstore.exe was not compiled correctly."
		pause
	)	
) else (
	echo "ERROR: header.exe file was not compiled correctly."
	pause
)
