!include setup.nsh

Name "${PRODUCTNAME}"

# General Symbol Definitions
!define REGKEY "SOFTWARE\${PRODUCTNAME}"
!define COMPANY Nuxeo
!define URL http://www.nuxeo.com/

# MultiUser Symbol Definitions
!define MULTIUSER_EXECUTIONLEVEL Admin
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_KEY "${REGKEY}"
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_VALUENAME MultiUserInstallMode
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_INSTDIR "${PRODUCTNAME}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_KEY "${REGKEY}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_VALUE "Path"

# MUI Symbol Definitions
!define MUI_ICON "${NUXEO_RESOURCES_DIR}${SEP}install.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NUXEO_RESOURCES_DIR}${SEP}startfinish.bmp"
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_STARTMENUPAGE_REGISTRY_ROOT HKLM
!define MUI_STARTMENUPAGE_REGISTRY_KEY ${REGKEY}
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME StartMenuGroup
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${PRODUCTNAME}"
!define MUI_UNICON "${NUXEO_RESOURCES_DIR}${SEP}uninstall.ico"
!define MUI_UNFINISHPAGE_NOAUTOCLOSE
!define MUI_LANGDLL_REGISTRY_ROOT HKLM
!define MUI_LANGDLL_REGISTRY_KEY ${REGKEY}
!define MUI_LANGDLL_REGISTRY_VALUENAME InstallerLanguage

# Nuxeo
!define NUXEO_PRODUCT_ICON "nuxeo.ico"

# Included files
!include x64.nsh
!include MultiUser.nsh
!include Sections.nsh
!include MUI2.nsh
!include "StrFunc.nsh"

${StrLoc} # Initialize function for use in install sections

# Reserved Files
!insertmacro MUI_RESERVEFILE_LANGDLL

# Variables
Var StartMenuGroup

Var PerformDMUpgrade
Var radioreplace
Var radiokeep

Var JavaExe
Var javabox
Var InstallJava

Var officebox
Var InstallOffice

Var pgsqlbox
Var InstallPGSQL
Var PGPath
Var PGUser

Var rmtmpbox
Var RemoveTmp
Var rmdatabox
Var RemoveData
Var rmlogsbox
Var RemoveLogs
Var rmconfbox
Var RemoveConf

# Installer pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE $(license)
!insertmacro MULTIUSER_PAGE_INSTALLMODE
Page custom CheckUpgradeFromNuxeo UpgradeFromNuxeo
Page custom CheckUpgradeFromDM UpgradeFromDM
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuGroup
Page custom SelectDependencies GetSelectedDependencies
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
UninstPage custom un.SelectRemove un.GetSelectedRemove
!insertmacro MUI_UNPAGE_INSTFILES

# Installer languages
!insertmacro MUI_LANGUAGE English
!insertmacro MUI_LANGUAGE French
!insertmacro MUI_LANGUAGE Spanish
!insertmacro MUI_LANGUAGE German
!insertmacro MUI_LANGUAGE Italian

# Installer attributes
InstallDir "${PRODUCTNAME}"
CRCCheck on
XPStyle on
ShowInstDetails show
VIAddVersionKey /LANG=${LANG_ENGLISH} ProductName "${PRODUCTNAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} ProductVersion "${VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} CompanyName "${COMPANY}"
VIAddVersionKey /LANG=${LANG_ENGLISH} CompanyWebsite "${URL}"
VIAddVersionKey /LANG=${LANG_ENGLISH} FileVersion "${VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} FileDescription "Nuxeo Enterprise Content Management"
VIAddVersionKey /LANG=${LANG_ENGLISH} LegalCopyright "Nuxeo SA 2006-2012"
InstallDirRegKey HKLM "${REGKEY}" Path
ShowUninstDetails show

# Installer sections

