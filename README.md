# Supaflag (Feature Flag functionality for Supabase)
[![Made with Supabase](https://supabase.com/badge-made-with-supabase-dark.svg)](https://supabase.com)

Supaflag is a simple open source solution for feature management based on Supabase that let you test your code with real production data, reducing the risk of negatively impacting your users' experience.


## Getting Started with Supaflag
### 1. Setting Up
Add [`v1.0_supaflag.sql`](/v1.0_supaflag.sql) to your Supabase migration. See [Supabase Migration Docs](https://supabase.com/docs/reference/cli/supabase-migration).
Or just execute [`v1.0_supaflag.sql`](/v1.0_supaflag.sql) in Supabase SQL Editor with admin role.

### 2. Creating your first feature flag
Use Subabase Table Editor:

![Supabase Table Editor](/img/supabase_table_editor.png)

or call [`create_feature_flag`](#create_feature_flag(flag_name, value, description, strategy, percentage, public)) function in Supabase SQL Editor with postgres role.
```sql
select create_feature_flag( 'new_feature',
                            true,
                            'new feature description',
                            'global',
                            100::smallint,
                            true);
```
Will create new enabled public (see [Public Policy](#public-policy)) global (see [Rollout Strategy](#rollout-strategy)) feature flag with name `new_feature`.

### 3. Getting the actual feature flag status
Call [`is_feature_flag_enabled`](#functions) function with any role.
```sql
select is_feature_flag_enabled('new_feature');
```

### 4. Using in your client
Call [`is_feature_flag_enabled`](#functions) function using `rpc`.
```typescript
const { flag, error } = await supabase.rpc('is_feature_flag_enabled',
  {flag_name: 'new_feature'}
)
```

### 5. Deleting the flag after rollout a feature to all users
Use Supabase Table Editor or call [`delete_feature_flag`](#functions) function in Supabase SQL Editor with admin role.
```sql
select delete_feature_flag('new_feature');
```


## Docs

### Rollout strategy
Rollout strategies let you activate a feature only for a specified users. Different strategies use different parameters.
*Default - **global**.*
> `feature_flag.strategy`

#### global
A simple strategy means that this flag active for everyone.

#### random
For every [`is_feature_flag_enabled`](#functions) call will return a random state based on the rollout percentage.

#### stickiness_user_id
Used to guarantee consistency (to be sticky on user id) for a gradual rollout. The same user id and the same rollout percentage should give predictable results.
*If user is anon the behavior would be false.*

#### stickiness_session_id
Used to guarantee consistency (to be sticky on session id) for a gradual rollout. The same session id and the same rollout percentage should give predictable results.
*If user is anon the behavior would be false.*

#### user_ids
This strategy allows you to specify a list of user ids that you want to expose the new feature for. Active for user ids linked with a feature flag.
Use [`add_users_to_user_ids_feature_flag`](#functions) function to add user ids to linked users or just insert `(flag_id, user_id)` into [`feature_flag_user_ids`](#tables).


### Rollout percentage
The percentage you want to activate the feature flag for.
Works only with `random`, `stickiness_user_id` and `stickiness_session_id` strategies.
*Default - **100** (rollout to all users).*
> `feature_flag.percentage`

### Public policy
Public policy allows you to make feature flags available only to `authenticated` users.
See [Supabase Roles](https://supabase.com/docs/guides/database/postgres/roles#authenticator).
*Default - **false** (visible only for authenticated).*
> `feature_flag.public`

### Rollback
If you need to rollback the feature flag functionality, add [`v1.0_supaflag_rollback.sql`](/v1.0_supaflag_rollback.sql) to your Supabase migration. See [Supabase Migration Docs](https://supabase.com/docs/reference/cli/supabase-migration) or just execute [`v1.0_supaflag_rollback.sql`](/v1.0_supaflag_rollback.sql) in Supabase SQL Editor with admin role.

### Functions

#### `create_feature_flag(flag_name, value, description, strategy, percentage, public)`
Used to creating a new feature flag.

Parameters:
- `flag_name` - a name of new feature flag; required;
- `value` - a feature flag state (on/off);
- `description` - a description of new feature flag;
- `strategy` - a rollout strategy of new feature flag; see [Rollout Strategy](#rollout-strategy);
- `percentage` - a rollout percentage of new feature flag;
- `public` - a public policy of new feature flag; see [Public Policy](#public-policy);

Results:
- `feature_flag row` when feature flag created;
- `exception 'feature flag name is null'` when flag name is not passed;
- `exception 'feature flag already exists'` when flag name already used;
- `exception 'new row violates row-level security policy'` when you do not have permission to create a feature flag;

#### `add_users_to_user_ids_feature_flag(flag_name, user_ids)`
Used to adding users to feature flags with the user_ids strategy.

Parameters:
- `flag_name` - a name of the feature flag; required;
- `user_ids` - an array of user ids who who should be added to the flag;

Results:
- `void` - when user ids added;
- `exception 'feature flag not found'` when a flag does not exist or you do not have permission to modify it;
- `exception 'feature flag strategy not user_ids'` when the flag has no user_ids strategy.
- `exception 'new row violates row-level security policy'` when you do not have permission to add users to the feature flag;

#### `is_feature_flag_enabled(flag_name)`
Used to getting an actual feature flag value.

Parameters:
- `flag_name` - a name of the feature flag; required;

Results:
- `true/false` when returned the actual feature flag value;
- `exception 'feature flag not found'` when a flag does not exist or you do not have permission to read it;
- `exception 'the feature flag strategy not implemented yet'` when added new strategy type and has not implemented logic for it yet;

#### `delete_feature_flag(flag_name)`
Used to deleting old feature flags.

Parameters:
- `flag_name` - a name the feature flag; required;

Results:
- `void` when flag deleted (if you have do not have permisson operation will ingoring);

#### Search path specification
By default, `search_path = public` specified for each finction. If you want to use a diffferent schema for the feature flags, then specify this schema in search_path param for each finction.


### Tables

#### feature_flag
Used to storing feature flags.

Definitions:
|Name|Description|Data Type|Nullable|Default|
|--|--|--|--|--|
|id|Feature flag unique id|uuid|not|uuid_generate_v4()|
|name|Feature flag unique name|varchar(255)|not|-|
|description|Feature flag description|text|yes|-|
|value|Feature flag state (on/off)|boolean|not|false|
|strategy|Feature flag rollout strategy|feature_flag_strategy_type|not|'global'|
|percentage|Feature flag rollout percentage|smallint|not|100|
|public|Feature flag public policy|boolean|not|false|
|created_at|Feature flag creation date|timestamp with time zone|not|now()|

#### feature_flag_user_ids
Used to storing links between feature flags and user ids for user_ids strategy.

Definitions:
|Name|Description|Data Type|Nullable|Default|
|--|--|--|--|--|
|flag_id|Feature flag unique id|uuid|not|-|
|user_id|Activated user id|uuid|not|-|

## Roadmap
- [ ] Add scripted tests for stickness strategies;
- [ ] Add `are_feature_flags_enabled` for getting a set of feature flags;
- [ ] Add the ability to combine feature flags;
- [ ] Add grouping for feature flags;
- [ ] Add group id for stickiness strategies;
- [ ] Add user-agent stickiness rollout strategy;
- [ ] Add benchmarking for is_feature_flag_enabled() function;
