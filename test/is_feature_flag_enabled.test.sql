begin;
select plan(7);

-- Throw exception when a flag not found
select throws_ok(   'select is_feature_flag_enabled(''not.existed.flag'')',
                    'feature flag not found',
                    'we should throw exception when the flag does not exist');

-- Return a flag value for global flags
insert into public.feature_flag (name, value, strategy)
values ('global.enabled', true, 'global');
select results_eq(  'select is_feature_flag_enabled(''global.enabled'')',
                    $$values (true)$$,
                    'should return saved global flag state');

-- Return true flag value for random flag with default percenatge (100)
insert into public.feature_flag (name, value, strategy)
values ('random.enabled.to.100', true, 'random');
select results_eq(  'select is_feature_flag_enabled(''random.enabled.to.100'')',
                    $$values (true)$$,
                    'when call random strategy with 100 percent then return true for every call');

-- Return false flag value for random flag with 0 percentage
insert into public.feature_flag (name, value, strategy, percentage)
values ('random.enabled.to.0', true, 'random', 0);
select results_eq(  'select is_feature_flag_enabled(''random.enabled.to.0'')',
                    $$values (false)$$,
                    'when call random strategy with 0 percent then return false for every call');

-- Return false flag value for stickiness_user_id flag when uid is not definded
insert into public.feature_flag (name, value, strategy)
values ('random.stickiness_user_id.without.uid', true, 'stickiness_user_id');
select results_eq(  'select is_feature_flag_enabled(''random.stickiness_user_id.without.uid'')',
                    $$values (false)$$,
                    'when call stickiness_user_id strategy without auth then return false for every call');

-- Return false flag value for stickiness_session_id flag when session_id is not definded
insert into public.feature_flag (name, value, strategy)
values ('random.stickiness_session_id.without.session_id', true, 'stickiness_user_id');
select results_eq(  'select is_feature_flag_enabled(''random.stickiness_session_id.without.session_id'')',
                    $$values (false)$$,
                    'when call stickiness_session_id strategy without auth then return false for every call');

-- Return false flag value for user_ids flag when user_id is not definded
insert into public.feature_flag (name, value, strategy)
values ('random.user_ids.without.uid', true, 'user_ids');
select results_eq(  'select is_feature_flag_enabled(''random.user_ids.without.uid'')',
                    $$values (false)$$,
                    'when call user_ids strategy without auth then return false for every call');

delete from public.feature_flag;
select * from finish();
end;