Section -Main SEC0000

    Call InstallDependencies

    SetOutPath $INSTDIR
    SetOverwrite on
    # Give full access to group "Builtin Users"
    AccessControl::GrantOnFile "$INSTDIR" "(BU)" "FullAccess"
    File /r ${NUXEO_DISTRIBUTION_DIR}${SEP}*
    File "${NUXEO_RESOURCES_DIR}${SEP}${NUXEO_PRODUCT_ICON}"

    Var /GLOBAL NXDATA
    ${if} $PerformDMUpgrade != 0
        StrCpy $NXDATA "Nuxeo DM"
    ${Else}
        StrCpy $NXDATA "${PRODUCTNAME}"
    ${EndIf}

    # Delete nuxeo.conf from the main product tree
    Delete bin\nuxeo.conf
    # and add it to $APPDATA (without overwriting existing ones)
    IfFileExists "$APPDATA\$NXDATA\conf\nuxeo.conf" nuxeoconfalmostdone
    SetOutPath "$APPDATA\$NXDATA\conf"
    SetOverwrite Off # just to be safe
    File ${NUXEO_DISTRIBUTION_DIR}${SEP}bin${SEP}nuxeo.conf
    FileOpen $2 "$APPDATA\$NXDATA\conf\nuxeo.conf" a
    FileSeek $2 0 END
    FileWrite $2 "$\r$\n"
    FileWrite $2 "nuxeo.data.dir=$APPDATA\$NXDATA\data$\r$\n"
    FileWrite $2 "nuxeo.log.dir=$APPDATA\$NXDATA\logs$\r$\n"
    FileWrite $2 "nuxeo.tmp.dir=$APPDATA\$NXDATA\tmp$\r$\n"
    FileWrite $2 "nuxeo.wizard.skippedsections=Paths$\r$\n"
    ${If} $InstallPGSQL == 1
        FileWrite $2 "nuxeo.templates=postgresql$\r$\n"
        FileWrite $2 "nuxeo.db.host=localhost$\r$\n"
        FileWrite $2 "nuxeo.db.port=5432$\r$\n"
        FileWrite $2 "nuxeo.db.name=nuxeodm$\r$\n"
        FileWrite $2 "nuxeo.db.user=nuxeodm$\r$\n"
        FileWrite $2 "nuxeo.db.password=nuxeodm$\r$\n"
        FileWrite $2 "nuxeo.wizard.skippedpages=DB$\r$\n"
    ${EndIf}
    FileWrite $2 "nuxeo.wizard.done=false$\r$\n"
    FileClose $2
    nuxeoconfalmostdone:
    ${if} $PerformDMUpgrade != 0
        # This is an upgrade from DM: reactivate wizard and skip most pages
        FileOpen $2 "$APPDATA\$NXDATA\conf\nuxeo.conf" a
        FileSeek $2 0 END
        FileWrite $2 "$\r$\n"
        FileWrite $2 "nuxeo.wizard.skippedpages=NetworkBlocked,General,Proxy,DB,Smtp$\r$\n"
        FileWrite $2 "nuxeo.wizard.done=false$\r$\n"
        FileClose $2
        SetOverwrite On
        FileOpen $2 "$INSTDIR\setupWizardDownloads\packages-default-selection.properties" w
        FileWrite $2 "preset=nuxeo-dm$\r$\n"
        FileClose $2
    ${Else}
        # This is not an upgrade from DM. If DM exists (side by side installation), change default http port
        ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Nuxeo DM" UninstallString
        StrCmp $2 "" nuxeoconfdone
        FileOpen $2 "$APPDATA\$NXDATA\conf\nuxeo.conf" a
        FileSeek $2 0 END
        FileWrite $2 "$\r$\n"
        FileWrite $2 "nuxeo.server.http.port=8081$\r$\n"
        FileWrite $2 "nuxeo.url=http://localhost:8081/nuxeo$\r$\rn"
        FileClose $2
    ${EndIf}
    nuxeoconfdone:
    AccessControl::GrantOnFile "$APPDATA\$NXDATA" "(BU)" "FullAccess"
    WriteRegStr HKLM "${REGKEY}" ConfigFile "$APPDATA\$NXDATA\conf\nuxeo.conf"
    SetOverwrite On

    # Include local 3rd parties (pdftohtml, ...)
    SetOutPath "$INSTDIR\3rdparty"
    File /r ${NUXEO_RESOURCES_DIR}${SEP}3rdparty${SEP}*

    # Include default PostgreSQL config file and db setup script
    SetOutPath "$INSTDIR\contrib"
    File ${NUXEO_RESOURCES_DIR}${SEP}contrib${SEP}*

    # Create a new file so NuxeoCtl can find out what product is running
    FileOpen $2 "$INSTDIR\bin\ProductName.txt" w
    FileWrite $2 "${PRODUCTNAME}"
    FileClose $2

    # Create tmp dir
    SetOutPath "$APPDATA\$NXDATA\tmp"
    # Give full access to group "Builtin Users"
    AccessControl::GrantOnFile "$APPDATA\$NXDATA\tmp" "(BU)" "FullAccess"

    # PostgreSQL setup :
    ${If} $InstallPGSQL == 1
        Call GetPGSQLSettings
        # stop postgresql
        ExecWait "sc stop postgresql-9.1"
        Sleep 5000 # Hope the service will be stopped after 5 seconds
        # overwrite postgresql.conf with ours
        SetOutPath $APPDATA\${PRODUCTNAME}\pgsql
        File ${NUXEO_RESOURCES_DIR}${SEP}contrib${SEP}postgresql.conf
        # create pgpass file (in the "current user" context)
        ${If} $MultiUser.InstallMode == AllUsers
            SetShellVarContext current
        ${EndIf}
        SetOutPath $APPDATA\postgresql
        FileOpen $2 "$APPDATA\postgresql\pgpass.conf" a
        FileSeek $2 0 END
        FileWrite $2 "$\r$\n"
        FileWrite $2 "localhost:5432:template1:$PGUser:postgres"
        FileClose $2
        ${If} $MultiUser.InstallMode == AllUsers
            SetShellVarContext all
        ${EndIf}
        # start postgresql
        ExecWait "sc start postgresql-9.1"
        Sleep 5000 # Hope the service will be started after 5 seconds
        # run db creation script
        ExecWait "$PGPath\bin\psql.exe -h localhost -U $PGUser -f $\"$INSTDIR\contrib\create_db.sql$\" template1"
    ${EndIf}

    SetOutPath $INSTDIR\bin
    CreateShortcut "$DESKTOP\${PRODUCTNAME}.lnk" "$INSTDIR\bin\Start Nuxeo.bat" "" "$INSTDIR\${NUXEO_PRODUCT_ICON}"
    WriteRegStr HKLM "${REGKEY}\Components" Main 1

    WriteRegStr HKLM "${REGKEY}" Path $INSTDIR
    WriteRegStr HKLM "${REGKEY}" VarDirectory "$APPDATA\$NXDATA"
    # Installation done, don't ask about DM upgrade again
    WriteRegStr HKLM "${REGKEY}" SkipDMUpgrade "true"
    SetOutPath $INSTDIR
    WriteUninstaller $INSTDIR\uninstall.exe
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    SetOutPath $SMPROGRAMS\$StartMenuGroup
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\${PRODUCTNAME}.lnk" "$INSTDIR\bin\Start Nuxeo.bat" "" "$INSTDIR\${NUXEO_PRODUCT_ICON}"
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\$(^UninstallLink).lnk" $INSTDIR\uninstall.exe
    !insertmacro MUI_STARTMENU_WRITE_END
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" DisplayName "${PRODUCTNAME}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" DisplayVersion "${VERSION}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" Publisher "${COMPANY}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" URLInfoAbout "${URL}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" DisplayIcon $INSTDIR\uninstall.exe
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" UninstallString $INSTDIR\uninstall.exe
    WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" NoModify 1
    WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" NoRepair 1
