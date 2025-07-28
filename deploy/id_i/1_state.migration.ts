import { Deployer } from "@solarity/hardhat-migrate";

import { ProposalSMT__factory, ProposalsState__factory } from "@ethers-v6";

import { getConfig } from "../config/config";

export = async (deployer: Deployer) => {
  const config = (await getConfig())!;

  let proposalSMT = await deployer.deploy(ProposalSMT__factory, { name: "ProposalSMT" });

  const proposalsState = await deployer.deployERC1967Proxy(ProposalsState__factory);

  await proposalsState.__ProposalsState_init(await proposalSMT.getAddress(), config.minFundingAmount);
};
