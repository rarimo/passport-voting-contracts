import { Deployer, Reporter } from "@solarity/hardhat-migrate";
import { deployProxy } from "./helpers/helper";

import { VotingVerifier__factory, Voting__factory, ProposalsState__factory } from "@ethers-v6";

import { getConfig } from "./config/config";

export = async (deployer: Deployer) => {
  const config = (await getConfig())!;

  const proposalsState = await deployer.deployed(ProposalsState__factory, "ProposalsState Proxy");

  const votingVerifier = await deployer.deploy(VotingVerifier__factory);

  const voting = await deployProxy(deployer, Voting__factory, "Voting");

  await voting.__Voting_init(
    config.tssSigner,
    config.chainName,
    config.registrationSMT,
    await proposalsState.getAddress(),
    await votingVerifier.getAddress(),
  );

  await proposalsState.addVoting(config.votingName, await voting.getAddress());

  Reporter.reportContracts(["Voting", `${await voting.getAddress()}`]);
};