SectionEnd

# Macro for selecting uninstaller sections
!macro SELECT_UNSECTION SECTION_NAME UNSECTION_ID
    Push $R0
    ReadRegStr $R0 HKLM "${REGKEY}\Components" "${SECTION_NAME}"
    StrCmp $R0 1 0 next${UNSECTION_ID}
    !insertmacro SelectSection "${UNSECTION_ID}"
    GoTo done${UNSECTION_ID}
next${UNSECTION_ID}:
    !insertmacro UnselectSection "${UNSECTION_ID}"
done${UNSECTION_ID}:
    Pop $R0
!macroend

# Uninstaller sections
Section /o -un.Main UNSEC0000
    # Stop Nuxeo
    ReadRegStr $2 HKLM "${REGKEY}" Path
    StrCmp $2 "" nuxeostopped
    ExecWait "$2\bin\nuxeoctl.bat nogui stop"
    nuxeostopped:
    # Remove the rest
    Delete /REBOOTOK "$DESKTOP\${PRODUCTNAME}.lnk"
    RmDir /r /REBOOTOK $INSTDIR
    DeleteRegValue HKLM "${REGKEY}\Components" Main
    ReadRegStr $3 HKLM "${REGKEY}" VarDirectory
    # Use default if VarDirectory isn't in the registry
    ${If} $3 == ""
        StrCpy $3 "$APPDATA\${PRODUCTNAME}"
    ${EndIf}
    ${If} $RemoveTmp == 1
        RmDir /r /REBOOTOK "$3\tmp"
    ${EndIf}
    ${If} $RemoveData == 1
        RmDir /r /REBOOTOK "$3\data"
    ${EndIf}
    ${If} $RemoveLogs == 1
        RmDir /r /REBOOTOK "$3\logs"
    ${EndIf}
    ${If} $RemoveConf == 1
        RmDir /r /REBOOTOK "$3\conf"
    ${EndIf}
    RmDir "$3"

    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\${PRODUCTNAME}.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\$(^UninstallLink).lnk"
    Delete /REBOOTOK $INSTDIR\uninstall.exe
    RmDir /REBOOTOK $INSTDIR
    DeleteRegValue HKLM "${REGKEY}" StartMenuGroup
    DeleteRegValue HKLM "${REGKEY}" Path
    DeleteRegValue HKLM "${REGKEY}" SkipDMUpgrade
    DeleteRegKey /IfEmpty HKLM "${REGKEY}\Components"
    DeleteRegKey /IfEmpty HKLM "${REGKEY}"
    RmDir /REBOOTOK $SMPROGRAMS\$StartMenuGroup
    Push $R0
    StrCpy $R0 $StartMenuGroup 1
    StrCmp $R0 ">" no_smgroup
no_smgroup:
    Pop $R0
SectionEnd

# Custom functions

Function CheckJava
    # 64bit arch with 64bit JDK
    ${If} ${RunningX64}
        SetRegView 64
        ReadRegStr $2 HKLM \
               "SOFTWARE\JavaSoft\Java Development Kit" \
               "CurrentVersion"
        SetRegView 32
        StrCmp $2 "1.6" foundjava
        StrCmp $2 "1.7" foundjava
    ${EndIf}
    # 64bit arch with 32bit JDK
    ${If} ${RunningX64}
        SetRegView 64
        ReadRegStr $2 HKLM \
                   "SOFTWARE\Wow6432Node\JavaSoft\Java Development Kit" \
                   "CurrentVersion"
        SetRegView 32
        StrCmp $2 "1.6" foundjava
        StrCmp $2 "1.7" foundjava
    ${EndIf}
    # 32bit arch with 32bit JDK
    ReadRegStr $2 HKLM \
           "SOFTWARE\JavaSoft\Java Development Kit" \
           "CurrentVersion"
    StrCmp $2 "1.6" foundjava
    StrCmp $2 "1.7" foundjava
    # We didn't find an adequate JDK in the registry
    # Assume we're now looking for OpenJDK
    # 1) Check in PATH
    StrCpy $JavaExe "java.exe"
    Call CheckJavaExe
    Pop $2
    StrCmp $2 1 foundjava
    # 2) Check in JAVA_HOME
    ReadEnvStr $2 "JAVA_HOME"
    StrCpy $JavaExe "$2\bin\java.exe"
    Call CheckJavaExe
    Pop $2
    StrCmp $2 1 foundjava
    # Still no suitable java!
    notjava:
    Push 0
    Goto done
    foundjava:
    Push 1
    done:
FunctionEnd

Function CheckJavaExe
    # Check whether a given java.exe exists and is suitable
    nsExec::ExecToStack '"$JavaExe" -version'
    Pop $1
    Pop $2
    StrCmp $1 "error" notjava
    ${StrLoc} $3 "$2" "1.6.0" ">"
    StrCmp $3 "" notjava6
    Goto checkopenjdk
    notjava6:
    ${StrLoc} $3 "$2" "1.7.0" ">"
    StrCmp $3 "" notjava7
    Goto checkopenjdk
    notjava7:
    # Check for java 8 here!
    Goto notjava
    checkopenjdk:
    ${StrLoc} $3 "$2" "OpenJDK" ">"
    StrCmp $3 "" notjava
    # Looks like we found our matching OpenJDK!
    Push 1
    Goto done
    notjava:
    Push 0
    done:
FunctionEnd

