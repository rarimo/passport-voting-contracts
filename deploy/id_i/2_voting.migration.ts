import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import { ProposalsState__factory, NoirTD1Verifier_ID_Card_I__factory, BioPassportVoting__factory } from "@ethers-v6";

import { getConfig } from "../config/config";

export = async (deployer: Deployer) => {
  const config = (await getConfig())!;

  const proposalsState = await deployer.deployed(ProposalsState__factory);

  const noirTD1VerifierIDCardI = await deployer.deploy(NoirTD1Verifier_ID_Card_I__factory);

  const noirIDVoting = await deployer.deployERC1967Proxy(BioPassportVoting__factory);

  await noirIDVoting.__BioPassportVoting_init(
    config.registrationSMT,
    await proposalsState.getAddress(),
    await noirTD1VerifierIDCardI.getAddress(),
  );

  await proposalsState.addVoting("NoirIDVoting", await noirIDVoting.getAddress());

  await Reporter.reportContractsMD(
    ["NoirIDVoting", `${await noirIDVoting.getAddress()}`],
    ["ProposalsState", `${await proposalsState.getAddress()}`],
  );
};
