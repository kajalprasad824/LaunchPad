// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ICOFactory is Ownable{
    uint public ICOCreationFee;
    uint public ICOReq;
    address[] public allICOAddress;
    
    enum AdminApproveType {
        PENDING,
        ACCEPT,
        REJECT
    }
    AdminApproveType adminApproveType;

    //ICO STATUS
    enum STATUS {
        UPCOMING,
        ACTIVE,
        ENDED,
        CANCELED
    }
    STATUS status;

    // WHEN CREATOR  FINALIZE ICO
    enum FINALIZE_STATUS {
        NOT_YET,
        PENDING,
        ACCEPT,
        REJECT
    }
    FINALIZE_STATUS finalizeStatus;

    struct ICOListing {
        string projectName;
        string description;
        uint256 presaleRate;
        uint256 softCap;
        uint256 hardCap;
        uint256 minBuy;
        uint256 maxBuy;
        uint256 startTime;
        uint256 endTime;
        uint round;
    }
    ICOListing ICOlisting;

    struct ICOListingParameters {
        string logo;
        string socialMediaLink;
        address icoOwner;
        address payoutCurrency;
        address tokenAddress;
    }
    ICOListingParameters ICOPara;

    struct allInfoList {
        address ICO;
        ICOListing ICOlisting;
        ICOListingParameters ICOPara;
        AdminApproveType adminApproveType;
        STATUS status;
        FINALIZE_STATUS finalizeStatus;
    }

    struct Vesting {
        uint256 presalePercent;
        uint256 vestingPeriodDays;
        uint256 eachCyclePercent;
        uint8 vestingRound;
    }
    Vesting public vesting;

    //[1000, 3600, 1000, 10]

    struct roundInfo {
        uint currentRound;
        uint totalRound;
    }
    mapping(address => mapping(string => roundInfo)) public rounds;
    //[1000, 1, 1000, 10]
    //allInfoList public AllInfoList;
    allInfoList[] public allICOListing;
    mapping(uint => allInfoList) public allICOList;

    mapping(address => uint[]) public userAllInfo;
    mapping(address => string[]) public projectNames;
    mapping(address => uint[]) public investorInfo;

    event UpdateICOCreationFee(uint ICOCreationFee);
   
    event UpdateVesting(uint256 presalePercent,uint256 vestingPeriodDays,uint256 eachCyclePercent,uint8 vestingRound);

    event CurrentRound(uint round);

    constructor(
        address initialOwner,
        uint _ICOCreationFee,
        Vesting memory vestingInfo) Ownable(initialOwner){
         uint256 total = vestingInfo.presalePercent +
            (vestingInfo.vestingRound - 1) *
            vestingInfo.eachCyclePercent;
        require(total == 10000, "Please check percentage");
        ICOCreationFee = _ICOCreationFee;
        vesting = Vesting(
            vestingInfo.presalePercent,
            vestingInfo.vestingPeriodDays,
            vestingInfo.eachCyclePercent,
            vestingInfo.vestingRound
        );
    }

    //----------------------Update Functions Admin---------------------------------------------

    function updateICOCreationFee(uint256 _ICOCreationFee) external onlyOwner {
        ICOCreationFee = _ICOCreationFee;
        emit UpdateICOCreationFee(_ICOCreationFee);
    }

    function updateVestingInfo(Vesting memory _VestingInfo) external onlyOwner {
        uint256 total = _VestingInfo.presalePercent +
            (_VestingInfo.vestingRound - 1) *
            _VestingInfo.eachCyclePercent;
        require(total == 10000, "Please check percentage");
        vesting = Vesting(
            _VestingInfo.presalePercent,
            _VestingInfo.vestingPeriodDays,
            _VestingInfo.eachCyclePercent,
            _VestingInfo.vestingRound
        );
        emit UpdateVesting(_VestingInfo.presalePercent, _VestingInfo.vestingPeriodDays,_VestingInfo.eachCyclePercent,_VestingInfo.vestingRound);
    }

    //-----------------------------------------------------------------------------------------------

    function ICOInfoCollect(
        address _ICO,
        string[] memory _string,
        uint[] memory _uint,
        address[] memory _address
    ) external {
        if (rounds[_address[0]][_string[0]].currentRound == 0) {
            require(
                _uint[7] >= 1,
                "Projects round shuold be equal or greater than 1"
            );
            projectNames[_address[0]].push(_string[0]);
            rounds[_address[0]][_string[0]].totalRound = _uint[7];
        }

        rounds[_address[0]][_string[0]].currentRound++;

        uint r = rounds[_address[0]][_string[0]].currentRound;

        require(
            r <= rounds[_address[0]][_string[0]].totalRound,
            "Total rounds for this project already complete"
        );
        require(_uint[0] > 0, "Presale rate should be greater than zero");
        require(
            _uint[6] > _uint[5],
            "End time should be greater than start time"
        );
        require(_uint[3] > 0, "Minimum Buy can not be equal to zero");
        require(
            _uint[4] > _uint[3],
            "Maximum buy should be greater than minimum buy"
        );
        require(
            _uint[1] > 0 && _uint[2] > 0,
            "Soft cap and hard cap shoulb be greater than zero"
        );

        ICOlisting = ICOListing(
            _string[0],
            _string[1],
            _uint[0],
            _uint[1],
            _uint[2],
            _uint[3],
            _uint[4],
            _uint[5],
            _uint[6],
            r
        );
        ICOPara = ICOListingParameters(
            _string[2],
            _string[3],
            _address[0],
            _address[1],
            _address[2]
        );

        allICOListing.push(
            allInfoList(
                _ICO,
                ICOlisting,
                ICOPara,
                AdminApproveType.PENDING,
                STATUS.UPCOMING,
                FINALIZE_STATUS.NOT_YET
            )
        );
        allICOList[ICOReq] = (
            allInfoList(
                _ICO,
                ICOlisting,
                ICOPara,
                AdminApproveType.PENDING,
                STATUS.UPCOMING,
                FINALIZE_STATUS.NOT_YET
            )
        );

        userAllInfo[_address[0]].push(ICOReq);
        
        emit CurrentRound(r);
        ICOReq++;
    }

    function ICOApprovalInfoCollect(uint id, bool decision) external {
        if (decision == true) {
            allICOList[id].adminApproveType = AdminApproveType.ACCEPT;
        } else {
            allICOList[id].adminApproveType = AdminApproveType.REJECT;
        }
    }

    function ICOFundInfoReq(uint id) external {
        allICOList[id].finalizeStatus = FINALIZE_STATUS.PENDING;
    }

    function ICOFundApprovalInfo(uint id, bool decision) external {
        if (decision == true) {
            allICOList[id].finalizeStatus = FINALIZE_STATUS.ACCEPT;
        } else {
            allICOList[id].finalizeStatus = FINALIZE_STATUS.REJECT;
        }
    }

    function ICOStatusInfo(uint id, uint stautsnum) external {
        if (stautsnum == 1) {
            allICOList[id].status = STATUS.ACTIVE;
        } else if (stautsnum == 2) {
            allICOList[id].status = STATUS.ENDED;
        } else if (stautsnum == 3) {
            allICOList[id].status = STATUS.CANCELED;
        }
    }

    function collectInvestorInfo(uint id, address _investor) external {
        investorInfo[_investor].push(id);
    }

    function updateTimeInfo(
        uint id,
        uint startingTime,
        uint endingTime
    ) external {
        allICOList[id].ICOlisting.startTime = startingTime;
        allICOList[id].ICOlisting.endTime = endingTime;
    }

    function updatePresaleInfo(uint id, uint presaleRate) external {
        allICOList[id].ICOlisting.presaleRate = presaleRate;
    }

    function updateCapInfo(uint id, uint softCap, uint hardCap) external {
        allICOList[id].ICOlisting.softCap = softCap;
        allICOList[id].ICOlisting.hardCap = hardCap;
    }

    //------------------------------------------------------------------------------------------------

    function VestInfo() external view returns (Vesting memory) {
        return vesting;
    }

    function lengthOfICO() external view returns (uint) {
        return allICOListing.length;
    }

    function userInfo() external view returns (uint[] memory) {
        return userAllInfo[msg.sender];
    }

    function InvestorInfo() external view returns (uint[] memory) {
        return investorInfo[msg.sender];
    }

    function userProjectNames() external view returns (string[] memory) {
        return projectNames[msg.sender];
    }
}
