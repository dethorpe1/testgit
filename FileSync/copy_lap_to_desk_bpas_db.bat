rem copy BPAS DB data files from laptop to desktop
rem to be used after offline working on DB on laptop

perl -w sync.perl -c lap_desk_bpas_db.cfg -f laptop
