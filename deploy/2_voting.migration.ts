import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import { VotingVerifier__factory, Voting__factory, ERC1967Proxy__factory, ProposalsState__factory } from "@ethers-v6";

import { getConfig } from "./config/config";

export = async (deployer: Deployer) => {
  const config = (await getConfig())!;

  const proposalsState = await deployer.deployed(ProposalsState__factory, "ProposalsState Proxy");

  const votingVerifier = await deployer.deploy(VotingVerifier__factory);

  let voting = await deployer.deploy(Voting__factory, { name: "Voting" });
  await deployer.deploy(ERC1967Proxy__factory, [await voting.getAddress(), "0x"], {
    name: "Voting Proxy",
  });
  voting = await deployer.deployed(Voting__factory, "Voting Proxy");

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
