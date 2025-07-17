import hre from "hardhat";

export async function getConfig() {
  if (hre.network.name == "localhost" || hre.network.name == "hardhat") {
    return await import("./localhost");
  }

  if (hre.network.name == "sepolia") {
    return await import("./sepolia");
  }

  if (hre.network.name == "q-testnet") {
    return await import("./q-testnet");
  }

  if (hre.network.name == "rarimo-l2") {
    return await import("./rarimo-l2");
  }

  if (hre.network.name == "rarimo-beta") {
    return await import("./rarimo-beta");
  }

  if (hre.network.name == "rarimo-l2-testnet") {
    return await import("./rarimo-l2-testnet");
  }

  throw new Error(`Config for network ${hre.network.name} is not specified`);
}
