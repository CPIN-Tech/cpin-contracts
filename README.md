# CPIN Protocol

## Deployed Addresses on PEAQ Mainnet

- CPIN Token - [0x06E3cB6b9D0B4089eFF7431AB496362591183E83](https://peaq.subscan.io/account/0x06E3cB6b9D0B4089eFF7431AB496362591183E83?tab=contract)
- CWATT Token - [0x3556aA434Bdcf429D59183d65B6cf036722Ac259](https://peaq.subscan.io/account/0x3556aA434Bdcf429D59183d65B6cf036722Ac259?tab=contract)
- CDATA Token - [0xa65Dab5831898d9A63De0e67FCf68a34D19102bC](https://peaq.subscan.io/account/0xa65Dab5831898d9A63De0e67FCf68a34D19102bC?tab=contract)
- Virtual Panel NFT - [0xa85c10190943BBc46dDE84024f9070e54987fa52](https://peaq.subscan.io/account/0xa85c10190943BBc46dDE84024f9070e54987fa52?tab=contract)
- CpinBuyPanel - [0x0A493a73860DBC93f6CDE70D83799c296b9ad79D](https://peaq.subscan.io/account/0x0A493a73860DBC93f6CDE70D83799c296b9ad79D?tab=contract)
- CpinSppStaking - [0x03134b6118537D9aBd581E6846C5eA9Ad95eDa99](https://peaq.subscan.io/account/0x03134b6118537D9aBd581E6846C5eA9Ad95eDa99?tab=contract)
- CpinConverter - [0x83eaE3Bc9a3F9Ba0D76C55212ab037206d03d496](https://peaq.subscan.io/account/0x83eaE3Bc9a3F9Ba0D76C55212ab037206d03d496?tab=contract)

## Architecture

![CPIn protocol diagram](./diagram.png)

- Facilities will create DID's for every data collection point they have like inverters.
- Every collected data will be sent by these Dids, hourly. The storage key must be like
  - cpin-production-2025-03-13-10 (the last number is the hour in range of 0-23)
- Data Aggregator, tracks all registered Dids and reads production information and aggregates them by facility
  and sends this information to staking contract. For details look cpin-data-aggregator repository.
- Users can buy virtual panels and stake. And they will get their reward and convert to CPIN or PEAQ
