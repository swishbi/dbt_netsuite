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