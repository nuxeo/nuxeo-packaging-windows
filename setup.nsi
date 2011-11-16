!include setup.nsh

# General Symbol Definitions
!define REGKEY "SOFTWARE\$(^Name)"
!define COMPANY Nuxeo
!define URL http://www.nuxeo.com/

# MultiUser Symbol Definitions
!define MULTIUSER_EXECUTIONLEVEL Admin
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_KEY "${REGKEY}"
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_VALUENAME MultiUserInstallMode
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_INSTDIR "$(^Name)"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_KEY "${REGKEY}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_VALUE "Path"

# MUI Symbol Definitions
!define MUI_ICON "${NUXEO_RESOURCES_DIR}${SEP}install.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NUXEO_RESOURCES_DIR}${SEP}startfinish.bmp"
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_STARTMENUPAGE_REGISTRY_ROOT HKLM
!define MUI_STARTMENUPAGE_REGISTRY_KEY ${REGKEY}
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME StartMenuGroup
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "$(^Name)"
!define MUI_UNICON "${NUXEO_RESOURCES_DIR}${SEP}uninstall.ico"
!define MUI_UNFINISHPAGE_NOAUTOCLOSE
!define MUI_LANGDLL_REGISTRY_ROOT HKLM
!define MUI_LANGDLL_REGISTRY_KEY ${REGKEY}
!define MUI_LANGDLL_REGISTRY_VALUENAME InstallerLanguage

# Nuxeo
!define NUXEO_PRODUCT_ICON "nuxeo-dm.ico"

# Included files
!include x64.nsh
!include MultiUser.nsh
!include Sections.nsh
!include MUI2.nsh

# Reserved Files
!insertmacro MUI_RESERVEFILE_LANGDLL

# Variables
Var StartMenuGroup

Var javabox
Var InstallJava
Var ooobox
Var InstallOOo
Var imagickbox
Var InstallImageMagick

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
InstallDir "$(^Name)"
CRCCheck on
XPStyle on
ShowInstDetails show
VIAddVersionKey /LANG=${LANG_ENGLISH} ProductName "$(^Name)"
VIAddVersionKey /LANG=${LANG_ENGLISH} ProductVersion "${VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} CompanyName "${COMPANY}"
VIAddVersionKey /LANG=${LANG_ENGLISH} CompanyWebsite "${URL}"
VIAddVersionKey /LANG=${LANG_ENGLISH} FileVersion "${VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} FileDescription ""
VIAddVersionKey /LANG=${LANG_ENGLISH} LegalCopyright ""
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
    IfFileExists "$APPDATA\$(^Name)\conf\nuxeo.conf" nuxeoconfdone
    SetOutPath "$APPDATA\$(^Name)\conf"
    SetOverwrite Off # just to be safe
    File ${NUXEO_DISTRIBUTION_DIR}${SEP}bin${SEP}nuxeo.conf
    FileOpen $2 "$APPDATA\$(^Name)\conf\nuxeo.conf" a
    FileSeek $2 0 END
    FileWrite $2 "$\r$\n"
    FileWrite $2 "nuxeo.data.dir=$APPDATA\$(^Name)\data$\r$\n"
    FileWrite $2 "nuxeo.log.dir=$APPDATA\$(^Name)\logs$\r$\n"
    FileWrite $2 "nuxeo.tmp.dir=$APPDATA\$(^Name)\tmp$\r$\n"
    ${If} $InstallPGSQL == 1
        FileWrite $2 "nuxeo.templates=default,postgresql$\r$\n"
        FileWrite $2 "nuxeo.db.host=localhost$\r$\n"
        FileWrite $2 "nuxeo.db.port=5432$\r$\n"
        FileWrite $2 "nuxeo.db.name=nuxeodm$\r$\n"
        FileWrite $2 "nuxeo.db.user=nuxeodm$\r$\n"
        FileWrite $2 "nuxeo.db.password=nuxeodm$\r$\n"
    ${EndIf}
    FileWrite $2 "nuxeo.wizard.done=false$\r$\n"
    FileClose $2
    nuxeoconfdone:
    AccessControl::GrantOnFile "$APPDATA\$(^Name)" "(BU)" "FullAccess"
    WriteRegStr HKLM "${REGKEY}" ConfigFile "$APPDATA\$(^Name)\conf\nuxeo.conf"
    SetOverwrite On

    # Include local 3rd parties (pdftohtml, ...)
    SetOutPath "$INSTDIR\3rdparty"
    File /r ${NUXEO_RESOURCES_DIR}${SEP}3rdparty${SEP}*

    # Include default PostgreSQL config file and db setup script
    SetOutPath "$INSTDIR\contrib"
    File ${NUXEO_RESOURCES_DIR}${SEP}contrib${SEP}*

    # Create a new file so NuxeoCtl can find out what product is running
    FileOpen $2 "$INSTDIR\bin\ProductName.txt" w
    FileWrite $2 "$(^Name)"
    FileClose $2

    # Create tmp dir
    SetOutPath "$APPDATA\$(^Name)\tmp"
    # Give full access to group "Builtin Users"
    AccessControl::GrantOnFile "$APPDATA\$(^Name)\tmp" "(BU)" "FullAccess"

    # PostgreSQL setup :
    ${If} $InstallPGSQL == 1
        Call GetPGSQLSettings
        # stop postgresql
        ExecWait "sc stop postgresql-8.4"
        Sleep 5000 # Hope the service will be stopped after 5 seconds
        # overwrite postgresql.conf with ours
        SetOutPath $APPDATA\$(^Name)\pgsql
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
    CreateShortcut "$DESKTOP\$(^Name).lnk" "$INSTDIR\bin\Start Nuxeo.bat" "" "$INSTDIR\${NUXEO_PRODUCT_ICON}"
    WriteRegStr HKLM "${REGKEY}\Components" Main 1

