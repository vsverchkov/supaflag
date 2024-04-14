begin;
select plan(1);

-- Delete an exists feature flag
insert into public.feature_flag (name) values ('exists.flag');
select delete_feature_flag('exists.flag');
select is_empty('select * from public.feature_flag where name = ''exists.flag''',
                'deleted flag must be missing');

select * from finish();
end;