Function CheckOffice
    # 64bit arch with 64bit Office
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE" $1
            StrCmp $2 "OpenOffice.org" foundoffice
            StrCmp $2 "LibreOffice" foundoffice
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 64bit arch with 32bit Office
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE\Wow6432Node" $1
            StrCmp $2 "OpenOffice.org" foundoffice
            StrCmp $2 "LibreOffice" foundoffice
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 32bit arch with 32bit Office
    StrCpy $1 0
    ${Do}
        EnumRegKey $2 HKLM "SOFTWARE" $1
        StrCmp $2 "OpenOffice.org" foundoffice
        StrCmp $2 "LibreOffice" foundoffice
        IntOp $1 $1 + 1
    ${LoopWhile} $2 != ""
    # We didn't find OpenOffice.org or LibreOffice
    Push 0
    Goto done
    foundoffice:
    Push 1
    done:
    SetRegView 32
FunctionEnd

Function CheckPGSQL
    # 64bit arch with 64bit PostgreSQL
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE\PostgreSQL\Installations" $1
            ${StrLoc} $3 "$2" "postgresql" ">"
            StrCmp $3 "" checknext6464 foundpgsql
            checknext6464:
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 64bit arch with 32bit PostgreSQL
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE\Wow6432Node\PostgreSQL\Installations" $1
            ${StrLoc} $3 "$2" "postgresql" ">"
            StrCmp $3 "" checknext6432 foundpgsql
            checknext6432:
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 32bit arch with 32bit PostgreSQL
    StrCpy $1 0
    ${Do}
        EnumRegKey $2 HKLM "SOFTWARE\PostgreSQL\Installations" $1
        ${StrLoc} $3 "$2" "postgresql" ">"
        StrCmp $3 "" checknext3232 foundpgsql
        checknext3232:
        IntOp $1 $1 + 1
    ${LoopWhile} $2 != ""
    # We didn't find PostgreSQL
    Push 0
    Goto done
    foundpgsql:
    Push 1
    done:
    SetRegView 32
FunctionEnd

Function GetJava
    Var /GLOBAL JavaURL
    ${If} ${RunningX64}
        StrCpy $JavaURL "http://www.nuxeo.org/wininstall/java/jdk_x64.exe"
        StrCpy $2 "$TEMP/jdk-x64.exe"
    ${Else}
        StrCpy $JavaURL "http://www.nuxeo.org/wininstall/java/jdk_x86.exe"
        StrCpy $2 "$TEMP/jdk-x86.exe"
    ${EndIf}
    nsisdl::download /TIMEOUT=30000 $JavaURL $2
    Pop $R0
    StrCmp $R0 "success" +3
    MessageBox MB_OK "Java download failed: $R0"
    Quit
    ExecWait "$2 /qr ADDLOCAL=ToolsFeature"
    Delete $2
FunctionEnd

Function GetOffice
    StrCpy $2 "$TEMP/Office.exe"
    nsisdl::download /TIMEOUT=30000 "http://www.nuxeo.org/wininstall/LibO/LibO.exe" $2
    Pop $R0
    StrCmp $R0 "success" +3
    MessageBox MB_OK "LibreOffice download failed: $R0"
    Quit
    ExecWait "$2 /S /GUILEVEL=qr"
    Delete $2
FunctionEnd

Function GetPGSQL
    StrCpy $2 "$TEMP/postgresql-9.1.exe"
    nsisdl::download /TIMEOUT=30000 "http://www.nuxeo.org/wininstall/postgresql/postgresql-9.1.exe" $2
    Pop $R0
    StrCmp $R0 "success" +3
    MessageBox MB_OK "PostgreSQL download failed: $R0"
    Quit
    ExecWait "$2 --mode unattended --unattendedmodeui minimal --installer-language en --servicepassword postgres --superpassword postgres --datadir $\"$APPDATA\${PRODUCTNAME}\pgsql$\" --create_shortcuts 1"
    Delete $2
FunctionEnd

# Upgrades

Function CheckUpgradeFromNuxeo

    Var /GLOBAL PerformNXUpgrade
    StrCpy $PerformNXUpgrade 0
    ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" UninstallString
    IfFileExists "$2" showupgradefromnuxeo
    Goto skipupgradefromnxueo
    showupgradefromnuxeo:

        StrCpy $PerformNXUpgrade 1

        !insertmacro MUI_HEADER_TEXT $(nxupgrade_title) $(nxupgrade_subtitle)
        nsDialogs::Create 1018
        Pop $0
        ${If} $0 == error
            Abort
        ${EndIf}

        nsDialogs::CreateControl EDIT \
            "${DEFAULT_STYLES}|${WS_VSCROLL}|${ES_MULTILINE}|${ES_WANTRETURN}|${ES_READONLY}" \
            "${__NSD_Text_EXSTYLE}" \
            0 0 90% 80% $(nxupgrade_explain)
        Pop $1
        CreateFont $4 "MS Shell Dlg" 10 700
        SendMessage $1 ${WM_SETFONT} $4 0

        nsDialogs::Show

    skipupgradefromnxueo:

FunctionEnd

Function UpgradeFromNuxeo

    ${if} $PerformNXUpgrade != 0
        ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" UninstallString
        ReadRegStr $3 HKLM "${REGKEY}" Path
        ExecWait '"$2" /S _?=$3'
    ${EndIf}

FunctionEnd

