alter type public.competition_type
add value if not exists 'zonal';

alter type public.competition_type
add value if not exists 'classificatoria';

alter type public.competition_type
add value if not exists 'fase_final';

alter type public.competition_type
add value if not exists 'liga';

alter type public.competition_type
add value if not exists 'copa';

alter type public.competition_type
add value if not exists 'outro';
