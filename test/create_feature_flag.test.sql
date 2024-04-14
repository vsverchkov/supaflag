begin;
select plan(8);

-- Create a default flag
select results_eq(  'select name, description, value, strategy, percentage, public from create_feature_flag(''default'', null, null, null, null, null);',
                    $$values ('default'::varchar(255), null, false, 'global'::public.feature_flag_strategy_type, 100::smallint, false)$$,
                    'create_feature_flag() without parameters should create flag with default parameters');

-- Create an enabled flag with default strategy
select results_eq(  'select name, description, value, strategy, percentage, public from create_feature_flag(''default.enabled'', true, null, null, null, null);',
                    $$values ('default.enabled'::varchar(255), null, true, 'global'::public.feature_flag_strategy_type, 100::smallint, false)$$,
                    'create_feature_flag() with specified value parameter should create flag with specified value');

-- Create a flag with default strategy and specified description
select results_eq(  'select name, description, value, strategy, percentage, public from create_feature_flag(''default.with.description'', null, ''description'', null, null, null);',
                    $$values ('default.with.description'::varchar(255), 'description', false, 'global'::public.feature_flag_strategy_type, 100::smallint, false)$$,
                    'create_feature_flag() with description parameter should create flag with description');

-- Create a flag with specified strategy
select results_eq(  'select name, description, value, strategy, percentage, public from create_feature_flag(''random'', false, null, ''random'', null, null);',
                    $$values ('random'::varchar(255), null, false, 'random'::public.feature_flag_strategy_type, 100::smallint, false)$$,
                    'create_feature_flag() with specified strategy should create flag with given strategy');

-- Create a flag with specified percentage
select results_eq(  'select name, description, value, strategy, percentage, public from create_feature_flag(''with.percentage'', true, ''description'', null, 50::smallint, null);',
                    $$values ('with.percentage'::varchar(255), 'description', true, 'global'::public.feature_flag_strategy_type, 50::smallint, false)$$,
                    'create_feature_flag() with specified percentage should create flag with given percentage');

-- Create a flag with specified public setting
select results_eq(  'select name, description, value, strategy, percentage, public from create_feature_flag(''with.public'', true, ''description'', ''random'', null, true);',
                    $$values ('with.public'::varchar(255), 'description', true, 'random'::public.feature_flag_strategy_type, 100::smallint, true)$$,
                    'create_feature_flag() with specified public setting should create flag with given public setting');

-- Try to create a flag without name
select throws_ok(   'select name, description, value, strategy, percentage, public from create_feature_flag(null, null, null, null, null, null);',
                    'feature flag name is null',
                    'we should specify a name when call create_feature_flag()');

-- Try to create a flag without name
select throws_ok(   'select name, description, value, strategy, percentage, public from create_feature_flag(''default'', null, null, null, null, null);',
                    'feature flag already exists',
                    'we should use a unique name when call create_feature_flag()');

delete from public.feature_flag;
select * from finish();
end;
