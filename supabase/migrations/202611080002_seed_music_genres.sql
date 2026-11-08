insert into public.genres (code, name)
values
  ('g_' || md5(lower(trim('Ballad'))), 'Ballad'),
  ('g_' || md5(lower(trim('Chưa phân loại'))), 'Chưa phân loại'),
  ('g_' || md5(lower(trim('Dance-Pop'))), 'Dance-Pop'),
  ('g_' || md5(lower(trim('Hip-Hop'))), 'Hip-Hop'),
  ('g_' || md5(lower(trim('K-Pop'))), 'K-Pop'),
  ('g_' || md5(lower(trim('Mashup'))), 'Mashup'),
  ('g_' || md5(lower(trim('Nhạc Trẻ'))), 'Nhạc Trẻ'),
  ('g_' || md5(lower(trim('Pop'))), 'Pop'),
  ('g_' || md5(lower(trim('Rap Việt'))), 'Rap Việt'),
  ('g_' || md5(lower(trim('Rock'))), 'Rock'),
  ('g_' || md5(lower(trim('V-Pop'))), 'V-Pop')
on conflict (code) do nothing;
