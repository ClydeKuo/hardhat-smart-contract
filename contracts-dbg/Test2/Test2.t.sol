// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.21 < 0.9.0;
// import  "../../contracts/demo.sol";
interface IDemo{
    function test() external view returns(uint64);
}
contract DbgEntry {
    event EvmPrint(string);
    event EvmSpoofMsgSender(address);
    constructor() {
        emit EvmPrint("DbgEntry.constructor");

        // Here you can either deploy your contracts via `new`, eg:
        //  Counter counter = new Counter();
        //  counter.increment();
        IDemo demo=IDemo(0x6214842E42679b870932776BB7214da2F9434DD9);
        // emit EvmSpoofMsgSender(0x15F7BE2CC4BAaF4E686bB3C67bE53d297259Caf6);
        demo.test();
        // or interact with an existing deployment by specifying a `fork` url in `dbg.project.json`
        // eg:
        //  ICounter counter = ICounter(0x12345678.....)
        //  counter.increment(); 
        //
        // If you have correct symbols (`artifacts`) for the deployed contract, you can step-into calls.

        uint256 abc = 123;
        uint256 def = abc + 5;

        emit EvmPrint("DbgEntry return");
    }
}