import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import { deployProxy } from "./helpers/helper";

import { RegistrationSMTReplicator__factory } from "@ethers-v6";

export = async (deployer: Deployer) => {
  const replicator = await deployProxy(deployer, RegistrationSMTReplicator__factory, "RegistrationSMTReplicator");

  await replicator.__RegistrationSMTReplicator_init(
    "0x038D006846a3e203738cF80A02418e124203beb2",
    "0xc1534912902BBe8C54626e2D69288C76a843bc0E",
    "Q-testnet",
  );

  // const replicatorImpl = await deployer.deploy(RegistrationSMTReplicator__factory);
  // const replicator = await deployer.deployed(RegistrationSMTReplicator__factory, "0x2af05993a27df83094a963af64b5d25296230544")

  // await replicator.upgradeTo(await replicatorImpl.getAddress());

  // await replicator.setSourceSMT("0xc1534912902BBe8C54626e2D69288C76a843bc0E");

  Reporter.reportContracts(["RegistrationSMTReplicator", "0xFbae44a113A6f07687b180605f425e43066a6179"]);
};
