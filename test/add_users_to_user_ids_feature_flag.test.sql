begin;
select plan(2);

-- Throw exception when a flag not found
select throws_ok(   'select add_users_to_user_ids_feature_flag(''not.existed.flag'', array[''c396ff7d-a9b1-45e8-bc2b-5fcc6eec3897'']::uuid[])',
                    'feature flag not found',
                    'we should throw exception when the flag does not exist');

-- Throw exception when founded flag has not user_id strategy
insert into public.feature_flag (name, value, strategy)
values ('not.user_id.strategy', true, 'global');
select throws_ok(   'select add_users_to_user_ids_feature_flag(''not.user_id.strategy'', array[''c396ff7d-a9b1-45e8-bc2b-5fcc6eec3897'']::uuid[])',
                    'feature flag strategy not user_ids',
                    'we should throw exception when the flag has not user_id strategy');

delete from public.feature_flag;
select * from finish();
end;
