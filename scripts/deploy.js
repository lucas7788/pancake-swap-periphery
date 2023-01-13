// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const {ethers} = require("hardhat");

async function main() {

    let signers = await ethers.getSigners();
    console.log(signers[0].address);

    //PancakeFactory: 0x1AA8c24ac757758e27E66E619429cA87d3Fc28BB
    // INIT_CODE_PAIR_HASH: 0xe7da666f616ba3bdb18c6908b22d556a41659bdd652762c246b8d1fa4f7506b4
    //0x0A6c7988FeAbF47C071d6cc72F93aFE80F794059
    let PancakeRouter = await deploy("PancakeRouter", "0x1AA8c24ac757758e27E66E619429cA87d3Fc28BB",
        "0xd8bc24cfd45452ef2c8bc7618e32330b61f2691b");
    console.log("PancakeRouter:", PancakeRouter.address);
    return;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});


async function deploy(name, ...param) {
    const Lock = await ethers.getContractFactory(name);
    const lock = await Lock.deploy(...param);

    return await lock.deployed();
}