import { Deployer, Reporter } from "@solarity/hardhat-migrate";
import { deployPoseidons, deployProxy } from "./helpers/helper";

import { ProposalSMT__factory, ProposalsState__factory } from "@ethers-v6";

import { getConfig } from "./config/config";

export = async (deployer: Deployer) => {
  const config = (await getConfig())!;

  await deployPoseidons(deployer, [2, 3]);

  let proposalSMT = await deployer.deploy(ProposalSMT__factory, { name: "ProposalSMT" });

  const proposalsState = await deployProxy(deployer, ProposalsState__factory, "ProposalsState");

  await proposalsState.__ProposalsState_init(config.tssSigner, config.chainName, await proposalSMT.getAddress());

  Reporter.reportContracts(["ProposalsState", `${await proposalsState.getAddress()}`]);
};
