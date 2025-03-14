declare @part# int = 8
declare @a varchar(100) = 'anvc34958734ryusd_klfjsdf'
select @a,HASHBYTES ('SHA2_256',@a), cast(HASHBYTES ('SHA2_256',@a) as int)
, abs(cast(HASHBYTES ('SHA2_256',@a) as int))%@part# 