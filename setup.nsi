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
VIAddVersionKey /LANG=${LANG_ENGLISH} LegalCopyright "Nuxeo SA 2006-2011"
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

    # Delete nuxeo.conf from the main product tree
    Delete bin\nuxeo.conf
    # and add it to $APPDATA (without overwriting existing ones)
    IfFileExists "$APPDATA\${PRODUCTNAME}\conf\nuxeo.conf" nuxeoconfdone
    SetOutPath "$APPDATA\${PRODUCTNAME}\conf"
    SetOverwrite Off # just to be safe
    File ${NUXEO_DISTRIBUTION_DIR}${SEP}bin${SEP}nuxeo.conf
    FileOpen $2 "$APPDATA\${PRODUCTNAME}\conf\nuxeo.conf" a
    FileSeek $2 0 END
    FileWrite $2 "$\r$\n"
    FileWrite $2 "nuxeo.data.dir=$APPDATA\${PRODUCTNAME}\data$\r$\n"
    FileWrite $2 "nuxeo.log.dir=$APPDATA\${PRODUCTNAME}\logs$\r$\n"
    FileWrite $2 "nuxeo.tmp.dir=$APPDATA\${PRODUCTNAME}\tmp$\r$\n"
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
    nuxeoconfdone:
    AccessControl::GrantOnFile "$APPDATA\${PRODUCTNAME}" "(BU)" "FullAccess"
    WriteRegStr HKLM "${REGKEY}" ConfigFile "$APPDATA\${PRODUCTNAME}\conf\nuxeo.conf"
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
    SetOutPath "$APPDATA\${PRODUCTNAME}\tmp"
    # Give full access to group "Builtin Users"
    AccessControl::GrantOnFile "$APPDATA\${PRODUCTNAME}\tmp" "(BU)" "FullAccess"

    # PostgreSQL setup :
    ${If} $InstallPGSQL == 1
        Call GetPGSQLSettings
        # stop postgresql
        ExecWait "sc stop postgresql-8.4"
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
        ExecWait "sc start postgresql-8.4"
        Sleep 5000 # Hope the service will be started after 5 seconds
        # run db creation script
        ExecWait "$PGPath\bin\psql.exe -h localhost -U $PGUser -f $\"$INSTDIR\contrib\create_db.sql$\" template1"
    ${EndIf}

    SetOutPath $INSTDIR\bin
    CreateShortcut "$DESKTOP\${PRODUCTNAME}.lnk" "$INSTDIR\bin\Start Nuxeo.bat" "" "$INSTDIR\${NUXEO_PRODUCT_ICON}"
    WriteRegStr HKLM "${REGKEY}\Components" Main 1

    WriteRegStr HKLM "${REGKEY}" Path $INSTDIR
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
    ${If} $RemoveTmp == 1
        RmDir /r /REBOOTOK "$APPDATA\${PRODUCTNAME}\tmp"
    ${EndIf}
    ${If} $RemoveData == 1
        RmDir /r /REBOOTOK "$APPDATA\${PRODUCTNAME}\data"
    ${EndIf}
    ${If} $RemoveLogs == 1
        RmDir /r /REBOOTOK "$APPDATA\${PRODUCTNAME}\logs"
    ${EndIf}
    ${If} $RemoveConf == 1
        RmDir /r /REBOOTOK "$APPDATA\${PRODUCTNAME}\conf"
    ${EndIf}
    RmDir "$APPDATA\${PRODUCTNAME}"

    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\${PRODUCTNAME}.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\$(^UninstallLink).lnk"
    Delete /REBOOTOK $INSTDIR\uninstall.exe
    RmDir /REBOOTOK $INSTDIR
    DeleteRegValue HKLM "${REGKEY}" StartMenuGroup
    DeleteRegValue HKLM "${REGKEY}" Path
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
    # BundleIds for Oracle Java6 JDK 6u27 : x64=52417, i586=52416
    # BundleIds for Oracle Java7 JDK 7u1 : x64=55071, i586=55070
    ${If} ${RunningX64}
        StrCpy $JavaURL "http://javadl.sun.com/webapps/download/AutoDL?BundleId=55071"
        StrCpy $2 "$TEMP/jdk-x64.exe"
    ${Else}
        StrCpy $JavaURL "http://javadl.sun.com/webapps/download/AutoDL?BundleId=55070"
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
    nsisdl::download /TIMEOUT=30000 "http://download.documentfoundation.org/libreoffice/stable/3.4.4/win/x86/LibO_3.4.4_Win_x86_install_multi.exe" $2
    Pop $R0
    StrCmp $R0 "success" +3
    MessageBox MB_OK "LibreOffice download failed: $R0"
    Quit
    ExecWait "$2 /S /GUILEVEL=qr"
    Delete $2
FunctionEnd

Function GetPGSQL
    StrCpy $2 "$TEMP/postgresql-8.4.exe"
    nsisdl::download /TIMEOUT=30000 "http://get.enterprisedb.com/postgresql/postgresql-8.4.9-1-windows.exe" $2
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

