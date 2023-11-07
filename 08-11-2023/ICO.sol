// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface FactoryICO {
    struct Vesting {
        uint256 presalePercent;
        uint256 vestingPeriodDays;
        uint256 eachCyclePercent;
        uint8 vestingRound;
    }

    function VestInfo() external view returns (Vesting memory);

    function ICOInfoCollect(
        address _ICO,
        string[] memory _string,
        uint[] memory _uint,
        address[] memory _address
    ) external;

    function ICOCreationFee() external view returns (uint);

    function lengthOfICO() external view returns (uint);

    function ICOApprovalInfoCollect(uint id, bool decision) external;

    function ICOFundInfoReq(uint id) external;

    function ICOStatusInfo(uint id, uint stautsnum) external;

    function ICOFundApprovalInfo(uint id, bool decision) external;

    function collectInvestorInfo(uint id, address _investor) external;

    function updateTimeInfo(
        uint id,
        uint startingTime,
        uint endingTime
    ) external;

    function updatePresaleInfo(uint id, uint presaleRate) external;

    function updateCapInfo(uint id, uint softCap, uint hardCap) external;
}

contract ICO is Ownable {
    uint public ICOId;

    address public icoOwner;
    address public factoryContract;
    address public Admin;

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
    }
    ICOListing public ICOlisting;

    struct ICOListingParameters {
        string logo;
        string socialMediaLink;
        address icoOwner;
        address payoutCurrency;
        address tokenAddress;
    }
    ICOListingParameters public ICOPara;

    //string array = ["projectname","description","logo","socialmedialink"]
    //uint array = ["presalerate","softcap","hardcap","minbuy","maxbuy","starttime","endtime","no of rounds"]
    //address array = ["icoowner","payoutcurrency","tokenaddress"]

    //["Finance","description","https://flowbite.com/docs/images/people/profile-picture-5.jpg","discord"]
    //["10000000000000000000","100000000000000000000","200000000000000000000","1000000000000000000","5000000000000000000","1691260104","1691346504","2"]
    //["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x5C9eb5D6a6C2c1B3EFc52255C0b356f116f6f66D","0x5C9eb5D6a6C2c1B3EFc52255C0b356f116f6f66D"]

    enum AdminApproveType {
        PENDING,
        ACCEPT,
        REJECT
    }
    AdminApproveType public adminApproveType;

    //ICO STATUS
    enum STATUS {
        UPCOMING,
        ACTIVE,
        ENDED,
        CANCELED
    }
    STATUS public status;

    // WHEN CREATOR  FINALIZE ICO
    enum FINALIZE_STATUS {
        NOT_YET,
        PENDING,
        ACCEPT,
        REJECT
    }
    FINALIZE_STATUS public finalizeStatus;

    struct allInfoList {
        ICOListing ICOlisting;
        ICOListingParameters ICOPara;
        AdminApproveType adminApproveType;
        STATUS status;
        FINALIZE_STATUS finalizeStatus;
    }
    allInfoList public AllInfoList;

    struct soldInfo {
        uint256 soldToken;
        uint256 availableToken;
        uint256 amountRaised;
    }
    soldInfo public SoldInfo;

    struct invest {
        uint256 totalAmount;
        uint256 totalToken;
        uint256 claimedToken;
        uint8 vestingRound;
    }
    mapping(address => invest) public Invest;
    address[] public investors;

    struct TokenInfo {
        string name;
        string symbol;
        uint8 decimal;
    }
    TokenInfo public tokenInfo;

    struct Vesting {
        uint256 presalePercent;
        uint256 vestingPeriodDays;
        uint256 eachCyclePercent;
        uint8 vestingRound;
    }
    Vesting public vesting;

    event ClaimInvestment(address from,address to, uint amount);
    event VestingClaim(address from,address to, uint vestingRound);
    event Buy(address investor, uint amountOfTokens);
    event UpdateSoftHardCap(uint ICOId,address ICO,uint softCap,uint hardCap,uint totalTokenForSale);
    event UpdatePresalrate(uint ICOId,address ICO,uint presaleRate,uint totalTokenForSale);
    event UpdateTime(uint ICOId,address ICO,uint startingTime,uint endingTime);
    event PoolCancelled(uint ICOId,address ICO,string statusOfICO);
    event WithdrawalRequest(uint ICOId,address ICO,string withdrawalReq);
    event FundApproval(uint ICOId,address ICO,string decision);
    event ICOApproval(uint ICOId,address ICO,string decision);
    event TokenInformation(string tokenName,string tokenSymbol,uint tokendecimals);
    event ICOCreated(uint ICOId,address ICO,string projectname ,string description,uint presalerate,uint softcap,uint hardcap,uint minbuy,uint maxbuy,uint starttime,uint endtime,address payoutcurrency);

    constructor(
        address ICOFactory,
        address _Admin,
        string[] memory _string,
        uint[] memory _uint,
        address[] memory _address
    ) payable {
        factoryContract = ICOFactory;
        Admin = _Admin;
        icoOwner = msg.sender;

        ICOlisting = ICOListing(
            _string[0],
            _string[1],
            _uint[0],
            _uint[1],
            _uint[2],
            _uint[3],
            _uint[4],
            _uint[5],
            _uint[6]
        );
        ICOPara = ICOListingParameters(
            _string[2],
            _string[3],
            _address[0],
            _address[1],
            _address[2]
        );
        AllInfoList = allInfoList(
            ICOlisting,
            ICOPara,
            adminApproveType,
            status,
            finalizeStatus
        );

       

        ICOId = FactoryICO(factoryContract).lengthOfICO();
        FactoryICO.Vesting memory vestInfo = FactoryICO(factoryContract)
            .VestInfo();
        vesting = Vesting(
            vestInfo.presalePercent,
            vestInfo.vestingPeriodDays,
            vestInfo.eachCyclePercent,
            vestInfo.vestingRound
        );

        tokenInfo = TokenInfo(
            IERC20(ICOPara.tokenAddress).name(),
            IERC20(ICOPara.tokenAddress).symbol(),
            IERC20(ICOPara.tokenAddress).decimals()
        );

        emit TokenInformation(IERC20(ICOPara.tokenAddress).name(),IERC20(ICOPara.tokenAddress).symbol(),IERC20(ICOPara.tokenAddress).decimals());

        SoldInfo.availableToken =
            (ICOlisting.hardCap * ICOlisting.presaleRate) /
            10 ** IERC20(ICOPara.payoutCurrency).decimals();
        //IERC20(ICOPara.tokenAddress).approve(address(this),SoldInfo.availableToken);

        FactoryICO(factoryContract).ICOInfoCollect(
            address(this),
            _string,
            _uint,
            _address
        );
        emit ICOCreated(ICOId,address(this),_string[0],_string[1], _uint[0],_uint[1], _uint[2],_uint[3],_uint[4],_uint[5],_uint[6],_address[1]);
        uint fee = FactoryICO(factoryContract).ICOCreationFee();
        payable(Admin).transfer(fee);
    }

    //-----------------------------------------------------------------------------------------------------------------------------

    // function collectAllInfoList() public view returns (allInfoList memory) {
    //     return AllInfoList;
    // }

    //-----------------------------------------Modifiers---------------------------------------------------------------------

    modifier onlyInvestor() {
        require(
            Invest[_msgSender()].totalAmount != 0,
            "You are not a investor"
        );
        _;
    }

    modifier beforeApproval() {
        require(
            adminApproveType == AdminApproveType.PENDING,
            "Cannot change after admin approval"
        );
        _;
    }

    //------------------------------------------------------------------------------------------------------------------------------

    function isICOEnd() public view returns (bool) {
        if (
            block.timestamp > ICOlisting.endTime ||
            ICOlisting.hardCap == SoldInfo.amountRaised
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isSoftCapReach() public view returns (bool) {
        if (ICOlisting.softCap <= SoldInfo.amountRaised) {
            return true;
        } else {
            return false;
        }
    }

    //-----------------------------------------------------------------------------------------------------------------------------

    //-------------------------------------Functions for Admin Approval------------------------------------------------------------
    function iCOApproval(bool decision) public {
        require(Admin == msg.sender, "Only admin can call this");
        require(
            adminApproveType == AdminApproveType.PENDING,
            "Already decided"
        );
        if (decision == true) {
            adminApproveType = AdminApproveType.ACCEPT;
            status = STATUS.ACTIVE;
            AllInfoList = allInfoList(
                ICOlisting,
                ICOPara,
                adminApproveType,
                status,
                finalizeStatus
            );
            IERC20(ICOPara.tokenAddress).transferFrom(
                owner(),
                address(this),
                SoldInfo.availableToken
            );
            FactoryICO(factoryContract).ICOStatusInfo(ICOId, 1);
            emit ICOApproval(ICOId,address(this),"Accepted");
        } else {
            adminApproveType = AdminApproveType.REJECT;
            AllInfoList = allInfoList(
                ICOlisting,
                ICOPara,
                adminApproveType,
                status,
                finalizeStatus
            );
            emit ICOApproval(ICOId,address(this),"Rejected");
        }
        FactoryICO(factoryContract).ICOApprovalInfoCollect(ICOId, decision);
    }

    function fundApproval(bool decision) public {
        require(Admin == msg.sender, "Only admin can call this");
        require(
            finalizeStatus == FINALIZE_STATUS.PENDING,
            "ICO Owner did not created request yet"
        );
        if (decision == true) {
            finalizeStatus = FINALIZE_STATUS.ACCEPT;
            IERC20(ICOPara.payoutCurrency).transfer(
                owner(),
                SoldInfo.amountRaised
            );
            IERC20(ICOPara.tokenAddress).transfer(
                owner(),
                SoldInfo.availableToken
            );
            ICOlisting.endTime = block.timestamp;
            AllInfoList = (
                allInfoList(
                    ICOlisting,
                    ICOPara,
                    adminApproveType,
                    status,
                    finalizeStatus
                )
            );

            emit FundApproval(ICOId,address(this),"Accepted");
        } else {
            finalizeStatus = FINALIZE_STATUS.REJECT;
            IERC20(ICOPara.tokenAddress).transfer(
                owner(),
                (ICOlisting.hardCap * ICOlisting.presaleRate) /
                    10 ** IERC20(ICOPara.tokenAddress).decimals()
            );
            AllInfoList = (
                allInfoList(
                    ICOlisting,
                    ICOPara,
                    adminApproveType,
                    status,
                    finalizeStatus
                )
            );

            emit FundApproval(ICOId,address(this),"Rejected");
        }
        FactoryICO(factoryContract).ICOFundApprovalInfo(ICOId, decision);
    }

    //-----------------------------------------------------------------------------------------------------------------------------

    //-------------------------Functions only ICO Owner can call---------------------------------------------------

    function finalizedRequest() public onlyOwner {
        require(
            isSoftCapReach() == true,
            "Softcap did not reach.So can't finalize"
        );
        require(
            finalizeStatus == FINALIZE_STATUS.NOT_YET,
            "Check Finalize Status"
        );
        require(status != STATUS.CANCELED, "Pool already cancelled");
        finalizeStatus = FINALIZE_STATUS.PENDING;
        status = STATUS.ENDED;
        AllInfoList = (
            allInfoList(
                ICOlisting,
                ICOPara,
                adminApproveType,
                status,
                finalizeStatus
            )
        );
        FactoryICO(factoryContract).ICOFundInfoReq(ICOId);
        FactoryICO(factoryContract).ICOStatusInfo(ICOId, 2);

        emit WithdrawalRequest(ICOId,address(this),"Request Generated");
    }

    function cancelPool() public onlyOwner {
        require(
            finalizeStatus == FINALIZE_STATUS.NOT_YET,
            "already asked for approval, Can't cancel"
        );
        require(status != STATUS.CANCELED, "Pool already cancelled");
        //ICOfactory(factoryContract).collectActiveInfo(address(this), false);

        IERC20(ICOPara.tokenAddress).transfer(
            msg.sender,
            IERC20(ICOPara.tokenAddress).balanceOf(address(this))
        );
        status = STATUS.CANCELED;
        AllInfoList = (
            allInfoList(
                ICOlisting,
                ICOPara,
                adminApproveType,
                status,
                finalizeStatus
            )
        );
        FactoryICO(factoryContract).ICOStatusInfo(ICOId, 3);

        emit PoolCancelled(ICOId,address(this),"CANCELED");
    }

    function updateTime(
        uint startingTime,
        uint endingTime
    ) public beforeApproval onlyOwner {
        ICOlisting.startTime = startingTime;
        ICOlisting.endTime = endingTime;

        AllInfoList = (
            allInfoList(
                ICOlisting,
                ICOPara,
                adminApproveType,
                status,
                finalizeStatus
            )
        );
        FactoryICO(factoryContract).updateTimeInfo(
            ICOId,
            startingTime,
            endingTime
        );

        emit UpdateTime(ICOId,address(this),startingTime,endingTime);
    }

    function updatePresalerate(
        uint presaleRate
    ) public beforeApproval onlyOwner {
        ICOlisting.presaleRate = presaleRate;
        SoldInfo.availableToken =
            (ICOlisting.hardCap * ICOlisting.presaleRate) /
            10 ** IERC20(ICOPara.payoutCurrency).decimals();
        AllInfoList = (
            allInfoList(
                ICOlisting,
                ICOPara,
                adminApproveType,
                status,
                finalizeStatus
            )
        );
        FactoryICO(factoryContract).updatePresaleInfo(ICOId, presaleRate);
        emit UpdatePresalrate(ICOId,address(this),presaleRate,SoldInfo.availableToken);
    }

    function updateSoftHardCap(
        uint _softCap,
        uint _hardCap
    ) public beforeApproval onlyOwner {
        ICOlisting.softCap = _softCap;
        ICOlisting.hardCap = _hardCap;
        SoldInfo.availableToken =
            (ICOlisting.hardCap * ICOlisting.presaleRate) /
            10 ** IERC20(ICOPara.payoutCurrency).decimals();
        AllInfoList = (
            allInfoList(
                ICOlisting,
                ICOPara,
                adminApproveType,
                status,
                finalizeStatus
            )
        );
        FactoryICO(factoryContract).updateCapInfo(ICOId, _softCap, _hardCap);
        emit UpdateSoftHardCap(ICOId,address(this),_softCap,_hardCap,SoldInfo.availableToken);
    }

    //----------------------------------------------------------------------------------------------------------------

    function buy(uint256 amount) public {
        require(
            adminApproveType == AdminApproveType.ACCEPT,
            "Admin did not approved yet"
        );
        require(status != STATUS.CANCELED, "This ICO is cancelled");
        require(block.timestamp >= ICOlisting.startTime, "Not started Yet");

        uint256 am = Invest[msg.sender].totalAmount + amount;
        require(
            am >= ICOlisting.minBuy && am <= ICOlisting.maxBuy,
            "Please check amount range"
        );
        require(isICOEnd() == false, "ICO has already end");

        uint256 token = (ICOlisting.presaleRate * amount) /
            10 ** IERC20(ICOPara.payoutCurrency).decimals();
        require(SoldInfo.availableToken >= token, "Not enough token for sale");

        if (Invest[msg.sender].totalAmount == 0) {
            investors.push(msg.sender);
            FactoryICO(factoryContract).collectInvestorInfo(ICOId, msg.sender);
        }

        IERC20(ICOPara.payoutCurrency).transferFrom(
            _msgSender(),
            address(this),
            amount
        );

        Invest[msg.sender].totalToken += token;
        Invest[msg.sender].totalAmount += amount;
        SoldInfo.availableToken -= token;
        SoldInfo.soldToken += token;
        SoldInfo.amountRaised += amount;

        emit Buy(_msgSender(),token);

    }

    function vestingClaim() public onlyInvestor {
        require(
            finalizeStatus == FINALIZE_STATUS.ACCEPT,
            "pool not approved yet"
        );

        uint256 time = ICOlisting.endTime +
            Invest[_msgSender()].vestingRound *
            vesting.vestingPeriodDays;

        if (Invest[_msgSender()].vestingRound == 0) {
            uint256 token = (Invest[_msgSender()].totalToken *
                vesting.presalePercent) / 10000;
            IERC20(ICOPara.tokenAddress).transfer(_msgSender(), token);
            Invest[_msgSender()].claimedToken += token;
            Invest[_msgSender()].vestingRound++;
        } else {
            require(
                Invest[_msgSender()].totalToken !=
                    Invest[_msgSender()].claimedToken,
                "You already claim tokens fully"
            );
            require(block.timestamp >= time, "wait for locking period");
            uint256 token = (Invest[_msgSender()].totalToken *
                vesting.eachCyclePercent) / 10000;
            IERC20(ICOPara.tokenAddress).transfer(_msgSender(), token);
            Invest[_msgSender()].claimedToken += token;
            Invest[_msgSender()].vestingRound++;
        }

        emit VestingClaim(_msgSender(),address(this),Invest[_msgSender()].vestingRound);
    }

    function claim() public onlyInvestor {
        if (
            status == STATUS.CANCELED ||
            finalizeStatus == FINALIZE_STATUS.REJECT ||
            (isSoftCapReach() == false && ICOlisting.endTime < block.timestamp)
        ) {
            IERC20(ICOPara.payoutCurrency).transfer(
                _msgSender(),
                Invest[_msgSender()].totalAmount
            );

            emit ClaimInvestment(_msgSender(),address(this),Invest[_msgSender()].totalAmount);
            Invest[_msgSender()] = invest(0, 0, 0, 0);
            
        } else {
            require(false, "Can't claim");
        }
    }

    function numInvestors() public view returns (uint) {
        return investors.length;
    }
}