Function CheckUpgradeFromDM

    StrCpy $PerformDMUpgrade 0
    ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Nuxeo DM" UninstallString
    IfFileExists "$2" checkdmanswered skipupgradefromdm
    checkdmanswered:
    ReadRegStr $2 HKLM "${REGKEY}" SkipDMUpgrade
    StrCmp $2 "" showupgradefromdm skipupgradefromdm
    showupgradefromdm:

        !insertmacro MUI_HEADER_TEXT $(dmupgrade_title) $(dmupgrade_subtitle)
        nsDialogs::Create 1018
        Pop $0
        ${If} $0 == error
            Abort
        ${EndIf}

        ${NSD_CreateLabel} 0 0 90% 12u $(dmupgrade_explain)
            Pop $0
            CreateFont $4 "MS Shell Dlg" 10 700
            SendMessage $0 ${WM_SETFONT} $4 0
        ${NSD_CreateRadioButton} 20u 40u 90% 12u $(dmupgrade_replace)
            Pop $radioreplace
        ${NSD_CreateLabel} 25u 53u 90% 12u $(dmupgrade_warn)
            Pop $0
        ${NSD_CreateRadioButton} 20u 70u 90% 12u $(dmupgrade_keep)
            Pop $radiokeep

        nsDialogs::Show

    skipupgradefromdm:

FunctionEnd

Function UpgradeFromDM

    ReadRegStr $2 HKLM "${REGKEY}" SkipDMUpgrade
    StrCmp $2 "" dodmupgradecheck skipdmupgradecheck

    dodmupgradecheck:
    ${NSD_GetState} $radioreplace $1
    ${NSD_GetState} $radiokeep $2
    ${If} $1 == ${BST_CHECKED}
        StrCpy $PerformDMUpgrade 1
    ${ElseIf} $2 == ${BST_CHECKED}
        StrCpy $PerformDMUpgrade 0
    ${Else}
        MessageBox MB_OK $(dmupgrade_mustselect)
        Abort
    ${EndIf}

    ${if} $PerformDMUpgrade != 0
        ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Nuxeo DM" UninstallString
        ReadRegStr $3 HKLM "SOFTWARE\Nuxeo DM" Path
        ExecWait "$3\bin\nuxeoctl.bat nogui stop"
        ExecWait '"$2" /S _?=$3'
    ${EndIf}

    skipdmupgradecheck:

FunctionEnd

# Dependencies selection

Function SelectDependencies
    Var /GLOBAL NeedDialog
    StrCpy $NeedDialog 0

    Var /GLOBAL HasJava
    StrCpy $javabox 0
    Call CheckJava
    Pop $HasJava
    ${If} $HasJava == 0
        StrCpy $NeedDialog 1
    ${EndIf}

    Var /GLOBAL HasOffice
    StrCpy $officebox 0
    Call CheckOffice
    Pop $HasOffice
    ${If} $HasOffice == 0
        StrCpy $NeedDialog 1
    ${EndIf}

    Var /GLOBAL HasPGSQL
    StrCpy $pgsqlbox 0
    Call CheckPGSQL
    Pop $HasPGSQL
    ${If} $HasPGSQL == 0
    ${AndIf} $PerformDMUpgrade == 0
        StrCpy $NeedDialog 1
    ${EndIf}

    # Some dependencies are not installed - we have stuff to do
    ${If} $NeedDialog == 1

        !insertmacro MUI_HEADER_TEXT $(dep_title) $(dep_subtitle)
        nsDialogs::Create 1018
        Pop $0
        ${If} $0 == error
            Abort
        ${EndIf}

        StrCpy $3 0

        ${If} $HasJava == 0
            ${NSD_CreateLabel} 0 $3u 90% 12u $(dep_explain_java)
            Pop $0
            CreateFont $4 "MS Shell Dlg" 10 700
            SendMessage $0 ${WM_SETFONT} $4 0
            IntOp $3 $3 + 13
            ${NSD_CreateCheckBox} 0 $3u 90% 12u "Java 6 Development Kit"
            Pop $javabox
            IntOp $3 $3 + 26
            ${NSD_Check} $javabox
        ${EndIf}

        ${If} $HasOffice == 0
            ${NSD_CreateLabel} 0 $3u 90% 12u $(dep_explain_office)
            Pop $0
            IntOp $3 $3 + 13
            ${NSD_CreateCheckBox} 0 $3u 90% 12u "LibreOffice"
            Pop $officebox
            IntOp $3 $3 + 26
            ${NSD_Check} $officebox
        ${EndIf}

        ${If} $HasPGSQL == 0
        ${AndIf} $PerformDMUpgrade == 0
            ${NSD_CreateLabel} 0 $3u 90% 12u $(dep_explain_pgsql)
            Pop $0
            IntOp $3 $3 + 13
            ${NSD_CreateCheckBox} 0 $3u 90% 12u "PostgreSQL"
            Pop $pgsqlbox
            IntOp $3 $3 + 26
            #${NSD_Check} $pgsqlbox
        ${EndIf}

        nsDialogs::Show

    ${EndIf}

FunctionEnd

Function GetSelectedDependencies

    ${If} $javabox != 0
        StrCpy $InstallJava 0
        ${NSD_GetState} $javabox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $InstallJava 1
        ${EndIf}
    ${EndIf}

    ${If} $officebox != 0
        StrCpy $InstallOffice 0
        ${NSD_GetState} $officebox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $InstallOffice 1
        ${EndIf}
    ${EndIf}

    ${If} $pgsqlbox != 0
        StrCpy $InstallPGSQL 0
        ${NSD_GetState} $pgsqlbox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $InstallPGSQL 1
        ${EndIf}
    ${EndIf}

FunctionEnd

# Dependencies Installation
# Called from section Main so we can have the progress dialogs

Function InstallDependencies
    ${If} $InstallJava == 1
        Call GetJava
    ${EndIf}
    ${If} $InstallOffice == 1
        Call GetOffice
    ${EndIf}
    ${If} $InstallPGSQL == 1
        Call GetPGSQL
    ${EndIf}
FunctionEnd

# Get PostgreSQL settings

