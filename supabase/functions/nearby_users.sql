create or replace function nearby_users(lat double precision, lng double precision, radius_km double precision)
returns table (
  user_id uuid,
  user_name text,
  lat double precision,
  lng double precision,
  books jsonb
)
language sql
as $$
  select 
    u.id as user_id,
    u.username as user_name,
    ST_Y(u.location::geometry) as lat,
    ST_X(u.location::geometry) as lng,
    (
      select jsonb_agg(b)
      from (
        select title, author, categories
        from books
        where b.owner_id = u.id and b.format = 'physical'
      ) b
    ) as books
  from users_with_books u
  where u.has_books = true
    and ST_DWithin(
      u.location,
      ST_MakePoint(lng, lat)::geography,
      radius_km * 1000
    )
$$;
