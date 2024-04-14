begin;
select plan(3);

-- Throw exception when try to insert a new flag without name
select throws_ok(   'insert into public.feature_flag(name) values (null)',
                    '23502',
                    'null value in column "name" of relation "feature_flag" violates not-null constraint',
                    'the feature flag name must be specified');

-- Throw exception when try to insert a new flag with undefined strategy
select throws_ok(   'insert into public.feature_flag(name, strategy) values (''new'', ''unknown'')',
                    '22P02',
                    'invalid input value for enum feature_flag_strategy_type: "unknown"',
                    'the feature flag name must be specified');

-- Create with default parameters and check result
insert into public.feature_flag(name) values ('default');
select results_eq(  'select name, description, value, strategy, percentage, public from public.feature_flag where name = ''default''',
                    $$values ('default'::varchar(255), null, false, 'global'::public.feature_flag_strategy_type, 100::smallint, false)$$,
                    'created default flag should contains default parameters');

delete from public.feature_flag;
select * from finish();
end;
