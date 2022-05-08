# FindAlias

A mix task that prints the filename and the line number of alias.

Searching for the full alias name in a project which use multi alias is difficult.

For eg:

```
alias ModA.{ModB, ModC}
```


## Installation

`mix archive.install github sushant12/find_alias`

## Usage

```
mix find_alias MyApp.ModuleName --dir lib
```
