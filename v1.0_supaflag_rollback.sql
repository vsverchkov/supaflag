-- Supaflag (Feature Flag functionality for Supabase)
-- Version 1.0

-- Drop functions
drop function if exists create_feature_flag(feature_flag.name%type, feature_flag.value%type,
                                            feature_flag.description%type, feature_flag.strategy%type,
                                            feature_flag.percentage%type, feature_flag.public%type);
drop function if exists is_feature_flag_enabled(feature_flag.name%type);
drop function if exists add_users_to_user_ids_feature_flag(feature_flag.name%type, uuid[]);
drop function if exists delete_feature_flag (feature_flag.name%type);

-- Drop structures
drop table if exists public.feature_flag_user_ids;
drop table if exists public.feature_flag;
drop type if exists public.feature_flag_strategy_type;
