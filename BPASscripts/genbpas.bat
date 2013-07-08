REM Script to generate the BPAS website pages from the MySQL DB's

REM guestbook - mySQL
REM =================
REM import any new mails
REM java -DMY_DOCUMENTS="%MY_DOCUMENTS%" -cp C:\home\craign\eclipse\workspace\Guestbook\build\Guestbook.jar com.dethorpe.guestbook.Guestbook
REM generate web page
REM perl -w "%MY_DOCUMENTS%\eclipse\workspace\BPASscripts\guestbookweb.perl"

REM Market - mySQL
REM ==============
REM perl.exe -w "C:\home\craign\eclipse\workspace\BPASscripts\marketweb.perl"

REM run catalyst test apps to generate static pages
REM Note: Use perl filter to strip catalyst root from links
REM ===================================
perl -w "%MY_DOCUMENTS%\eclipse\workspace\cat_bpas\script\cat_bpas_test.pl" /shows/summarylist | perl -w "%MY_DOCUMENTS%\eclipse\workspace\BPASscripts\convert_cat_to_static.pl" 1 > c:\websites\bpas\shows\summarylist.html

perl -w "%MY_DOCUMENTS%\eclipse\workspace\cat_bpas\script\cat_bpas_test.pl" /shows/fulllist | perl -w "%MY_DOCUMENTS%\eclipse\workspace\BPASscripts\convert_cat_to_static.pl" 1 > c:\websites\bpas\shows\fulllist.html

perl -w "%MY_DOCUMENTS%\eclipse\workspace\cat_bpas\script\cat_bpas_test.pl" /shows/attendlist | perl -w "%MY_DOCUMENTS%\eclipse\workspace\BPASscripts\convert_cat_to_static.pl" 1 > c:\websites\bpas\members\attendlist.html

REM  Non-website reports 
REM  ===================
perl -w "%MY_DOCUMENTS%\eclipse\workspace\cat_bpas\script\cat_bpas_test.pl" /query/renewalsdue/1 | perl -w "%MY_DOCUMENTS%\eclipse\workspace\BPASscripts\convert_cat_to_static.pl" 1 > "C:\websites\bpas\DBreports\renewalsdue.html"

perl -w "%MY_DOCUMENTS%\eclipse\workspace\cat_bpas\script\cat_bpas_test.pl" /query/offlinemembers | perl -w "%MY_DOCUMENTS%\eclipse\workspace\BPASscripts\convert_cat_to_static.pl" 1 > "C:\websites\bpas\DBreports\offlinemembers.html"

REM RSS feed
REM ========
perl -w "%MY_DOCUMENTS%\eclipse\workspace\BPASscripts\feed-builder.pl" > c:\websites\bpas\BPAS_RSS.xml

pause

