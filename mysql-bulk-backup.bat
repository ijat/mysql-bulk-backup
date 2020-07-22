@echo off

REM Edit as required

set db_host="localhost"
set db_user="root"
set db_pass=""

set mysql_path="C:\xampp\mysql\bin\mysql.exe"
set mysqldump_path="C:\xampp\mysql\bin\mysqldump.exe"
set log_path=".\logs"
set backup_path=".\backups"



REM Internal codes below, do not edit

set db_list=_temp.txt
set /A index_value=0
set /A skip_value=0

if not exist %log_path% mkdir %log_path%
if not exist %backup_path% mkdir %backup_path%

CALL :log "=== Starting backup ==="
CALL :log "Mysql path = %mysql_path%"
CALL :log "Mysqldump path = %mysqldump_path%"
CALL :log "Log path = %log_path%"
CALL :log "Backup path = %backup_path%"
CALL :log "Current directory = %cd%"

echo Starting backup databases...
echo.

rem if exist _temp.txt del _temp.txt

rem Get all databases
set mysql_params=
if not %db_host% == "" set mysql_params=%mysql_params% -h %db_host%
if not %db_user% == "" set mysql_params=%mysql_params% -u %db_user%
if not %db_pass% == "" set mysql_params=%mysql_params% -p%db_pass%
set mysql_params=%mysql_params% -e"Show databases;"

CALL :log "Getting databases to _temp.txt"
%mysql_path% %mysql_params% > _temp.txt

rem Start backing up...

if not [%1]==[] (
	set db_list=%1%
	echo Using databases name from %1%
	echo.
	call :log "Using db list %1%"
)
for /F "tokens=*" %%A in (%db_list%) do CALL :backup_db %%A

set /A total_value=%index_value%-%skip_value%
echo Total %total_value% databases dumped!
echo.

set /p DUMMY=Press ENTER to exit...
CALL :log "Deleting _temp.txt"
if exist _temp.txt del _temp.txt
CALL :log "END-OF-SCRIPT"
exit

:blacklist_db 
rem https://dba.stackexchange.com/questions/101292/need-for-backing-up-mysql-databases-information-schema-performance-schema-mysq
rem https://serverfault.com/questions/681091/mysql-backups-of-information-schema
set %3="GO"
IF %~1 == Database (
	IF %~2 == 1 (
		set %3="SKIP"
    )
)
rem https://dba.stackexchange.com/questions/111072/which-databases-are-backed-up-by-mysqldump-all-databases
If %~1 == information_schema set %3="SKIP"
If %~1 == performance_schema set %3="SKIP"
EXIT /B 0

:backup_db
set /A index_value=%index_value%+1

set out=
call :blacklist_db %~1 %index_value% out

if %out% == "SKIP" (
	set /A skip_value=%skip_value%+1
	echo [SKIP] %~1...
	echo.
	call :log "Skip %~1"
	EXIT /B 0
)

CALL :log "Processing %~1..."
echo [DUMP] %~1...

echo.

set mysqldump_params=
if not %db_host% == "" set mysqldump_params=%mysqldump_params% -h %db_host%
if not %db_user% == "" set mysqldump_params=%mysqldump_params% -u %db_user%
if not %db_pass% == "" set mysqldump_params=%mysqldump_params% -p%db_pass%
set mysqldump_params=%mysqldump_params% %~1

CALL :update_time
if not exist %backup_path%\%mydate% mkdir %backup_path%\%mydate%
%mysqldump_path%%mysqldump_params% > %backup_path%\%mydate%\%~1.sql
EXIT /B 0

:update_time
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-3 delims=/:" %%a in ("%TIME%") do (set mytime=%%a:%%b:%%c)
EXIT /B 0

:log
call :update_time
ECHO [%mydate%-%mytime%] %~1 >> "%log_path%\%mydate%.txt"
EXIT /B 0
