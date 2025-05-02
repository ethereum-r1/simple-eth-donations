# Simple Eth Donations

made for trustless donations to R1 rollup

## Foundry 

See foundry documentation: https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test -vv
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/EthDonations.s.sol:EthDonationsScript --rpc-url <your_rpc_url> --account <pwd_encrypted_account_filepath>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