SectionEnd

Section -post SEC0001
    WriteRegStr HKLM "${REGKEY}" Path $INSTDIR
    SetOutPath $INSTDIR
    WriteUninstaller $INSTDIR\uninstall.exe
    StrCpy $0 "manual"
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    SetOutPath $SMPROGRAMS\$StartMenuGroup
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\$(^Name).lnk" "$INSTDIR\bin\Start Nuxeo.bat" "" "$INSTDIR\${NUXEO_PRODUCT_ICON}"
	CreateShortcut "$SMPROGRAMS\$StartMenuGroup\$(^UninstallLink).lnk" $INSTDIR\uninstall.exe
    !insertmacro MUI_STARTMENU_WRITE_END
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayName "$(^Name)"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayVersion "${VERSION}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" Publisher "${COMPANY}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" URLInfoAbout "${URL}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayIcon $INSTDIR\uninstall.exe
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" UninstallString $INSTDIR\uninstall.exe
    WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" NoModify 1
    WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" NoRepair 1
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
    Delete /REBOOTOK "$DESKTOP\$(^Name).lnk"
    RmDir /r /REBOOTOK $INSTDIR
    DeleteRegValue HKLM "${REGKEY}\Components" Main
    ${If} $RemoveTmp == 1
        RmDir /r /REBOOTOK "$APPDATA\$(^Name)\tmp"
    ${EndIf}
    ${If} $RemoveData == 1
        RmDir /r /REBOOTOK "$APPDATA\$(^Name)\data"
    ${EndIf}
    ${If} $RemoveLogs == 1
        RmDir /r /REBOOTOK "$APPDATA\$(^Name)\logs"
    ${EndIf}
    ${If} $RemoveConf == 1
        RmDir /r /REBOOTOK "$APPDATA\$(^Name)\conf"
    ${EndIf}
    RmDir "$APPDATA\$(^Name)"
SectionEnd

Section -un.post UNSEC0001
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\$(^Name).lnk"
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
        #StrCmp $2 "1.5" foundjava
        StrCmp $2 "1.6" foundjava
    ${EndIf}
    # 64bit arch with 32bit JDK
    ${If} ${RunningX64}
        SetRegView 64
        ReadRegStr $2 HKLM \
                   "SOFTWARE\Wow6432Node\JavaSoft\Java Development Kit" \
                   "CurrentVersion"
        SetRegView 32
        #StrCmp $2 "1.5" foundjava
        StrCmp $2 "1.6" foundjava
    ${EndIf}
    # 32bit arch with 32bit JDK
    ReadRegStr $2 HKLM \
           "SOFTWARE\JavaSoft\Java Development Kit" \
           "CurrentVersion"
    #StrCmp $2 "1.5" foundjava
    StrCmp $2 "1.6" foundjava
    # We didn't find a JDK
    Push 0
    Goto done
    foundjava:
    Push 1
    done:
FunctionEnd

Function CheckOOo
    # 64bit arch with 64bit OOo
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE" $1
            StrCmp $2 "OpenOffice.org" foundooo
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 64bit arch with 32bit OOo
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE\Wow6432Node" $1
            StrCmp $2 "OpenOffice.org" foundooo
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 32bit arch with 32bit OOo
    StrCpy $1 0
    ${Do}
        EnumRegKey $2 HKLM "SOFTWARE" $1
        StrCmp $2 "OpenOffice.org" foundooo
        IntOp $1 $1 + 1
    ${LoopWhile} $2 != ""
    # We didn't find OpenOffice.org
    Push 0
    Goto done
    foundooo:
    Push 1
    done:
    SetRegView 32
FunctionEnd

Function CheckImageMagick
    # 64bit arch with 64bit ImageMagick
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE" $1
            StrCmp $2 "ImageMagick" foundimagick
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 64bit arch with 32bit ImageMagick
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $1 0
        ${Do}
            EnumRegKey $2 HKLM "SOFTWARE\Wow6432Node" $1
            StrCmp $2 "ImageMagick" foundimagick
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 32bit arch with 32bit ImageMagick
    StrCpy $1 0
    ${Do}
        EnumRegKey $2 HKLM "SOFTWARE" $1
        StrCmp $2 "ImageMagick" foundimagick
        IntOp $1 $1 + 1
    ${LoopWhile} $2 != ""
    # We didn't find ImageMagick
    Push 0
    Goto done
    foundimagick:
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
            StrCmp $2 "postgresql-8.4" foundpgsql
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
            StrCmp $2 "postgresql-8.4" foundpgsql
            IntOp $1 $1 + 1
        ${LoopWhile} $2 != ""
        SetRegView 32
    ${EndIf}
    # 32bit arch with 32bit PostgreSQL
    StrCpy $1 0
    ${Do}
        EnumRegKey $2 HKLM "SOFTWARE\PostgreSQL\Installations" $1
        StrCmp $2 "postgresql-8.4" foundpgsql
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

Function GetOOo
    StrCpy $2 "$TEMP/OOo.exe"
    nsisdl::download /TIMEOUT=30000 "http://www.nuxeo.org/wininstall/OOo/OOo.exe" $2
    Pop $R0
    StrCmp $R0 "success" +3
    MessageBox MB_OK "OpenOffice.org download failed: $R0"
    Quit
    ExecWait "$2 /S /GUILEVEL=qr"
    Delete $2
FunctionEnd

Function GetImageMagick
    StrCpy $2 "$TEMP/ImageMagick.exe"
    nsisdl::download /TIMEOUT=30000 "http://www.nuxeo.org/wininstall/imagemagick/ImageMagick.exe" $2
    Pop $R0
    StrCmp $R0 "success" +3
    MessageBox MB_OK "ImageMagick download failed: $R0"
    Quit
    ExecWait "$2 /SILENT"
    Delete $2
FunctionEnd