Function GetPGSQLSettings
    StrCpy $PGPath ""
    StrCpy $PGUser ""
    # 64bit arch with 64bit PostgreSQL
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $5 "SOFTWARE\PostgreSQL\Installations\postgresql-8.4"
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE\PostgreSQL\Installations" $1
            StrCmp $2 "postgresql-8.4" foundpgsql
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        StrCpy $5 "SOFTWARE\PostgreSQL\Installations\postgresql-9.1"
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE\PostgreSQL\Installations" $1
            StrCmp $2 "postgresql-9.1" foundpgsql
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 64bit arch with 32bit PostgreSQL
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $5 "SOFTWARE\Wow6432Node\PostgreSQL\Installations\postgresql-8.4"
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE\Wow6432Node\PostgreSQL\Installations" $1
            StrCmp $2 "postgresql-8.4" foundpgsql
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        StrCpy $5 "SOFTWARE\Wow6432Node\PostgreSQL\Installations\postgresql-9.1"
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE\Wow6432Node\PostgreSQL\Installations" $1
            StrCmp $2 "postgresql-9.1" foundpgsql
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 32bit arch with 32bit PostgreSQL
    StrCpy $5 "SOFTWARE\PostgreSQL\Installations\postgresql-8.4"
    StrCpy $1 0
    ${Do}
        EnumRegKey $2 HKLM "SOFTWARE\PostgreSQL\Installations" $1
        StrCmp $2 "postgresql-8.4" foundpgsql
        IntOp $1 $1 + 1
    ${LoopWhile} $2 != ""
    StrCpy $5 "SOFTWARE\PostgreSQL\Installations\postgresql-9.1"
    StrCpy $1 0
    ${Do}
        EnumRegKey $2 HKLM "SOFTWARE\PostgreSQL\Installations" $1
        StrCmp $2 "postgresql-9.1" foundpgsql
        IntOp $1 $1 + 1
    ${LoopWhile} $2 != ""
    # We didn't find PostgreSQL
    DetailPrint "Error try to get PostgreSQL settings"
    Goto done
    foundpgsql:
    ReadRegStr $PGPath HKLM $5 "Base Directory"
    ReadRegStr $PGUser HKLM $5 "Super User"
    done:
    SetRegView 32
FunctionEnd

# Installer functions

Function .onInit
    InitPluginsDir
    !insertmacro MUI_LANGDLL_DISPLAY
    !insertmacro MULTIUSER_INIT
FunctionEnd

# Uninstall options selection

Function un.SelectRemove

    !insertmacro MUI_HEADER_TEXT $(rm_title) $(rm_subtitle)
    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    StrCpy $3 0

    ${NSD_CreateCheckBox} 0 $3u 90% 12u $(rm_tmp)
    Pop $rmtmpbox
    IntOp $3 $3 + 13
    ${NSD_CreateCheckBox} 0 $3u 90% 12u $(rm_data)
    Pop $rmdatabox
    IntOp $3 $3 + 13
    ${NSD_CreateCheckBox} 0 $3u 90% 12u $(rm_logs)
    Pop $rmlogsbox
    IntOp $3 $3 + 13
    ${NSD_CreateCheckBox} 0 $3u 90% 12u $(rm_conf)
    Pop $rmconfbox
    IntOp $3 $3 + 13

    nsDialogs::Show

FunctionEnd

Function un.GetSelectedRemove

    ${If} $rmtmpbox != 0
        StrCpy $RemoveTmp 0
        ${NSD_GetState} $rmtmpbox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $RemoveTmp 1
        ${EndIf}
    ${EndIf}

    ${If} $rmdatabox != 0
        StrCpy $RemoveData 0
        ${NSD_GetState} $rmdatabox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $RemoveData 1
        ${EndIf}
    ${EndIf}

    ${If} $rmlogsbox != 0
        StrCpy $RemoveLogs 0
        ${NSD_GetState} $rmlogsbox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $RemoveLogs 1
        ${EndIf}
    ${EndIf}

    ${If} $rmconfbox != 0
        StrCpy $RemoveConf 0
        ${NSD_GetState} $rmconfbox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $RemoveConf 1
        ${EndIf}
    ${EndIf}

FunctionEnd

# Uninstaller functions
Function un.onInit
    !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuGroup
    !insertmacro MUI_UNGETLANGUAGE
    !insertmacro MULTIUSER_UNINIT
    !insertmacro SELECT_UNSECTION Main ${UNSEC0000}
FunctionEnd

# Installer Language Strings

LangString ^UninstallLink ${LANG_ENGLISH} "Uninstall ${PRODUCTNAME}"
LangString ^UninstallLink ${LANG_FRENCH} "Désinstaller ${PRODUCTNAME}"
LangString ^UninstallLink ${LANG_SPANISH} "Desinstalar ${PRODUCTNAME}"
LangString ^UninstallLink ${LANG_GERMAN} "Demontieren Sie ${PRODUCTNAME}"
LangString ^UninstallLink ${LANG_ITALIAN} "Rimuovere ${PRODUCTNAME}"

# Other localizations

LicenseLangString license ${LANG_ENGLISH} "${NUXEO_RESOURCES_DIR}${SEP}LICENSE_en"
LicenseLangString license ${LANG_FRENCH} "${NUXEO_RESOURCES_DIR}${SEP}LICENSE_fr"
LicenseLangString license ${LANG_SPANISH} "${NUXEO_RESOURCES_DIR}${SEP}LICENSE_es"
LicenseLangString license ${LANG_GERMAN} "${NUXEO_RESOURCES_DIR}${SEP}LICENSE_de"
LicenseLangString license ${LANG_ITALIAN} "${NUXEO_RESOURCES_DIR}${SEP}LICENSE_it"

# English