LangString dep_title ${LANG_ENGLISH} "Dependencies"
LangString dep_subtitle ${LANG_ENGLISH} "Download and install the following dependencies"
LangString dep_explain_java ${LANG_ENGLISH} "WARNING: Could not detect JDK 6 or 7"
LangString dep_explain_office ${LANG_ENGLISH} "Required for document preview and conversion:"
LangString dep_explain_pgsql ${LANG_ENGLISH}  "EXPERIMENTAL - Automatically configure PostgreSQL database:"

LangString rm_title ${LANG_ENGLISH} "Removal options"
LangString rm_subtitle ${LANG_ENGLISH} "Do you want to remove the following?"
LangString rm_tmp ${LANG_ENGLISH} "Temporary files"
LangString rm_data ${LANG_ENGLISH} "Data files"
LangString rm_logs ${LANG_ENGLISH} "Log files"
LangString rm_conf ${LANG_ENGLISH} "Configuration files"

# French

LangString dep_title ${LANG_FRENCH} "Dépendances"
LangString dep_subtitle ${LANG_FRENCH} "Télécharger et installer les dépendances suivantes"
LangString dep_explain_java ${LANG_FRENCH} "ATTENTION: JDK 6 ou 7 non détecté"
LangString dep_explain_office ${LANG_FRENCH} "Nécessaire pour la prévisualisation et la conversion des documents:"
LangString dep_explain_pgsql ${LANG_FRENCH}  "EXPÉRIMENTAL - Configurer une base PostgreSQL automatiquement:"

LangString rm_title ${LANG_FRENCH} "Options de suppression"
LangString rm_subtitle ${LANG_FRENCH} "Voulez-vous supprimer les éléments suivants ?"
LangString rm_tmp ${LANG_FRENCH} "Fichiers temporaires"
LangString rm_data ${LANG_FRENCH} "Fichiers de données"
LangString rm_logs ${LANG_FRENCH} "Fichiers de log"
LangString rm_conf ${LANG_FRENCH} "Fichiers de configuration"

# Spanish

LangString dep_title ${LANG_SPANISH} "Dependencias"
LangString dep_subtitle ${LANG_SPANISH} "AVISO: Descargue e instale las siguientes dependencias"
LangString dep_explain_java ${LANG_SPANISH} "No se ha detectado JDK 6 or 7"
LangString dep_explain_office ${LANG_SPANISH} "Requerido para la conversión y previsualización de documentos:"
LangString dep_explain_pgsql ${LANG_SPANISH}  "EXPERIMENTAL - Configurar automáticamente la base de datos PostgreSQL:"

LangString rm_title ${LANG_SPANISH} "Opciones de eliminado"
LangString rm_subtitle ${LANG_SPANISH} "¿Desea eliminar el siguiente?"
LangString rm_tmp ${LANG_SPANISH} "Archivos temporales"
LangString rm_data ${LANG_SPANISH} "Repositorio de datos"
LangString rm_logs ${LANG_SPANISH} "Archivos de logs"
LangString rm_conf ${LANG_SPANISH} "Archivos de configuración"

# German

LangString dep_title ${LANG_GERMAN} "Abhängigkeiten"
LangString dep_subtitle ${LANG_GERMAN} "Lädt herunter und installiert folgende Abhängigkeiten"
LangString dep_explain_java ${LANG_GERMAN} "ACHTUNG: JDK 6 oder 7 konnte nicht gefunden werden"
LangString dep_explain_office ${LANG_GERMAN} "Wird für die Dokumentvorschau und Konvertierung benötigt:"
LangString dep_explain_pgsql ${LANG_GERMAN}  "EXPERIMENTELL - Sie konfigurieren automatisch PostgreSQL Datenbank:"

LangString rm_title ${LANG_GERMAN} "Demontierbare Optionen"
LangString rm_subtitle ${LANG_GERMAN} "Wollen Sie das folgende demontieren ?"
LangString rm_tmp ${LANG_GERMAN} "TMP löschen"
LangString rm_data ${LANG_GERMAN} "Daten löschen"
LangString rm_logs ${LANG_GERMAN} "Log-Infos löschen"
LangString rm_conf ${LANG_GERMAN} "Konfiguration löschen"

# Italian

LangString dep_title ${LANG_ITALIAN} "Dipendenze"
LangString dep_subtitle ${LANG_ITALIAN} "Scarica ed installa le dipendenze seguenti"
LangString dep_explain_java ${LANG_ITALIAN} "ATTENZIONE: Impossibile rilevare JDK 6 or 7"
LangString dep_explain_office ${LANG_ITALIAN} "Richiesto per l'anteprima e la conversione del documento:"
LangString dep_explain_pgsql ${LANG_ITALIAN}  "SPERIMENTALE - Configura automaticamente il database PostgreSQL:"

LangString rm_title ${LANG_ITALIAN} "Opzioni di rimozione"
LangString rm_subtitle ${LANG_ITALIAN} "Vuoi rimuovere il seguente?"
LangString rm_tmp ${LANG_ITALIAN} "file temporanei"
LangString rm_data ${LANG_ITALIAN} "file di Dati"
LangString rm_logs ${LANG_ITALIAN} "file di Log"
LangString rm_conf ${LANG_ITALIAN} "file di Configurazione"

