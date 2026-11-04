; 昌子大冒险 / Changzi Adventure - Windows demo installer (Inno Setup 6.3+)
;
; Build the game first (release template, embedded PCK):
;   godot --headless --path . --export-release "Windows Desktop" build/windows/changzi-adventure.exe
;
; Compile this script on Windows:
;   ISCC.exe packaging\windows\changzi-adventure.iss
;
; Output:
;   build\windows\installer\changzi-adventure-0.11.0-demo-setup.exe
;
; Signing is intentionally disabled until a real code-signing certificate is
; available. See docs/release/windows-signing.md, then configure the "signtool"
; sign tool and uncomment SignTool / SignedUninstaller below.
;
; Keep MyAppVersion in sync with project.godot (config/version). The numeric
; form is only for the PE version resource; Windows requires four numbers.

#define MyAppName "昌子大冒险"
#define MyAppNameEn "Changzi Adventure"
#define MyAppVersion "0.11.0-demo"
#define MyAppVersionNumeric "0.11.0.0"
#define MyAppPublisher "GameCreateStudio"
#define MyAppExeName "changzi-adventure.exe"
#define MyAppId "{{963F8BA8-36C6-4080-93D2-2D3FAAF7927F}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
VersionInfoVersion={#MyAppVersionNumeric}
VersionInfoProductVersion={#MyAppVersionNumeric}
VersionInfoProductName={#MyAppName}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppNameEn} Setup
VersionInfoCopyright=GameCreateStudio
DefaultDirName={autopf}\{#MyAppNameEn}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Per-user install: no administrator prompt, nothing written outside the user
; profile. Users can still pick an all-users location from the dialog.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
MinVersion=10.0
; Inno Setup 6.3+ syntax for "runs on x64, installs as 64-bit". Use plain
; "x64" instead if the build machine still has Inno Setup 6.0-6.2.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\build\windows\installer
OutputBaseFilename=changzi-adventure-{#MyAppVersion}-setup
SetupIconFile=..\..\assets\branding\changzi.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Enable once the demo's EULA / asset-licensing page is finalized.
; LicenseFile=..\..\LICENSE
; Sign after a real certificate is installed; see the signing doc.
; SignTool=signtool
; SignedUninstaller=yes

; ChineseSimplified.isl is not bundled with the official Inno Setup
; distribution. Put ChineseSimplified.isl in Inno's Languages folder (or the
; compiler's Languages folder), then uncomment this section to localize the
; wizard. The English default works without any extra file.
; [Languages]
; Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
; The release executable embeds the PCK, so the installer ships one game file.
Source: "..\..\build\windows\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion
Source: "..\..\ASSETS.md"; DestDir: "{app}"; DestName: "ASSETS.md"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

; Game progress lives in %APPDATA%\Godot\app_userdata\昌子大冒险 and is left in
; place on purpose: uninstalling the demo must never destroy saves.
