set lp=i:\lparfum
set dat=i:\lparfum\dat
set month_dir=000%date:~3,2%
set backup=d:\save_tmp
mkdir .\lparfum\dat\%month_dir%
rename %lp%\store.exe _store.exe
rename %lp%\plateg.exe _plateg.exe
rename %lp%\Qstat.exe _Qstat.exe
rename %lp%\stat.exe _stat.exe


echo %date%-%time% > %dat%\upload.f
copy %dat%\stor.* .\lparfum\dat /y /z
copy %dat%\naklad.* .\lparfum\dat /y /z
copy %dat%\%month_dir%\rec_buy.* .\lparfum\dat\%month_dir% /y /z

rem резервная копия rec_num
copy %dat%\rec_num.* %backup%\recnum\ /y /z

d:\install\OrderAuto\OrderAuto.exe 4

copy .\*.log %backup%\log\ /Y

ping localhost -n 120

xcopy .\lparfum\dat\%month_dir% %dat%\%month_dir% /E /Y /Z
xcopy .\lparfum\dat\naklad.* %dat% /Y /Z
xcopy .\lparfum\dat\stor.* %dat% /Y /Z
 
del /q /f %dat%\upload.f

rename %lp%\_store.exe store.exe
rename %lp%\_plateg.exe plateg.exe
rename %lp%\_Qstat.exe Qstat.exe
rename %lp%\_stat.exe stat.exe