Function GetPGSQL
    StrCpy $2 "$TEMP/postgresql-8.4.exe"
    nsisdl::download /TIMEOUT=30000 "http://www.nuxeo.org/wininstall/pgsql/postgresql-8.4.exe" $2
    Pop $R0
    StrCmp $R0 "success" +3
    MessageBox MB_OK "PostgreSQL download failed: $R0"
    Quit
    ExecWait "$2 --mode unattended --unattendedmodeui minimal --installer-language en --servicepassword postgres --superpassword postgres --datadir $\"$APPDATA\$(^Name)\pgsql$\" --create_shortcuts 1"
    Delete $2
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

    Var /GLOBAL HasOOo
    StrCpy $ooobox 0
    Call CheckOOo
    Pop $HasOOo
    ${If} $HasOOo == 0
        StrCpy $NeedDialog 1
    ${EndIf}

    Var /GLOBAL HasImageMagick
    StrCpy $imagickbox 0
    Call CheckImageMagick
    Pop $HasImageMagick
    ${If} $HasImageMagick == 0
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
            IntOp $3 $3 + 13
            ${NSD_CreateCheckBox} 0 $3u 90% 12u "Java 6 Development Kit"
            Pop $javabox
            IntOp $3 $3 + 26
            ${NSD_Check} $javabox
        ${EndIf}

        ${If} $HasOOo == 0
            ${NSD_CreateLabel} 0 $3u 90% 12u $(dep_explain_ooo)
            Pop $0
            IntOp $3 $3 + 13
            ${NSD_CreateCheckBox} 0 $3u 90% 12u "OpenOffice.org"
            Pop $ooobox
            IntOp $3 $3 + 26
            ${NSD_Check} $ooobox
        ${EndIf}
        
        ${If} $HasImageMagick == 0
            ${NSD_CreateLabel} 0 $3u 90% 12u $(dep_explain_imagick)
            Pop $0
            IntOp $3 $3 + 13
            ${NSD_CreateCheckBox} 0 $3u 90% 12u "ImageMagick"
            Pop $imagickbox
            IntOp $3 $3 + 26
            ${NSD_Check} $imagickbox
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
    
    ${If} $ooobox != 0
        StrCpy $InstallOOo 0
        ${NSD_GetState} $ooobox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $InstallOOo 1
        ${EndIf}
    ${EndIf}
    
    ${If} $imagickbox != 0
        StrCpy $InstallImageMagick 0
        ${NSD_GetState} $imagickbox $0
        ${If} $0 == ${BST_CHECKED}
            StrCpy $InstallImageMagick 1
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
    ${If} $InstallOOo == 1
        Call GetOOo
    ${EndIf}
    ${If} $InstallImageMagick == 1
        Call GetImageMagick
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
# TODO Update the Language Strings with the appropriate translations.

LangString ^UninstallLink ${LANG_ENGLISH} "Uninstall $(^Name)"
LangString ^UninstallLink ${LANG_FRENCH} "Désinstaller $(^Name)"
LangString ^UninstallLink ${LANG_SPANISH} "Uninstall $(^Name)"
LangString ^UninstallLink ${LANG_GERMAN} "Uninstall $(^Name)"
LangString ^UninstallLink ${LANG_ITALIAN} "Uninstall $(^Name)"

# Other localizations

LicenseLangString license ${LANG_ENGLISH} "${NUXEO_RESOURCES_DIR}${SEP}LICENSE_en"
LicenseLangString license ${LANG_FRENCH} "${NUXEO_RESOURCES_DIR}${SEP}LICENSE_fr"
LicenseLangString license ${LANG_SPANISH} "${NUXEO_RESOURCES_DIR}${SEP}LICENSE_es"
LicenseLangString license ${LANG_GERMAN} "${NUXEO_RESOURCES_DIR}${SEP}LICENSE_de"
LicenseLangString license ${LANG_ITALIAN} "${NUXEO_RESOURCES_DIR}${SEP}LICENSE_it"

# English

LangString dep_title ${LANG_ENGLISH} "Dependencies"
LangString dep_subtitle ${LANG_ENGLISH} "Download and install the following dependencies"
LangString dep_explain_java ${LANG_ENGLISH} "Required for the program to run:"
LangString dep_explain_ooo ${LANG_ENGLISH} "Required for document preview and conversion:"
LangString dep_explain_imagick ${LANG_ENGLISH}  "Required for image conversion:"
LangString dep_explain_pgsql ${LANG_ENGLISH}  "EXPERIMENTAL - Automatically configure PostgreSQL database:"

LangString rm_title ${LANG_ENGLISH} "Removal options"
LangString rm_subtitle ${LANG_ENGLISH} "Do you want to remove the following ?"
LangString rm_tmp ${LANG_ENGLISH} "Temporary files"
LangString rm_data ${LANG_ENGLISH} "Data files"
LangString rm_logs ${LANG_ENGLISH} "Log files"
LangString rm_conf ${LANG_ENGLISH} "Configuration files"

# French

LangString dep_title ${LANG_FRENCH} "Dépendances"
LangString dep_subtitle ${LANG_FRENCH} "Télécharger et installer les dépendances suivantes"
LangString dep_explain_java ${LANG_FRENCH} "Nécessaire pour executer le programme :"
LangString dep_explain_ooo ${LANG_FRENCH} "Nécessaire pourla prévisualisation et la conversion des documents :"
LangString dep_explain_imagick ${LANG_FRENCH}  "Nécessaire pour la conversion des images :"
LangString dep_explain_pgsql ${LANG_FRENCH}  "EXPERIMENTAL - Configurer une base PostgreSQL automatiquement :"

