-- Supaflag (Feature Flag functionality for Supabase)
-- Version 1.0

/*
    Create structures
*/

-- Create strategy types
create type public.feature_flag_strategy_type as enum(
    'global',
    'random',
    'stickiness_user_id',
    'stickiness_session_id',
    'user_ids'
  );

-- Add comment on the strategy type enum
comment on type public.feature_flag_strategy_type is 'Feature flag Rollout Strategy.

global -    A simple strategy means that this flag active for everyone;
random -    For every is_feature_flag_enabled call will return a random state based on the rollout percentage.
stickiness_user_id -    Used to guarantee consistency (to be sticky on user id) for a gradual rollout.
                        The same user id and the same rollout percentage should give predictable results.
                        If user is anon the behavior would be false;
stickiness_session_id - Used to guarantee consistency (to be sticky on session id) for a gradual rollout.
                        The same session id and the same rollout percentage should give predictable results.
                        If user is anon the behavior would be false.
user_ids -  This strategy allows you to specify a list of user ids that you want to expose the new feature for.
            Active for user ids linked with a feature flag.';

-- Create a feature flag table with metadata
create table if not exists public.feature_flag (
    id uuid primary key default uuid_generate_v4(),
    name varchar(255) not null,
    description text,
    value boolean not null default false,
    strategy feature_flag_strategy_type not null default 'global',
    percentage smallint not null default 100,
    public boolean not null default false,
    created_at timestamp with time zone not null default now(),
    constraint feature_flag_name_unique unique (name),
    constraint feature_flag_percentage_check check (percentage between 0 and 100)
  );

-- Add comments on the feature_flag table
comment on table public.feature_flag is 'Feature flags';
comment on column public.feature_flag.id is 'Feature flag unique id';
comment on column public.feature_flag.name is 'Feature flag unique name';
comment on column public.feature_flag.description is 'Feature flag description';
comment on column public.feature_flag.value is 'Feature flag value (on/off)';
comment on column public.feature_flag.strategy is 'Feature flag rollout strategy';
comment on column public.feature_flag.percentage
is 'Feature flag rollout percentage; use by random and stickiness strategies';
comment on column public.feature_flag.public
is 'Feature flag public policy';
comment on column public.feature_flag.created_at is 'Feature flag creation date';

-- Create an index for the public field (RLS performance)
create index if not exists feature_flag_public_idx on public.feature_flag (public);

-- Enable RLS for the feature flag table
alter table public.feature_flag enable row level security;

-- Create policy for selecting public feature flags by anon
create policy "Public feature flags are visible to everyone"
on public.feature_flag for select to anon using(public);

-- Create policy for selecting all feature flags by authenticated
create policy "All feature flags are visible to authenticated"
on public.feature_flag for select to authenticated using(true);

-- Create link for the user_ids strategy type
create table if not exists public.feature_flag_user_ids (
    flag_id uuid not null,
    user_id uuid not null,
    constraint feature_flag_user_ids_pk primary key (flag_id, user_id),
    constraint feature_flag_user_ids_flag_id_fk foreign key (flag_id) references public.feature_flag (id) on delete cascade,
    constraint feature_flag_user_ids_user_id_fk foreign key (user_id) references auth.users (id) on delete cascade
);

-- Add comments on the feature_flag_user_ids table
comment on table public.feature_flag_user_ids is 'Link between feature flag and user id for user_ids strategy';
comment on column public.feature_flag_user_ids.flag_id is 'Link to the feature flag id';
comment on column public.feature_flag_user_ids.user_id is 'Link to the user id';

-- Create a unique index for the user_id (RLS performance)
create index if not exists feature_flag_user_ids_user_id_idx on public.feature_flag_user_ids (user_id);

-- Enable RLS for the feature flag table
alter table public.feature_flag_user_ids enable row level security;

-- Create policy for selecting user's own links
create policy "Public feature flags are visible to everyone"
on public.feature_flag_user_ids for select using((select auth.uid()) = user_id);


/*
    Create functions
*/

-- Create a function for checking a feature flag value
create or replace function is_feature_flag_enabled (flag_name feature_flag.name%type)
returns boolean
language plpgsql
set search_path = public
as
$$
declare
    id feature_flag.id%type;
    value feature_flag.value%type;
    strategy feature_flag.strategy%type;
    percentage feature_flag.percentage%type;
    uid uuid;
    session_id uuid;
begin
    select  f.id,   f.value,    f.strategy, f.percentage
    into    id,     value,      strategy,   percentage
    from feature_flag f
    where f.name = flag_name;

    if not found then
        raise exception 'feature flag not found' using hint = 'check the flag_name';
    end if;

    if strategy = 'global' then
        return value;
    elsif strategy = 'random' then
        -- generate 1-100 range and check the inclusion in the configured percentage
        return  case when (select floor(random() * 100) + 1) <= percentage
                then value
                else not value end;
    elsif strategy = 'stickiness_user_id' then
        uid := (select auth.uid());
        if uid is null then
            return false;
        end if;

        -- generate uid hash, map hash (integer) range onto percentage range (1-100)
        -- and check the inclusion in the configured percentage
        return  case when (select ((uuid_hash(uid) + 2147483648) * 100 / 4294967295 + 1)) <= percentage
                then value
                else not value end;
    elsif strategy = 'stickiness_session_id' then
        session_id := (select (auth.jwt() ->> 'session_id'));
        if session_id is null then
            return false;
        end if;

        -- generate session_id hash, map hash (integer) range onto percentage range (1-100)
        -- and check the inclusion in the configured percentage
        return  case when (select ((uuid_hash(session_id) + 2147483648) * 100 / 4294967295 + 1)) <= percentage
                then value
                else not value end;
    elsif strategy = 'user_ids' then
        uid := (select(auth.uid()));
        if uid is null then
            return false;
        end if;

        -- check that uid exists (or not) in feature_flag_user_ids
        return  case when exists(   select 1
                                    from feature_flag_user_ids uis
                                    where uis.flag_id = id and uis.user_id = uid)
                then value
                else not value end;
    end if;

    raise exception 'the feature flag strategy not implemented yet' using hint = 'implement new strategy type';
