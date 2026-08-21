-- Limpa partidas avulsas e seus eventos.
-- Mantém public.standalone_teams para reaproveitar os nomes dos times depois.
delete from public.standalone_matches;

-- Se quiser zerar TUDO, incluindo os times avulsos, rode também:
-- delete from public.standalone_teams;