LangString nxupgrade_title ${LANG_ENGLISH} "An existing installation of ${PRODUCTNAME} has been detected"
LangString nxupgrade_subtitle ${LANG_ENGLISH} "Uninstall and upgrade?"
LangString nxupgrade_explain ${LANG_ENGLISH} "To install your new version of ${PRODUCTNAME}, the installer needs to remove the previous one.$\r$\n$\r$\nThis will not affect your data.$\r$\n$\r$\nIf you prefer to keep your existing version, please cancel the installation."

LangString dmupgrade_title ${LANG_ENGLISH} "An installation of Nuxeo DM has been detected"
LangString dmupgrade_subtitle ${LANG_ENGLISH} "Uninstall Nuxeo DM and upgrade to ${PRODUCTNAME}?"
LangString dmupgrade_explain ${LANG_ENGLISH} "What do you want to do?"
LangString dmupgrade_replace ${LANG_ENGLISH} "Replace your existing Nuxeo DM with the new ${PRODUCTNAME}"
LangString dmupgrade_warn ${LANG_ENGLISH} "Note: this will not work with the embedded development database"
LangString dmupgrade_keep ${LANG_ENGLISH} "Install them side by side"
LangString dmupgrade_mustselect ${LANG_ENGLISH} "You must select an option."

LangString dep_title ${LANG_ENGLISH} "Dependencies"
LangString dep_subtitle ${LANG_ENGLISH} "Download and install the following dependencies"
LangString dep_explain_java ${LANG_ENGLISH} "WARNING: Could not detect JDK 6 or 7"
LangString dep_explain_office ${LANG_ENGLISH} "Required for document preview and conversion:"
LangString dep_explain_pgsql ${LANG_ENGLISH}  "Automatically configure PostgreSQL database:"

LangString rm_title ${LANG_ENGLISH} "Removal options"
LangString rm_subtitle ${LANG_ENGLISH} "Do you want to remove the following?"
LangString rm_tmp ${LANG_ENGLISH} "Temporary files"
LangString rm_data ${LANG_ENGLISH} "Data files"
LangString rm_logs ${LANG_ENGLISH} "Log files"
LangString rm_conf ${LANG_ENGLISH} "Configuration files"

# French

LangString nxupgrade_title ${LANG_FRENCH} "Une installation de ${PRODUCTNAME} a été détectée"
LangString nxupgrade_subtitle ${LANG_FRENCH} "Désinstaller et mettre à jour?"
LangString nxupgrade_explain ${LANG_FRENCH} "Pour installer la nouvelle version de ${PRODUCTNAME}, l'installeur doit supprimer la précédente.$\r$\n$\r$\nCeci n'affectera pas vos données.$\r$\n$\r$\nSi vous préferez garder la version actuelle, veuillez annuler l'installation."

LangString dmupgrade_title ${LANG_FRENCH} "Une installation de Nuxeo DM a été détectée"
LangString dmupgrade_subtitle ${LANG_FRENCH} "Désinstaller Nuxeo DM et mettre à jour vers ${PRODUCTNAME}?"
LangString dmupgrade_explain ${LANG_FRENCH} "Comment voulez-vous procéder?"
LangString dmupgrade_replace ${LANG_FRENCH} "Remplacer Nuxeo DM par ${PRODUCTNAME}"
LangString dmupgrade_warn ${LANG_FRENCH} "Note: ne fonctionne pas avec la base de données de développement embarquée"
LangString dmupgrade_keep ${LANG_FRENCH} "Les installer en parallèle"
LangString dmupgrade_mustselect ${LANG_FRENCH} "Vous devez choisir une option."

LangString dep_title ${LANG_FRENCH} "Dépendances"
LangString dep_subtitle ${LANG_FRENCH} "Télécharger et installer les dépendances suivantes"
LangString dep_explain_java ${LANG_FRENCH} "ATTENTION: JDK 6 ou 7 non détecté"
LangString dep_explain_office ${LANG_FRENCH} "Nécessaire pour la prévisualisation et la conversion des documents:"
LangString dep_explain_pgsql ${LANG_FRENCH}  "Configurer une base PostgreSQL automatiquement:"

LangString rm_title ${LANG_FRENCH} "Options de suppression"
LangString rm_subtitle ${LANG_FRENCH} "Voulez-vous supprimer les éléments suivants ?"
LangString rm_tmp ${LANG_FRENCH} "Fichiers temporaires"
LangString rm_data ${LANG_FRENCH} "Fichiers de données"
LangString rm_logs ${LANG_FRENCH} "Fichiers de log"
LangString rm_conf ${LANG_FRENCH} "Fichiers de configuration"

# Spanish

LangString nxupgrade_title ${LANG_SPANISH} "An existing installation of ${PRODUCTNAME} has been detected"
LangString nxupgrade_subtitle ${LANG_SPANISH} "Uninstall and upgrade?"
LangString nxupgrade_explain ${LANG_SPANISH} "To install your new version of ${PRODUCTNAME}, the installer needs to remove the previous one.$\r$\n$\r$\nThis will not affect your data.$\r$\n$\r$\nIf you prefer to keep your existing version, please cancel the installation."

LangString dmupgrade_title ${LANG_SPANISH} "An installation of Nuxeo DM has been detected"
LangString dmupgrade_subtitle ${LANG_SPANISH} "Uninstall Nuxeo DM and upgrade to ${PRODUCTNAME}?"
LangString dmupgrade_explain ${LANG_SPANISH} "What do you want to do?"
LangString dmupgrade_replace ${LANG_SPANISH} "Replace your existing Nuxeo DM with the new ${PRODUCTNAME}"
LangString dmupgrade_warn ${LANG_SPANISH} "Note: this will not work with the embedded development database"
LangString dmupgrade_keep ${LANG_SPANISH} "Install them side by side"
LangString dmupgrade_mustselect ${LANG_SPANISH} "You must select an option."

