# dbt_netsuite v0.3.1

## Bug Fixes 🐞
- Update the `netsuite__time_entry_details` model to correctly account for features enabled in the `dbt_netsuite_source` package. Previously, the model would fail if any of the following variables were not defined or set to `false`: `netsuite__using_jobs`, `netsuite__advanced_jobs_enabled`, `netsuite__time_off_management_enabled`.

## Contributors
- [phillem15](https://github.com/phillem15) ([#16](https://github.com/swishbi/dbt_netsuite/pull/16))

# dbt_netsuite v0.3.0

## 🚨 Breaking Changes 🚨:
[PR #15](https://github.com/swishbi/dbt_netsuite/pull/15) includes the following breaking changes:
- Update `dbt_netsuite_source` package to `v0.3.0`. This re-introduces the `quantity` and `rateamount` columns to the `stg_netsuite__transaction_lines` model. This also adds the `voided` column to the `stg_netsuite__transactions` model. If these columns were added via the pass through columns, they need to be removed from the pass through variable or aliased using the `transform_sql` modifier.

## 🎉 Feature Updates 🎉
- Added a new model `netsuite__inventory_details` for the purposes of creating the inventory balance history. This can be enabled using the `netsuite__inventory_management_enabled` variable.

## Contributors
- [phillem15](https://github.com/phillem15) ([#15](https://github.com/swishbi/dbt_netsuite/pull/15))

# dbt_netsuite v0.2.10

## 🚨 Breaking Changes 🚨:
[PR #14](https://github.com/swishbi/dbt_netsuite/pull/14) includes the following breaking changes:
- Update `dbt_netsuite_source` to `v0.2.3`. This removes the `quantity` and `rate` columns from the `stg_netsuite__transaction_lines` model. These columns can be re-added via the pass through columns.

## Contributors
- [phillem15](https://github.com/phillem15) ([#14](https://github.com/swishbi/dbt_netsuite/pull/14))

# dbt_netsuite v0.2.9

## Bug Fixes 🐞
Incorporate the `netsuite__multiple_currencies_enabled` variable into the select statement and joins for the currency CTE. This was incorporated in some places but not all.

## Contributors
- [phillem15](https://github.com/phillem15) ([#13](https://github.com/swishbi/dbt_netsuite/pull/13))

# dbt_netsuite v0.2.8

## Bug Fixes 🐞
Bump the version for the `dbt_netsuite_source` package to `v0.2.8`. This fixes a bug in the `netsuite__budget_datails` model where the default identifier for the budgets table should be `budgets` instead of `budget`.

## Contributors
- [phillem15](https://github.com/phillem15) ([#12](https://github.com/swishbi/dbt_netsuite/pull/12))

# dbt_netsuite v0.2.7

## 🎉 Feature Updates 🎉
Incorporate customer categories into `netsuite__transaction_details` via the `netsuite__using_customer_categories` variable from `dbt_netsuite_source`.

## Contributors
- [phillem15](https://github.com/phillem15) ([#11](https://github.com/swishbi/dbt_netsuite/pull/11))

# dbt_netsuite v0.2.6

## Bug Fixes 🐞
Update int_netsuite__tran_and_reporting_periods adjustment period logic so that adjustment periods are only included for the year they are adjusting. They should not carry forward into future years.

## Contributors
- [phillem15](https://github.com/phillem15) ([#10](https://github.com/swishbi/dbt_netsuite/pull/10))

# dbt_netsuite v0.2.5

## Bug Fixes 🐞
Update int_netsuite__tran_and_reporting_periods query to remove adjustment periods from the multiplier periods. This was causing the adjustment periods in the balance sheet to be overinflated.

## Contributors
- [phillem15](https://github.com/phillem15) ([#9](https://github.com/swishbi/dbt_netsuite/pull/9))

# dbt_netsuite v0.2.4

## 🎉 Feature Updates 🎉
Update balance sheet query to allow Net Income to fold into Retained Earnings using the balance sheet retained earnings variables.

## Contributors
- [phillem15](https://github.com/phillem15) ([#8](https://github.com/swishbi/dbt_netsuite/pull/8))

# dbt_netsuite v0.2.3

## 🎉 Feature Updates 🎉
Update package reference to no longer require a GitHub personal access token as an environment variable.

## Contributors
- [phillem15](https://github.com/phillem15) ([#7](https://github.com/swishbi/dbt_netsuite/pull/7))

# dbt_netsuite v0.2.2

## Bug Fixes 🐞
Update balance sheet query to allow variable definitions to appropriately allocate retained earnings.

## Contributors
- [phillem15](https://github.com/phillem15) ([#6](https://github.com/swishbi/dbt_netsuite/pull/6))

# dbt_netsuite v0.2.1

## 🎉 Feature Updates 🎉
Update balance sheet query to allow variable definitions to appropriately allocate retained earnings.

## Contributors
- [phillem15](https://github.com/phillem15) ([#5](https://github.com/swishbi/dbt_netsuite/pull/5))

# dbt_netsuite v0.2.0

## 🚨 Breaking Changes 🚨:
[PR #4](https://github.com/swishbi/dbt_netsuite/pull/4) includes the following breaking changes:
- Remove columns from models that are feature dependent in NetSuite. These columns can be re-added via the pass through columns.

## 🎉 Feature Updates 🎉

## Contributors
- [phillem15](https://github.com/phillem15) ([#4](https://github.com/swishbi/dbt_netsuite/pull/4))

# dbt_netsuite v0.1.0
Refer to the relevant release notes on the Github repository for specific details for the previous releases. Thank you!

## 🎉 Feature Updates 🎉

## Bug Fixes 🐞

## Contributors

## 🚨 Breaking Changes 🚨