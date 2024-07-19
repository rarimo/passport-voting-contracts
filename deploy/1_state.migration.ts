import { Deployer, Reporter } from "@solarity/hardhat-migrate";
import { deployPoseidons } from "./helpers/helper";

import { ProposalSMT__factory, ProposalsState__factory, ERC1967Proxy__factory } from "@ethers-v6";

import { getConfig } from "./config/config";

export = async (deployer: Deployer) => {
  const config = (await getConfig())!;

  await deployPoseidons(deployer, [2, 3]);

  let proposalSMT = await deployer.deploy(ProposalSMT__factory, { name: "ProposalSMT" });

  let proposalsState = await deployer.deploy(ProposalsState__factory, { name: "ProposalsState" });
  await deployer.deploy(ERC1967Proxy__factory, [await proposalsState.getAddress(), "0x"], {
    name: "ProposalsState Proxy",
  });
  proposalsState = await deployer.deployed(ProposalsState__factory, "ProposalsState Proxy");

  await proposalsState.__ProposalsState_init(config.tssSigner, config.chainName, await proposalSMT.getAddress());

  Reporter.reportContracts(["ProposalsState", `${await proposalsState.getAddress()}`]);
};