end;
$$;

-- Add comment on is_feature_flag_enabled function
comment on function is_feature_flag_enabled is 'Get an actual feature flag value.

Parameters:
flag_name - a name of the feature flag; required;

Results:
true/false - when returned the actual feature flag value;
exception ''feature flag not found'' - when a flag does not exist or you do not have permission to read it;
exception ''the feature flag strategy not implemented yet'' - when added new strategy type and has not implemented logic for it yet;';

-- Create function for creating new feature flag
create or replace function create_feature_flag (flag_name feature_flag.name%type,
                                                value feature_flag.value%type,
                                                description feature_flag.description%type,
                                                strategy feature_flag.strategy%type,
                                                percentage feature_flag.percentage%type,
                                                public feature_flag.public%type)
returns feature_flag
language plpgsql
set search_path = public
as
$$
declare
    result feature_flag;
begin
    if flag_name is null then
        raise exception 'feature flag name is null' using hint = 'feature flag name must be filled';
    end if;

    if exists(select 1 from feature_flag ff where ff.name = flag_name) then
        raise exception 'feature flag already exists' using hint = 'use unique feature flag name';
    end if;

    execute 'insert into feature_flag (name'
            || case when value is not null then ', value' else '' end
            || case when description is not null then ', description' else '' end
            || case when strategy is not null then ', strategy' else '' end
            || case when percentage is not null then ', percentage' else '' end
            || case when public is not null then ', public' else '' end
            || ') values ('
            || concat_ws(', ',
                '''' || flag_name || '''',
                case when value is not null then '''' || value || '''' end,
                case when description is not null then '''' ||  description || '''' end,
                case when strategy is not null then '''' ||  strategy || '''' end,
                case when percentage is not null then percentage end,
                case when public is not null then '''' || public || '''' end
                )
            || ') returning *'
    into result;

    return result;
end;
$$;

-- Add comment on create_feature_flag function
comment on function create_feature_flag is 'Create a new feature flag.

Parameters:
flag_name - a name of new feature flag; required;
value - a feature flag state (on/off);
description - a description of new feature flag;
strategy - a rollout strategy of new feature flag; see feature_flag_strategy_type;
percentage - a rollout percentage of new feature flag;
public - a public policy of new feature flag; true - visible for everyone, false - only for authenticated;

Results:
feature_flag row - when feature flag created;
exception ''feature flag name is null'' - when flag name is not passed;
exception ''feature flag already exists'' - when flag name already used;
exception ''new row violates row-level security policy'' - when you do not have permission to create a feature flag;';

-- Create function for adding users to the user ids feature flag
create or replace function add_users_to_user_ids_feature_flag ( flag_name feature_flag.name%type,
                                                                user_ids uuid[])
returns void
language plpgsql
set search_path = public
as
$$
declare
    fid feature_flag.id%type;
    strategy feature_flag.strategy%type;
begin
    select  f.id,   f.strategy
    into    fid,    strategy
    from feature_flag f
    where f.name = flag_name;

    if not found then
        raise exception 'feature flag not found' using hint = 'check the feature flag name';
    end if;

    if strategy != 'user_ids' then
        raise exception 'feature flag strategy not user_ids' using hint = 'use only the user_ids feature flags';
    end if;

    insert into feature_flag_user_ids (flag_id, user_id)
    select fid, unnest(user_ids)
    on conflict do nothing;
end;
$$;

-- Add comment on create_user_ids_feature_flag function
comment on function add_users_to_user_ids_feature_flag is 'Add user ids to the user ids feature flag.

Parameters:
flag_name - a name of the feature flag; required;
user_ids - an array of user ids who who should be added to the flag;

Results:
void - when user ids added;
exception ''feature flag not found'' - when a flag does not exist or you do not have permission to modify it;
exception ''feature flag strategy not user_ids'' - when the flag has no user_ids strategy.
exception ''new row violates row-level security policy'' - when you do not have permission to add users to the feature flag;';

-- Create function for deleting old feature flags
create or replace function delete_feature_flag (flag_name feature_flag.name%type)
returns void
language sql
set search_path = public
as
$$
    delete from feature_flag f
    where f.name = flag_name;
$$;

-- Add comment on delete_feature_flag function
comment on function delete_feature_flag is 'Delete the old feature flag.

Parameters:
flag_name - a name the feature flag; required;

Results:
void - when flag deleted (if you have do not have permisson operation will ingoring);';
