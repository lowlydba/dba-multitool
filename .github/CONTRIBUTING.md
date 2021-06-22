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
* Making a pull request to address any of the above to the `development` branch

## Testing Locally

See the testing readme in the [tests directory README](../tests/README.md)

## Style Guide

Styles (or lack thereof) that are particular to this project.
Think :tshirt:, not :necktie:

### T-SQL

T-SQL is linted against this [configuration](../appveyor/tsqllint)
of TSQLLint via a Pester test.

### Markdown

All markdown, whether manually or automatically generated, should adhere to standard
markdown rules. This project utilize's David Anson's [markdown lint][mdlint]
with a slightly customized
[configuration][mdconfig].

You can use our config and markdown lint plugins in your IDE of choice, or just wait
for your commits to be automatically linted using Github Actions.

### PowerShell

PowerShell is only used in the automation piece of this project,
but [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
is used to lint it for general best practice adherement.

[mdconfig]: https://github.com/LowlyDBA/dba-multitool/blob/master/.github/linters/.markdown-lint.yml
[mdlint]: https://github.com/DavidAnson/markdownlint
[tsqlt]: https://tsqlt.org/
