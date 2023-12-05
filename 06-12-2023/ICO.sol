// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


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
    
    //string array = ["projectname","description","logo","socialmedialink"]
    //uint array = ["presalerate","softcap","hardcap","minbuy","maxbuy","starttime","endtime","no of rounds"]
    //address array = ["icoowner","payoutcurrency","tokenaddress"]

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

    struct AllInfoList {
        ICOListing ICOlisting;
        ICOListingParameters ICOPara;
        AdminApproveType adminApproveType;
        STATUS status;
        FINALIZE_STATUS finalizeStatus;
    }
    AllInfoList public allInfoList;

    struct SoldInfo {
        uint256 soldToken;
        uint256 availableToken;
        uint256 amountRaised;
    }
    SoldInfo public soldInfo;

    struct Invest {
        uint256 totalAmount;
        uint256 totalToken;
        uint256 claimedToken;
        uint8 vestingRound;
    }
    mapping(address => Invest) public invest;
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
        address initialOwner,
        address ICOFactory,
        address _Admin,
        string[] memory _string,
        uint[] memory _uint,
        address[] memory _address
    ) payable Ownable(initialOwner){
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
        allInfoList = AllInfoList(
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
            IERC20Metadata(ICOPara.tokenAddress).name(),
            IERC20Metadata(ICOPara.tokenAddress).symbol(),
            IERC20Metadata(ICOPara.tokenAddress).decimals()
        );

        emit TokenInformation(IERC20Metadata(ICOPara.tokenAddress).name(),IERC20Metadata(ICOPara.tokenAddress).symbol(),IERC20Metadata(ICOPara.tokenAddress).decimals());

        soldInfo.availableToken =
            (ICOlisting.hardCap * ICOlisting.presaleRate) /
            10 ** IERC20Metadata(ICOPara.payoutCurrency).decimals();

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
            invest[_msgSender()].totalAmount != 0,
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
            ICOlisting.hardCap == soldInfo.amountRaised
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isSoftCapReach() public view returns (bool) {
        if (ICOlisting.softCap <= soldInfo.amountRaised) {
            return true;
        } else {
            return false;
        }
    }

    //-----------------------------------------------------------------------------------------------------------------------------

    //-------------------------------------Functions for Admin Approval------------------------------------------------------------
    function iCOApproval(bool decision) external {
        require(Admin == msg.sender, "Only admin can call this");
        require(
            adminApproveType == AdminApproveType.PENDING,
            "Already decided"
        );
        if (decision == true) {
            adminApproveType = AdminApproveType.ACCEPT;
            status = STATUS.ACTIVE;
            allInfoList.adminApproveType = adminApproveType;
            allInfoList.status = status;
            
            IERC20(ICOPara.tokenAddress).transferFrom(
                owner(),
                address(this),
                soldInfo.availableToken
            );
            FactoryICO(factoryContract).ICOStatusInfo(ICOId, 1);
            emit ICOApproval(ICOId,address(this),"Accepted");
        } else {
            adminApproveType = AdminApproveType.REJECT;
            allInfoList.adminApproveType = adminApproveType;
            
            emit ICOApproval(ICOId,address(this),"Rejected");
        }
        FactoryICO(factoryContract).ICOApprovalInfoCollect(ICOId, decision);
    }

    function fundApproval(bool decision) external {
        require(Admin == msg.sender, "Only admin can call this");
        require(
            finalizeStatus == FINALIZE_STATUS.PENDING,
            "ICO Owner did not created request yet"
        );
        if (decision == true) {
            finalizeStatus = FINALIZE_STATUS.ACCEPT;
            IERC20(ICOPara.payoutCurrency).transfer(
                owner(),
                soldInfo.amountRaised
            );
            IERC20(ICOPara.tokenAddress).transfer(
                owner(),
                soldInfo.availableToken
            );
            ICOlisting.endTime = block.timestamp;
            allInfoList.ICOlisting.endTime = block.timestamp;
            allInfoList.finalizeStatus = finalizeStatus;

            emit FundApproval(ICOId,address(this),"Accepted");
        } else {
            finalizeStatus = FINALIZE_STATUS.REJECT;
            IERC20(ICOPara.tokenAddress).transfer(
                owner(),
                (ICOlisting.hardCap * ICOlisting.presaleRate) /
                    10 ** IERC20Metadata(ICOPara.tokenAddress).decimals()
            );
            allInfoList.finalizeStatus = finalizeStatus;
            

            emit FundApproval(ICOId,address(this),"Rejected");
        }
        FactoryICO(factoryContract).ICOFundApprovalInfo(ICOId, decision);
    }

    //-----------------------------------------------------------------------------------------------------------------------------

    //-------------------------Functions only ICO Owner can call---------------------------------------------------

    function finalizedRequest() external onlyOwner {
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
        allInfoList.status = status;
        allInfoList.finalizeStatus = finalizeStatus;
        
        FactoryICO(factoryContract).ICOFundInfoReq(ICOId);
        FactoryICO(factoryContract).ICOStatusInfo(ICOId, 2);

        emit WithdrawalRequest(ICOId,address(this),"Request Generated");
    }

    function cancelPool() external onlyOwner {
        require(
            finalizeStatus == FINALIZE_STATUS.NOT_YET,
            "already asked for approval, Can't cancel"
        );
        require(status != STATUS.CANCELED, "Pool already cancelled");

        IERC20(ICOPara.tokenAddress).transfer(
            msg.sender,
            IERC20(ICOPara.tokenAddress).balanceOf(address(this))
        );
        status = STATUS.CANCELED;
        allInfoList.status = status;
        FactoryICO(factoryContract).ICOStatusInfo(ICOId, 3);

        emit PoolCancelled(ICOId,address(this),"CANCELED");
    }

    function updateTime(
        uint startingTime,
        uint endingTime
    ) external beforeApproval onlyOwner {
        ICOlisting.startTime = startingTime;
        ICOlisting.endTime = endingTime;

        allInfoList.ICOlisting.startTime = startingTime;
        allInfoList.ICOlisting.endTime = endingTime;
        FactoryICO(factoryContract).updateTimeInfo(
            ICOId,
            startingTime,
            endingTime
        );

        emit UpdateTime(ICOId,address(this),startingTime,endingTime);
    }

    function updatePresalerate(
        uint presaleRate
    ) external beforeApproval onlyOwner {
        ICOlisting.presaleRate = presaleRate;
        allInfoList.ICOlisting.presaleRate = presaleRate;
        soldInfo.availableToken =
            (ICOlisting.hardCap * ICOlisting.presaleRate) /
            10 ** IERC20Metadata(ICOPara.payoutCurrency).decimals();
        FactoryICO(factoryContract).updatePresaleInfo(ICOId, presaleRate);
        emit UpdatePresalrate(ICOId,address(this),presaleRate,soldInfo.availableToken);
    }

    function updateSoftHardCap(
        uint _softCap,
        uint _hardCap
    ) external beforeApproval onlyOwner {
        ICOlisting.softCap = _softCap;
        ICOlisting.hardCap = _hardCap;
        allInfoList.ICOlisting.softCap = _softCap;
        allInfoList.ICOlisting.hardCap = _hardCap;
        soldInfo.availableToken =
            (ICOlisting.hardCap * ICOlisting.presaleRate) /
            10 ** IERC20Metadata(ICOPara.payoutCurrency).decimals();
        FactoryICO(factoryContract).updateCapInfo(ICOId, _softCap, _hardCap);
        emit UpdateSoftHardCap(ICOId,address(this),_softCap,_hardCap,soldInfo.availableToken);
    }

    //----------------------------------------------------------------------------------------------------------------

    function buy(uint256 amount) external {
        require(
            adminApproveType == AdminApproveType.ACCEPT,
            "Admin did not approved yet"
        );
        require(status != STATUS.CANCELED, "This ICO is cancelled");
        require(isICOEnd() == false, "ICO has already end");
        require(block.timestamp >= ICOlisting.startTime, "Not started Yet");

        Invest storage invests = invest[_msgSender()];
        uint256 am = invests.totalAmount + amount;
        require(
            am >= ICOlisting.minBuy && am <= ICOlisting.maxBuy,
            "Please check amount range"
        );

        uint256 token = (ICOlisting.presaleRate * amount) /
            10 ** IERC20Metadata(ICOPara.payoutCurrency).decimals();
        require(soldInfo.availableToken >= token, "Not enough token for sale");

        if (invests.totalAmount == 0) {
            investors.push(msg.sender);
            FactoryICO(factoryContract).collectInvestorInfo(ICOId, msg.sender);
        }

        IERC20(ICOPara.payoutCurrency).transferFrom(
            _msgSender(),
            address(this),
            amount
        );

        invests.totalToken += token;
        invests.totalAmount += amount;
        soldInfo.availableToken -= token;
        soldInfo.soldToken += token;
        soldInfo.amountRaised += amount;

        emit Buy(_msgSender(),token);

    }

    function vestingClaim() external onlyInvestor {
        require(
            finalizeStatus == FINALIZE_STATUS.ACCEPT,
            "pool not approved yet"
        );

        Invest storage invests = invest[_msgSender()];

        uint256 time = ICOlisting.endTime +
            invests.vestingRound *
            vesting.vestingPeriodDays;

        if (invests.vestingRound == 0) {
            uint256 token = (invests.totalToken *
                vesting.presalePercent) / 10000;
            IERC20(ICOPara.tokenAddress).transfer(_msgSender(), token);
            invests.claimedToken += token;
            invests.vestingRound++;
        } else {
            require(
                invests.totalToken !=
                    invests.claimedToken,
                "You already claim tokens fully"
            );
            require(block.timestamp >= time, "wait for locking period");
            uint256 token = (invests.totalToken *
                vesting.eachCyclePercent) / 10000;
            IERC20(ICOPara.tokenAddress).transfer(_msgSender(), token);
            invests.claimedToken += token;
            invests.vestingRound++;
        }

        emit VestingClaim(_msgSender(),address(this),invests.vestingRound);
    }

    function claim() external onlyInvestor {
        if (
            status == STATUS.CANCELED ||
            finalizeStatus == FINALIZE_STATUS.REJECT ||
            (isSoftCapReach() == false && ICOlisting.endTime < block.timestamp)
        ) {
            IERC20(ICOPara.payoutCurrency).transfer(
                _msgSender(),
                invest[_msgSender()].totalAmount
            );

            emit ClaimInvestment(_msgSender(),address(this),invest[_msgSender()].totalAmount);
            invest[_msgSender()] = Invest(0, 0, 0, 0);
            
        } else {
            require(false, "Can't claim");
        }
    }

    function numInvestors() external view returns (uint) {
        return investors.length;
    }
}
