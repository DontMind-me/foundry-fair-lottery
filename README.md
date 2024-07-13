# Fair Lotttery Contract

## About

The Fair Lottery Contract is a decentralized lottery system built using Solidity and Chainlink VRFv2 for verifiable random number generation. The contract allows participants to enter a lottery by paying a specified entrance fee. The lottery winner is selected randomly and the prize is automatically transferred to the winner.

## License

MIT

## Functions

1. Players can only enter by paying ether equal or above the entranceFee by calling ```enterLottery```
2. Only after a Specific TimePeriod can a Winner be picked
3. Utilizes Chainlink VRFv2 for verifiable randomeness
4. Gets called automatically to select a winner by Chainlink Automation Nodes after all conditions are met

## Notes

- Ensure that Sufficent LINK tokens are available in the subscription for VRF Requests

## Smart Contracts Overview

- **Lottery** Allows Players to enter lottery by paying ETH and chooses a random winner fairly once enough time and other conditions have been met

- **DeployLottery** Script to deploy Lottery contract with settings appropriate for the specific chain

- **HelperConfig** Allows the deploying of the Contract in different environments and Networks

- **Create Subscription** Creates a Subscription if ```subscriptionID``` is zero programatically

- **FundSubscription** Funds the Created Subscription programatically

- **AddConsumer** Adds the Deployed Contract to the subscription 

## Prerequisites

To interact with the FundMe contract or deploy it yourself, you'll need:
- [Foundry](https://book.getfoundry.sh/getting-started/installation.html) for smart contract development and testing
- An Ethereum wallet like [Metamask](https://metamask.io/)

## Clone Repository 

```
git clone https://github.com/DontMind-me/foundry-fair-lottery
cd foundry-fair-lottery
forge build
```
## Installs

To interact with the contract, you will have to download the following packages or just run ```forge install``` in the terminal:

```
forge install cyfrin/foundry-devops@0.2.2 --no-commit
```

```
forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit
```

```
forge install foundry-rs/forge-std@v1.8.2 --no-commit
```

```
 forge install transmissions11/solmate@v6 --no-commit
```

## Commands

#### Build

```shell
$ forge build
```

#### Test

```shell
$ forge test
```

#### Gas Snapshots

```shell
$ forge snapshot
```

#### Anvil

```shell
$ anvil
```

#### Deploy

```shell
$ forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(add_rpc_url) --private-key $(add_private_key) --broadcast --verify --etherscan-api-key $(add_etherscan_api_key) -vvv
```
------------------------------------
## THANK YOU FOR VISITING MY PROJECT!!

