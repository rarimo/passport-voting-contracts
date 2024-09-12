import { ethers } from "hardhat";

import { Deployer } from "@solarity/hardhat-migrate";

import { ProposalsState__factory } from "@ethers-v6";

function getVotingConfig() {
  const coder = ethers.AbiCoder.defaultAbiCoder();

  return coder.encode(
    ["tuple(uint256[],uint256,uint256,uint256,uint256)"],
    [[[0x554b52, 0x47454f], 1723720410, 1, 0x303630373139, 0x323430373139]],
  );
}

export = async (deployer: Deployer) => {
  let proposalsState = await deployer.deployed(ProposalsState__factory, "0x13f68a62785C4f0cc886D3387a67E9D582F12528");

  // await proposalsState.hideProposal(1, true);

  await proposalsState.createProposal({
    startTimestamp: 1725615572,
    duration: 7200,
    multichoice: 0,
    acceptedOptions: [31, 7, 31, 7],
    description: "https://ipfs.io/ipfs/QmUGDxQPciiSjRfoeqQEj67c4uZNRUZQhK6KPzJUE3o6wy",
    votingWhitelist: ["0x370061172B2eebeDcfd9C5bb8C06CF64fe9989DA"],
    votingWhitelistData: [getVotingConfig()],
  });

  await proposalsState.createProposal({
    startTimestamp: 1725615572,
    duration: 43200,
    multichoice: 0,
    acceptedOptions: [31, 15, 31, 15],
    description: "https://ipfs.io/ipfs/QmdwAFqQzuyfq9kUVErAmgoZQkT8mRWKsF3yZThqd8UDwm",
    votingWhitelist: ["0x370061172B2eebeDcfd9C5bb8C06CF64fe9989DA"],
    votingWhitelistData: [getVotingConfig()],
  });

  await proposalsState.createProposal({
    startTimestamp: 1725615572,
    duration: 172800,
    multichoice: 0,
    acceptedOptions: [31, 7, 31, 7],
    description: "https://ipfs.io/ipfs/QmUGDxQPciiSjRfoeqQEj67c4uZNRUZQhK6KPzJUE3o6wy",
    votingWhitelist: ["0x370061172B2eebeDcfd9C5bb8C06CF64fe9989DA"],
    votingWhitelistData: [getVotingConfig()],
  });

  await proposalsState.createProposal({
    startTimestamp: 1725615572,
    duration: 604800,
    multichoice: 0,
    acceptedOptions: [3, 7],
    description: "https://ipfs.io/ipfs/QmWfNQzzbFJYPLh2oGq7X25X9ePYqjDb3MqJ9PZfy7jZ5r",
    votingWhitelist: ["0x370061172B2eebeDcfd9C5bb8C06CF64fe9989DA"],
    votingWhitelistData: [getVotingConfig()],
  });

  await proposalsState.createProposal({
    startTimestamp: 1725615572,
    duration: 1209600,
    multichoice: 0,
    acceptedOptions: [15],
    description: "https://ipfs.io/ipfs/QmSS2ontPYJHJxsTKoSmjekY8KUZVBQBrnnyukVCtNha6R",
    votingWhitelist: ["0x370061172B2eebeDcfd9C5bb8C06CF64fe9989DA"],
    votingWhitelistData: [getVotingConfig()],
  });

  /* prod */

  // let proposalsState = await deployer.deployed(ProposalsState__factory, "0x179f262777Dc03b1CD8891D6d3Fa091DE337D308");

  // await proposalsState.hideProposal(3, true);

  // await proposalsState.createProposal({
  //   startTimestamp: 1723734096,
  //   duration: 3600,
  //   multichoice: 0,
  //   acceptedOptions: [3, 7],
  //   description: "https://ipfs.io/ipfs/QmWfNQzzbFJYPLh2oGq7X25X9ePYqjDb3MqJ9PZfy7jZ5r",
  //   votingWhitelist: ["0x3352e899Ac27804E5C632187CC970c16AE9909f7"],
  //   votingWhitelistData: [getVotingConfig()],
  // });

  // await proposalsState.createProposal({
  //   startTimestamp: 1723720410,
  //   duration: 4002390,
  //   multichoice: 0,
  //   acceptedOptions: [15],
  //   description: "https://ipfs.io/ipfs/QmSS2ontPYJHJxsTKoSmjekY8KUZVBQBrnnyukVCtNha6R",
  //   votingWhitelist: ["0x3352e899Ac27804E5C632187CC970c16AE9909f7"],
  //   votingWhitelistData: [getVotingConfig()],
  // });

  console.log(await proposalsState.lastProposalId());
};
