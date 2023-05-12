// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract demo {
  // event testEvent(uint indexed a,uint indexed b, bool indexed c,uint  d);
  function test()  public returns(uint8){
    uint8 a=3;

    uint8 res=a/2;
    // emit testEvent(2,3,true,4);
    return res;
  }
}

contract Patient  {
    uint256 public p_index = 0;

    struct Records {
        string cname;

        string l_cadence;
        string r_cadence;
        string n_cadence;

        string l_dsupport;
        string r_dsupport;
        string n_dsupport;

        string l_footoff;
        string r_footoff;
        string n_footoff;

        string l_steptime;
        string r_steptime;
        string n_steptime;


        string admittedOn;
        string dischargedOn;
        string ipfs;
    }

    struct patient {
        uint256 id;
        string name;
        string phone;
        string gender;
        string dob;
        string bloodgroup;
        string allergies;
        Records[] records;
        address addr;
    }

    address[] private patientList;
    mapping(address => mapping(address=>bool)) isAuth;
    mapping(address=>patient) patients;
    mapping(address=>bool) isPatient;

    function addRecord() public  returns(uint8){
        return 2;
    }
}