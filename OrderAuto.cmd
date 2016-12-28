rename i:\lparfum\store.exe _store.exe
rename i:\lparfum\plateg.exe _plateg.exe
rename i:\lparfum\Qstat.exe _Qstat.exe
rename i:\lparfum\stat.exe _stat.exe

set dat=i:\lparfum\dat
echo %date%-%time% > %dat%\upload.f
copy i:\lparfum\dat\stor.* .\lparfum\dat /y /z
copy i:\lparfum\dat\naklad.* .\lparfum\dat /y /z
copy i:\lparfum\dat\00012\rec_buy.* .\lparfum\dat\00012 /y /z

rem резервная копия rec_num
copy i:\lparfum\dat\rec_num.* d:\save_tmp\recnum\ /y /z

rem pause

d:\install\OrderAuto\OrderAuto.exe 4
rem pause

copy d:\install\OrderAuto\*.log d:\save_tmp\log\ /Y

ping localhost -n 120

xcopy .\lparfum\dat\00012 i:\lparfum\dat\00012 /E /Y /Z
xcopy .\lparfum\dat\naklad.* i:\lparfum\dat /Y /Z
xcopy .\lparfum\dat\stor.* i:\lparfum\dat /Y /Z
 
del /q /f %dat%\upload.f
rem del .\LPARFUM\DAT\00004\rec_buy.k0*
rem .\LPARFUM\FILES.DEF\CFIL.EXE .\LPARFUM\FILES.DEF\rec_buy.CLA REC_BUY .\LPARFUM\DAT\00006\rec_buy.DAT .\LPARFUM\DAT\00006\rec_buy.DAT
rem del .\LPARFUM\DAT\naklad.k0*
rem .\LPARFUM\FILES.DEF\CFIL.EXE .\LPARFUM\FILES.DEF\naklad.CLA NAKLAD .\LPARFUM\DAT\NAKLAD.DAT .\LPARFUM\DAT\NAKLAD.DAT
rem del .\lparfum\dat\stor.k0*
rem .\lparfum\files.def\cfil.exe .\lparfum\files.def\stor.cla STOR .\lparfum\dat\stor.dat .\lparfum\dat\stor.dat



rename i:\lparfum\_store.exe store.exe
rename i:\lparfum\_plateg.exe plateg.exe
rename i:\lparfum\_Qstat.exe Qstat.exe
rename i:\lparfum\_stat.exe stat.exe