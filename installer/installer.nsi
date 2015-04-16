/**
 * Web Store NSIS 2.46 install script
 * (c) 2002-2015 Rafał Toborek
 * http://toborek.info
 * http://github.com/clash82/WebStore
 */

!define WS_VERSION "2.3.0.0"
!define WS_NAME "Web Store"
!define REG_UNINSTALL "Software\Microsoft\Windows\CurrentVersion\Uninstall\${WS_NAME}"

!define MULTIUSER_EXECUTIONLEVEL Highest
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_DEFAULT_CURRENTUSER
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_KEY "Software\${WS_NAME}"
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_VALUENAME ""
!define MULTIUSER_INSTALLMODE_INSTDIR "${WS_NAME}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_KEY "Software\${WS_NAME}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_VALUENAME ""

SetCompressor /SOLID lzma

!include "multiuser.nsh"
!include "MUI2.nsh"

BrandingText "${WS_NAME} ${WS_VERSION}"
Name "${WS_NAME}"
Caption "${WS_NAME} ${WS_VERSION} installer"
OutFile "wstore${WS_VERSION}.exe"

XPStyle on
CRCCheck on
!define MUI_ICON "icon_install.ico"
!define MUI_UNICON "icon_uninstall.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
!define MUI_HEADER_TRANSPARENT_TEXT
!define MUI_WELCOMEFINISHPAGE_BITMAP "ending.bmp"
ShowInstDetails hide

!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_LICENSE "welcome.txt"
!insertmacro MULTIUSER_PAGE_INSTALLMODE
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "&Run"
!define MUI_FINISHPAGE_RUN_FUNCTION "_exec_app"
!define MUI_FINISHPAGE_LINK "toborek.info"
!define MUI_FINISHPAGE_LINK_LOCATION "http://toborek.info"
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE "English"

VIProductVersion "${WS_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "${WS_NAME} ${WS_VERSION} installer"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${WS_NAME} (http://toborek.info)"
VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "${WS_NAME} ${WS_VERSION} installer"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "Rafał Toborek"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalTrademarks" "Rafał Toborek"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Rafał Toborek"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${WS_VERSION}"

!include "FileFunc.nsh"
!macro install_app
	Delete "$INSTDIR\*.*"
	Delete "$SMPROGRAMS\${WS_NAME}\*.*"

	SetOverwrite on
	File "..\release\webstore.exe"
	File "..\release\webstore.hdr"
	File "..\release\delzip190.dll"
	File "files\changelog_pl.txt"
	File "files\license.txt"
	File "files\webstore.txt"
	File "files\webstore_pl.txt"

	WriteRegStr SHELL_CONTEXT "Software\${WS_NAME}" "" $INSTDIR
	CreateDirectory "$SMPROGRAMS\${WS_NAME}"

	CreateShortCut "$SMPROGRAMS\${WS_NAME}\Web Store Wizard.lnk" "$INSTDIR\webstore.exe" "" "$INSTDIR\webstore.exe" "0" ""
	WriteINIStr "$SMPROGRAMS\${WS_NAME}\Home page.url" "InternetShortcut" "URL" "http://toborek.info"
	WriteINIStr "$SMPROGRAMS\${WS_NAME}\GitHub page.url" "InternetShortcut" "URL" "http://github.com/clash82/WebStore"
	WriteUninstaller "$INSTDIR\uninstall.exe"
	WriteRegStr SHELL_CONTEXT "${REG_UNINSTALL}" "DisplayName" "${WS_NAME}"
	WriteRegStr SHELL_CONTEXT "${REG_UNINSTALL}" "UninstallString" '"$INSTDIR\uninstall.exe"'
	WriteRegDWORD SHELL_CONTEXT "${REG_UNINSTALL}" "NoModify" 1
	WriteRegDWORD SHELL_CONTEXT "${REG_UNINSTALL}" "NoRepair" 1
	WriteRegStr SHELL_CONTEXT "${REG_UNINSTALL}" "Publisher" "Rafał Toborek"
	WriteRegStr SHELL_CONTEXT "${REG_UNINSTALL}" "HelpLink" "http://toborek.info"

	WriteRegStr SHELL_CONTEXT "${REG_UNINSTALL}" "DisplayVersion" "${WS_VERSION}"
	WriteRegStr SHELL_CONTEXT "${REG_UNINSTALL}" "DisplayIcon" '"$INSTDIR\webstore.exe"'
	WriteRegStr SHELL_CONTEXT "${REG_UNINSTALL}" "InstallLocation" '"$INSTDIR"'
	WriteRegStr SHELL_CONTEXT "${REG_UNINSTALL}" "Readme" '"$INSTDIR\readme.txt"'

	${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
	IntFmt $0 "0x%08X" $0
	WriteRegDWORD SHELL_CONTEXT "${REG_UNINSTALL}" "EstimatedSize" "$0"
!macroEnd

Section
	SetOutPath $INSTDIR
        !insertmacro install_app
SectionEnd

Section "Uninstall"
	Delete "$INSTDIR\*.*"
	RMDir "$INSTDIR"
	Delete "$SMPROGRAMS\${WS_NAME}\*.*"
	RMDir "$SMPROGRAMS\${WS_NAME}"
	DeleteRegKey SHELL_CONTEXT "Software\Microsoft\Windows\CurrentVersion\Uninstall\${WS_NAME}"
	DeleteRegKey SHELL_CONTEXT "Software\${WS_NAME}"

	; remove settings for current user (you must do it for "All Users" installation)
	DeleteRegKey HKCU "Software\${WS_NAME}"

	MessageBox MB_OK|MB_ICONINFORMATION "${WS_NAME} was uninstalled from this computer :-("
        Quit
SectionEnd

Function _exec_app
	ExecShell "open" "$INSTDIR\webstore.exe"
FunctionEnd

!include "FileFunc.nsh"
!include "LogicLib.nsh"

Function .onInit
	ReadRegStr $0 SHELL_CONTEXT "Software\${WS_NAME}" ""
	${If} $0 == ""
		StrCpy $INSTDIR "$PROGRAMFILES\${WS_NAME}"
	${Else}
		StrCpy $INSTDIR $0
        ${EndIf}

	!insertmacro MULTIUSER_INIT
FunctionEnd

Function un.onInit
	!insertmacro MULTIUSER_UNINIT
FunctionEnd
