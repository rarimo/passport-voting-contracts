import { expect } from "chai";
import { ethers } from "hardhat";
import { HDNodeWallet } from "ethers";

import { time } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter, getPoseidon, votingName } from "@/test/helpers";

import { AQueryProofExecutor } from "@/generated-types/ethers/contracts/voting/BaseVoting";

import { BioPassportVoting, ProposalsState } from "@ethers-v6";

describe("Voting", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SIGNER: HDNodeWallet;

  let voting: BioPassportVoting;
  let proposalsState: ProposalsState;

  async function deployState() {
    const Proxy = await ethers.getContractFactory("ERC1967Proxy");
    const ProposalSMT = await ethers.getContractFactory("ProposalSMT", {
      libraries: {
        PoseidonUnit2L: await (await getPoseidon(2)).getAddress(),
        PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
      },
    });
    const ProposalsState = await ethers.getContractFactory("ProposalsState", {
      libraries: {
        PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
      },
    });

    const proposalSMT = await ProposalSMT.deploy();
    proposalsState = await ProposalsState.deploy();

    let proxy = await Proxy.deploy(await proposalsState.getAddress(), "0x");
    proposalsState = proposalsState.attach(await proxy.getAddress()) as ProposalsState;

    await proposalsState.__ProposalsState_init(await proposalSMT.getAddress(), 0n);
  }

  async function deployVoting() {
    const Proxy = await ethers.getContractFactory("ERC1967Proxy");
    const RegistrationSMTMock = await ethers.getContractFactory("RegistrationSMTMock");
    const VerifierMock = await ethers.getContractFactory("VerifierMock");
    const Voting = await ethers.getContractFactory("BioPassportVoting");

    const registrationSMTMock = await RegistrationSMTMock.deploy();
    const verifierMock = await VerifierMock.deploy();

    voting = await Voting.deploy();

    let proxy = await Proxy.deploy(await voting.getAddress(), "0x");
    voting = voting.attach(await proxy.getAddress()) as BioPassportVoting;

    await voting.__BioPassportVoting_init(
      await registrationSMTMock.getAddress(),
      await proposalsState.getAddress(),
      await verifierMock.getAddress(),
    );
  }

  before("setup", async () => {
    [OWNER] = await ethers.getSigners();
    SIGNER = ethers.Wallet.createRandom();

    await deployState();
    await deployVoting();

    await proposalsState.addVoting(votingName, await voting.getAddress());

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  function getVotingConfig() {
    const coder = ethers.AbiCoder.defaultAbiCoder();

    return coder.encode(
      ["tuple(uint256,uint256[],uint256,uint256,uint256,uint256,uint256,uint256)"],
      [[0x00, [0x554b52, 0x47454f], 1721401330, 1, 0x00, 0x303030303030, 0x303630373139, 0x323430373139]],
    );
  }

  async function getCurrentDate() {
    let res: string = "0x";
    const date = new Date((await time.latest()) * 1000);

    res += "3" + date.getUTCFullYear().toString()[2] + "3" + date.getUTCFullYear().toString()[3];

    let month = (date.getUTCMonth() + 1).toString();

    if (month.length == 1) {
      month = "0" + month;
    }

    res += "3" + month[0] + "3" + month[1];

    let day = date.getUTCDate().toString();

    if (day.length == 1) {
      day = "0" + day;
    }

    res += "3" + day[0] + "3" + day[1];

    return res;
  }

  describe("#vote", () => {
    it("should vote", async () => {
      const proposalConfig: ProposalsState.ProposalConfigStruct = {
        startTimestamp: await time.latest(),
        duration: 11223344,
        multichoice: 0,
        acceptedOptions: [3, 7, 15],
        description: "doesn't really matter",
        votingWhitelist: [await voting.getAddress()],
        votingWhitelistData: [getVotingConfig()],
      };

      await proposalsState.createProposal(proposalConfig);

      const userData = {
        nullifier: ethers.hexlify(ethers.randomBytes(31)),
        citizenship: 0x554b52,
        identityCreationTimestamp: 123456,
      };

      const zkProof: AQueryProofExecutor.ProofPointsStruct = {
        a: [0, 0],
        b: [
          [0, 0],
          [0, 0],
        ],
        c: [0, 0],
      };

      const encodedData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["uint256", "uint256[]", "tuple(uint256,uint256,uint256)"],
        [1, [1, 4, 2], Object.values(userData)],
      );

      await voting.execute(ethers.hexlify(ethers.randomBytes(32)), await getCurrentDate(), encodedData, zkProof);

      const proposalInfo = await proposalsState.getProposalInfo(1);

      expect(proposalInfo.status).to.eq(2);
      expect(proposalInfo.config.description).to.eq(proposalConfig.description);
      expect(proposalInfo.votingResults).to.deep.eq([
        [1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0, 0, 0, 0],
        [0, 1, 0, 0, 0, 0, 0, 0],
      ]);
    });
  });
});
