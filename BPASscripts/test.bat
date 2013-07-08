REM Show summary list from catalyst app
REM ===================================

REM Note: Use perl filter to strip catalyst root from links

perl -w "%MY_DOCUMENTS%\eclipse\workspace\cat_bpas\script\cat_bpas_test.pl" /shows/summarylist | perl -w -p -e "$_ =~ s/http:\/\/localhost\/static\/css\///" > c:\websites\bpas\ShowsSummaryList.html

pause
