
[Setup]
AppName=vproc
AppVerName=VPROC_1_0_1
DefaultDirName={src}\vproc
DisableProgramGroupPage=yes
OutputBaseFilename=setup_vproc_1_0_1

[Dirs]
Name: "{app}\code"
Name: "{app}\usercode"
Name: "{app}\doc"

[Files]
Source:"vproc.iss";                        DestDir: "{app}"

; Make files
Source:"makefile";                         DestDir: "{app}"
Source:"makefile.cver";                    DestDir: "{app}"
Source:"makefile.ica";                     DestDir: "{app}"
Source:"makefile.nc";                      DestDir: "{app}"
Source:"makefile.vcs";                     DestDir: "{app}"
Source:"MakeVcs.def";                      DestDir: "{app}"
Source:"Pli.tab";                          DestDir: "{app}"

; Verilog 
Source:"test.vc";                          DestDir: "{app}"
Source:"test.v";                           DestDir: "{app}"
Source:"extradefs.v";                      DestDir: "{app}"
Source:"f_VProc.v";                        DestDir: "{app}"

; C source code                                            
Source:"code\*.c";                         DestDir: "{app}\code"
Source:"code\*.h";                         DestDir: "{app}\code"
Source:"usercode\*.c";                     DestDir: "{app}\usercode"

; Documentation
Source:"doc\VProc.htm";                    DestDir: "{app}\doc"
Source:"doc\images\*.gif";                 DestDir: "{app}\doc\images"
Source:"doc\images\*.png";                 DestDir: "{app}\doc\images"