LangString rm_title ${LANG_FRENCH} "Options de supression"
LangString rm_subtitle ${LANG_FRENCH} "Voulez-vous supprimer les elements suivants ?"
LangString rm_tmp ${LANG_FRENCH} "Fichiers temporaires"
LangString rm_data ${LANG_FRENCH} "Fichiers de donnees"
LangString rm_logs ${LANG_FRENCH} "Fichiers de log"
LangString rm_conf ${LANG_FRENCH} "Fichiers de configuration"

# Spanish

LangString dep_title ${LANG_SPANISH} "Dependencias"
LangString dep_subtitle ${LANG_SPANISH} "Descargue e instale las siguientes dependencias"
LangString dep_explain_java ${LANG_SPANISH} "Requerido por el programar para ejecutarse :"
LangString dep_explain_ooo ${LANG_SPANISH} "Requerido para la conversión y previsualización de documentos :"
LangString dep_explain_imagick ${LANG_SPANISH}  "Requerido para la conversión de imágenes :"
LangString dep_explain_pgsql ${LANG_SPANISH}  "(ES) EXPERIMENTAL - Automatically configure PostgreSQL database :"

LangString rm_title ${LANG_SPANISH} "(ES) Removal options"
LangString rm_subtitle ${LANG_SPANISH} "(ES) Do you want to remove the following ?"
LangString rm_tmp ${LANG_SPANISH} "Borrar TMP"
LangString rm_data ${LANG_SPANISH} "Borrar datos"
LangString rm_logs ${LANG_SPANISH} "Borrar logs"
LangString rm_conf ${LANG_SPANISH} "Borrar configuración"

# German

LangString dep_title ${LANG_GERMAN} "Abhängigkeiten"
LangString dep_subtitle ${LANG_GERMAN} "Lädt und installiert folgende Abhängigkeiten herunter"
LangString dep_explain_java ${LANG_GERMAN} "Wird von der Anwendung während der Laufzeit benötigt :"
LangString dep_explain_ooo ${LANG_GERMAN} "Wird für die Dokumentvorschau und Konvertierung benötigt :"
LangString dep_explain_imagick ${LANG_GERMAN}  "Wird für die Bildkonvertierung benötigt :"
LangString dep_explain_pgsql ${LANG_GERMAN}  "(DE) EXPERIMENTAL - Automatically configure PostgreSQL database :"

LangString rm_title ${LANG_GERMAN} "(DE) Removal options"
LangString rm_subtitle ${LANG_GERMAN} "(DE) Do you want to remove the following ?"
LangString rm_tmp ${LANG_GERMAN} "TMP löschen"
LangString rm_data ${LANG_GERMAN} "Daten löschen"
LangString rm_logs ${LANG_GERMAN} "Log-Infos löschen"
LangString rm_conf ${LANG_GERMAN} "Konfiguration löschen"

# Italian

LangString dep_title ${LANG_ITALIAN} "(IT) Dependencies"
LangString dep_subtitle ${LANG_ITALIAN} "(IT) Download and install the following dependencies"
LangString dep_explain_java ${LANG_ITALIAN} "(IT) Required for the program to run:"
LangString dep_explain_ooo ${LANG_ITALIAN} "(IT) Required for document preview and conversion:"
LangString dep_explain_imagick ${LANG_ITALIAN}  "(IT) Required for image conversion:"
LangString dep_explain_pgsql ${LANG_ITALIAN}  "(IT) EXPERIMENTAL - Automatically configure PostgreSQL database:"

LangString rm_title ${LANG_ITALIAN} "(IT) Removal options"
LangString rm_subtitle ${LANG_ITALIAN} "(IT) Do you want to remove the following ?"
LangString rm_tmp ${LANG_ITALIAN} "(IT) TMP files"
LangString rm_data ${LANG_ITALIAN} "(IT) Data files"
LangString rm_logs ${LANG_ITALIAN} "(IT) Log files"
LangString rm_conf ${LANG_ITALIAN} "(IT) Configuration files"

