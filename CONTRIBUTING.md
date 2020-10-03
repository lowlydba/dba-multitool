# Contributing to DBA MultiTool

:wave: Hi there! Thanks for using and contributing to the DBA MultiTool!

Below are guidelines and helpful approaches for participating in the project.

* [How to Help](#how-to-help)
* [Testing](#testing-locally)
* [Style Guide](#style-guide)

## How to Help

You can help contribute by:

* Opening a feature request
* Opening a :bug:
* Increasing unit test coverage
* Making a pull request to address any of the above

## Testing Locally

While Appveyor tests across most modern SQL Server versions for compatibility
and unit tests check basic functionality, there are still parts of the scripts
that benefit from human validation and localized testing scenarios.

If you have multiple versions of SQL Server at your disposal, testing across
them is appreciated.

To run local tests from the root of the repository, use the same
PowerShell scripts used by Appveyor (check appveyor.yml for
examples of how to use each script):

1. If you don't have the PowerShell modules DbaTools and SqlServer (and don't
want to install them manually) you can run `appveyor\install_dependencies.ps1`
to get them in addition to TSQLLint (via npm)
2. If you don't have a [tSQLt][tsqlt] database already, run `appveyor\install_tsqlt.ps1`
to install a local copy of it
3. Install the DBA MultiTool with `appveyor\install_tool.ps1`
4. Build the unit tests with `appveyor\build_tsqlt_tests.ps1`
5. Make any proposed modifications to the scripts
6. Verify all unit tests pass with `appveyor\run_tsqlt_tests.ps1`
7. If `sp_doc` was changed, visually inspect a generated markdown file
to ensure everything looks as expected (but do not commit it to your branch)
8. Make a pull request! :tada:

## Style Guide

Styles (or lack thereof) that are particular to this project.
Think :tshirt:, not :necktie:

### T-SQL

While there is no hard rule on T-SQL style enforced or linted in this project, use
your discretion to fit the existing style and favor readability over a strict
adherence to a specific style.

### Markdown

All markdown, whether manually or automatically generated, should adhere to standard
markdown rules. This project utilize's David Anson's [markdown lint][mdlint]
with a slightly customized
[configuration][mdconfig].

You can use our config and markdown lint plugins in your IDE of choice, or just wait
for your commits to be automatically linted using Github Actions.

### PowerShell

PowerShell is only used in the automation piece of this project, but could probably
benefit from being better documented and standardized. Right now no particular
style is enforced, but one may be used in the future.

[mdconfig]: https://github.com/LowlyDBA/dba-multitool/blob/master/.github/linters/.markdown-lint.yml
[mdlint]: https://github.com/DavidAnson/markdownlint
[tsqlt]: https://tsqlt.org/
