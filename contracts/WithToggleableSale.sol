import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract WithToggleableSale is Context, Ownable {
    uint256 public preSaleStartTimestamp;
    uint256 public publicSaleStartTimestamp;
    bool public isSaleActive;

    constructor(
        uint256 initPreSaleStart,
        uint256 initPublicSaleStart
    ) {
        preSaleStartTimestamp = initPreSaleStart;
        publicSaleStartTimestamp = initPublicSaleStart;
        isSaleActive = true;
    }

    /**
     * Toggle sale on/off
     */
    function toggleSale(bool toggle) public onlyOwner {
        isSaleActive = toggle;
    }


    /**
     * Sets a new date for the public sale
     */
    function setSaleStart(uint256 newSaleStart) public onlyOwner {
        require(newSaleStart >= preSaleStartTimestamp, "Public sale should start after pre-sale");
        publicSaleStartTimestamp = newSaleStart;
    }


    /**
     * Sets a new date for the pre-sale sale
     */
    function setPreSaleStart(uint256 newSaleStart) public onlyOwner {
        require(newSaleStart <= publicSaleStartTimestamp, "Public sale should start after pre-sale");
        preSaleStartTimestamp = newSaleStart;
    }

    /**
     * @dev Throws if sale not active
     */
    modifier whenPublicSaleActive() {
        require(
            block.timestamp >= publicSaleStartTimestamp,
            "Public sale of the token is not yet active"
        );
        require(isSaleActive, "Sale of the token is disabled");
        _;
    }

    /**
     * @dev Throws if presale not active
     */
    modifier whenPreSaleActive() {
        require(
            block.timestamp >= preSaleStartTimestamp,
            "Pre-sale of the token is not yet active"
        );
        require(isSaleActive, "Sale of the token is disabled");
        _;
    }
}
