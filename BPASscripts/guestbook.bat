Echo off
REM Script to run questbook email import to database and
REM then create new webpage
REM 
cd "%MY_DOCUMENTS%\BPAS\membership details\membership database"
REM import any new mails
java -DMY_DOCUMENTS="%MY_DOCUMENTS%" -cp Guestbook.jar com.dethorpe.guestbook.Guestbook
REM Create the new guestbook page
perl "%MY_DOCUMENTS%\eclipse\workspace\BPASscripts\guestbookweb.perl"
