import { ethers } from "hardhat";
import { HDNodeWallet } from "ethers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";

import { Reverter, chainName } from "@/test/helpers";

import { RegistrationSMTReplicator } from "@ethers-v6";

const prefix = "Rarimo passport root";
const sourceSMT = "0xc1534912902bbe8c54626e2d69288c76a843bc0e";

describe("RegistrationSMTReplicator", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SIGNER: HDNodeWallet;

  let replicator: RegistrationSMTReplicator;

  async function transitRoot(root: string, timestamp: number) {
    const leaf = ethers.solidityPackedKeccak256(
      ["string", "address", "address", "bytes32", "uint256"],
      [prefix, sourceSMT, await replicator.getAddress(), root, timestamp],
    );
    const signature = ethers.Signature.from(SIGNER.signingKey.sign(leaf)).serialized;

    const coder = ethers.AbiCoder.defaultAbiCoder();
    const data = coder.encode(["bytes32[]", "bytes"], [[], signature]);

    await replicator.transitionRoot(root, timestamp, data);
  }

  before("setup", async () => {
    [OWNER] = await ethers.getSigners();
    SIGNER = ethers.Wallet.createRandom();

    const Replicator = await ethers.getContractFactory("RegistrationSMTReplicator");
    replicator = await Replicator.deploy();

    await replicator.__RegistrationSMTReplicator_init(SIGNER, sourceSMT, chainName);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("transitionRoot()", () => {
    it("should transit state", async () => {
      const randomRoot = ethers.hexlify(ethers.randomBytes(32));
      const curTime = await time.latest();

      expect(await replicator.isRootValid(randomRoot)).to.be.false;

      await transitRoot(randomRoot, curTime);

      expect(await replicator.latestRoot()).to.equal(randomRoot);
      expect(await replicator.latestTimestamp()).to.equal(curTime);

      expect(await replicator.isRootValid(randomRoot)).to.be.true;
    });

    it("should transit old root", async () => {
      const firstRoot = ethers.hexlify(ethers.randomBytes(32));
      const curTime = await time.latest();

      await transitRoot(firstRoot, curTime);

      const secondRoot = ethers.hexlify(ethers.randomBytes(32));
      const secondTime = curTime - 1;

      await transitRoot(secondRoot, secondTime);

      expect(await replicator.latestRoot()).to.equal(firstRoot);

      expect(await replicator.isRootValid(secondRoot)).to.be.true;
    });
  });
});
