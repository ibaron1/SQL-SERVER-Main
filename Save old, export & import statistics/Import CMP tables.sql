create table CUSTOM..CMPtbls
(name varchar(30))

-- vi C:\IFS\CMP tables\CMPtables.txt

bcp CUSTOM..CMPtbls in CMPtables.txt -Up489920 -SGLSRD -c