LangString dep_title ${LANG_SPANISH} "Dependencias"
LangString dep_subtitle ${LANG_SPANISH} "AVISO: Descargue e instale las siguientes dependencias"
LangString dep_explain_java ${LANG_SPANISH} "No se ha detectado JDK 6 or 7"
LangString dep_explain_office ${LANG_SPANISH} "Requerido para la conversión y previsualización de documentos:"
LangString dep_explain_pgsql ${LANG_SPANISH}  "Configurar automáticamente la base de datos PostgreSQL:"

LangString rm_title ${LANG_SPANISH} "Opciones de eliminado"
LangString rm_subtitle ${LANG_SPANISH} "¿Desea eliminar el siguiente?"
LangString rm_tmp ${LANG_SPANISH} "Archivos temporales"
LangString rm_data ${LANG_SPANISH} "Repositorio de datos"
LangString rm_logs ${LANG_SPANISH} "Archivos de logs"
LangString rm_conf ${LANG_SPANISH} "Archivos de configuración"

# German

LangString nxupgrade_title ${LANG_GERMAN} "An existing installation of ${PRODUCTNAME} has been detected"
LangString nxupgrade_subtitle ${LANG_GERMAN} "Uninstall and upgrade?"
LangString nxupgrade_explain ${LANG_GERMAN} "To install your new version of ${PRODUCTNAME}, the installer needs to remove the previous one.$\r$\n$\r$\nThis will not affect your data.$\r$\n$\r$\nIf you prefer to keep your existing version, please cancel the installation."

LangString dmupgrade_title ${LANG_GERMAN} "An installation of Nuxeo DM has been detected"
LangString dmupgrade_subtitle ${LANG_GERMAN} "Uninstall Nuxeo DM and upgrade to ${PRODUCTNAME}?"
LangString dmupgrade_explain ${LANG_GERMAN} "What do you want to do?"
LangString dmupgrade_replace ${LANG_GERMAN} "Replace your existing Nuxeo DM with the new ${PRODUCTNAME}"
LangString dmupgrade_warn ${LANG_GERMAN} "Note: this will not work with the embedded development database"
LangString dmupgrade_keep ${LANG_GERMAN} "Install them side by side"
LangString dmupgrade_mustselect ${LANG_GERMAN} "You must select an option."

LangString dep_title ${LANG_GERMAN} "Abhängigkeiten"
LangString dep_subtitle ${LANG_GERMAN} "Lädt herunter und installiert folgende Abhängigkeiten"
LangString dep_explain_java ${LANG_GERMAN} "ACHTUNG: JDK 6 oder 7 konnte nicht gefunden werden"
LangString dep_explain_office ${LANG_GERMAN} "Wird für die Dokumentvorschau und Konvertierung benötigt:"
LangString dep_explain_pgsql ${LANG_GERMAN}  "Sie konfigurieren automatisch PostgreSQL Datenbank:"

LangString rm_title ${LANG_GERMAN} "Demontierbare Optionen"
LangString rm_subtitle ${LANG_GERMAN} "Wollen Sie das folgende demontieren ?"
LangString rm_tmp ${LANG_GERMAN} "TMP löschen"
LangString rm_data ${LANG_GERMAN} "Daten löschen"
LangString rm_logs ${LANG_GERMAN} "Log-Infos löschen"
LangString rm_conf ${LANG_GERMAN} "Konfiguration löschen"

# Italian

LangString nxupgrade_title ${LANG_ITALIAN} "An existing installation of ${PRODUCTNAME} has been detected"
LangString nxupgrade_subtitle ${LANG_ITALIAN} "Uninstall and upgrade?"
LangString nxupgrade_explain ${LANG_ITALIAN} "To install your new version of ${PRODUCTNAME}, the installer needs to remove the previous one.$\r$\n$\r$\nThis will not affect your data.$\r$\n$\r$\nIf you prefer to keep your existing version, please cancel the installation."

LangString dmupgrade_title ${LANG_ITALIAN} "An installation of Nuxeo DM has been detected"
LangString dmupgrade_subtitle ${LANG_ITALIAN} "Uninstall Nuxeo DM and upgrade to ${PRODUCTNAME}?"
LangString dmupgrade_explain ${LANG_ITALIAN} "What do you want to do?"
LangString dmupgrade_replace ${LANG_ITALIAN} "Replace your existing Nuxeo DM with the new ${PRODUCTNAME}"
LangString dmupgrade_warn ${LANG_ITALIAN} "Note: this will not work with the embedded development database"
LangString dmupgrade_keep ${LANG_ITALIAN} "Install them side by side"
LangString dmupgrade_mustselect ${LANG_ITALIAN} "You must select an option."

LangString dep_title ${LANG_ITALIAN} "Dipendenze"
LangString dep_subtitle ${LANG_ITALIAN} "Scarica ed installa le dipendenze seguenti"
LangString dep_explain_java ${LANG_ITALIAN} "ATTENZIONE: Impossibile rilevare JDK 6 or 7"
LangString dep_explain_office ${LANG_ITALIAN} "Richiesto per l'anteprima e la conversione del documento:"
LangString dep_explain_pgsql ${LANG_ITALIAN}  "Configura automaticamente il database PostgreSQL:"

LangString rm_title ${LANG_ITALIAN} "Opzioni di rimozione"
LangString rm_subtitle ${LANG_ITALIAN} "Vuoi rimuovere il seguente?"
LangString rm_tmp ${LANG_ITALIAN} "file temporanei"
LangString rm_data ${LANG_ITALIAN} "file di Dati"
LangString rm_logs ${LANG_ITALIAN} "file di Log"
LangString rm_conf ${LANG_ITALIAN} "file di Configurazione"

