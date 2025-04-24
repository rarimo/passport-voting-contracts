import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import { ProposalsState__factory, BioPassportVoting__factory, BioPassportVotingVerifier__factory } from "@ethers-v6";

import { getConfig } from "./config/config";

export = async (deployer: Deployer) => {
  const config = (await getConfig())!;

  const proposalsState = await deployer.deployed(ProposalsState__factory);

  const bioPassportVotingVerifier = await deployer.deploy(BioPassportVotingVerifier__factory);

  const bioPassportVoting = await deployer.deployERC1967Proxy(BioPassportVoting__factory);

  await bioPassportVoting.__BioPassportVoting_init(
    config.registrationSMT,
    await proposalsState.getAddress(),
    await bioPassportVotingVerifier.getAddress(),
  );

  await proposalsState.addVoting(config.bioVotingName, await bioPassportVoting.getAddress());

  await Reporter.reportContractsMD(
    ["BioPassportVoting", `${await bioPassportVoting.getAddress()}`],
    ["ProposalsState", `${await proposalsState.getAddress()}`],
  );
};
