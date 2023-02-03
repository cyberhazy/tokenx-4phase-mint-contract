pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./WithMintSupply.sol";
import "./WithToggleableSale.sol";
import "./WithWhitelist.sol";

contract TokenX is ERC721Enumerable,
    Ownable,
    Pausable,
    WithMintSupply,
    WithToggleableSale,
    WithWhitelist,
    VRFConsumerBase
{
    struct _MintSupply {
        uint256 maxSupply;
        uint256 remainingMints;
        uint256 mintPrice;
    }

    uint256 public constant MAX_PRESALE_MINTS = 3;
    uint256 public constant MAX_BATCH_MINTS = 10;

    address public immutable tokenYAddress;

    _MintSupply public maticSupply;
    _MintSupply public tokenYSupply;
    _MintSupply public teamSupply;

    mapping(address => bool) public teamClaimed;
    /** Track whether an address has minted with PD already */
    mapping(address => bool) public tokenYMinted;
    /** Track number of presale mints per address */
    mapping(address => uint256) public presaleMintCount;

    bytes32 internal _linkKeyHash;
    uint256 internal _linkFee;

    /** Link mint requests -> recipients */
    mapping(bytes32 => address) private _linkRequests;

    /** Event on request randomness call */
    event RequestMint(bytes32 indexed requestId);
    /** Event on fulfill randomness call */
    event FulfillMint(bytes32 indexed requestId, uint256 token);

    constructor(
        uint256 maticMintPrice,
        uint256 maticMaxSupply,
        uint256 pdMintPrice,
        uint256 pdMaxSupply,
        uint256 teamMaxSupply,
        uint256 initPreSaleStart,
        uint256 initPublicSaleStart,
        address initTokenYAddress,
        address vrfCoordinator,
        address linkToken,
        bytes32 keyHash
    )
        ERC721("TokenX", "TOKENX")
        VRFConsumerBase(vrfCoordinator, linkToken)
        WithToggleableSale(initPreSaleStart, initPublicSaleStart)
        WithMintSupply(maticMaxSupply + pdMaxSupply + teamMaxSupply)
    {
        maticSupply = _MintSupply(maticMaxSupply, maticMaxSupply, maticMintPrice);
        tokenYSupply = _MintSupply(pdMaxSupply, pdMaxSupply, pdMintPrice);
        teamSupply = _MintSupply(teamMaxSupply, teamMaxSupply, 0);
        tokenYAddress = initTokenYAddress;

        _linkKeyHash = keyHash;
        _linkFee = 0.0001 * 10**18;
    }

    function mintPublic(
        uint256 tokenCount
    )
        public
        payable
        whenMintInitialized
        whenPublicSaleActive
        whenNotPaused
    {
        _mintTokens(tokenCount);
    }

    function mintPresale(
        uint256 tokenCount
    )
        public
        payable
        whenMintInitialized
        whenPreSaleActive
        whenNotPaused
    {
        require(
            presaleMintCount[msg.sender] + tokenCount <= MAX_PRESALE_MINTS,
            "Cannot mint more than 3 tokens during pre-sale"
        );
        require(whitelist[msg.sender], "Sender is not whitelisted to mint in pre-sale");
        presaleMintCount[msg.sender] += tokenCount;
        _mintTokens(tokenCount);
    }

    function mintTokenY()
        public
        whenMintInitialized
        whenPreSaleActive
        whenNotPaused
    {
        require(!tokenYMinted[msg.sender], "Sender already minted a token with TokenY");
        require(tokenWhitelist[msg.sender], "Sender is not whitelisted to mint with TokenY");
        tokenYMinted[msg.sender] = true;

        IERC20 tokenYContract = IERC20(tokenYAddress);
        uint256 balance = tokenYContract.balanceOf(address(msg.sender));
        require(balance >= tokenYSupply.mintPrice, "Insufficient TokenY available");
        tokenYContract.transferFrom(msg.sender, address(this), tokenYSupply.mintPrice);

        _mintRandomToken(msg.sender, tokenYSupply);
    }

    function mintTeam()
        public
        whenMintInitialized
        whenNotPaused
    {
        require(teamSupply.remainingMints > 0, "Token count exceeds remaining mint supply");
        require(!teamClaimed[msg.sender], "Team token already claimed");
        require(teamAddresses[msg.sender], "Sender is not in the team member list");

        teamClaimed[msg.sender] = true;
        _mintRandomToken(msg.sender, teamSupply);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId)
        external
        virtual
        whenNotPaused
    {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function withdraw(address target, uint256 amount) public onlyOwner {
        payable(target).transfer(amount);
    }

    function withdrawErc20(
        address tokenAddress,
        address target,
        uint256 amount
    ) public onlyOwner {
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transfer(target, amount);
    }

    /**
     * Updates LINK fee for VRF usage
     */
    function updateLinkFee(uint256 newFee) public onlyOwner {
        _linkFee = newFee;
    }

    /**
     * Toggles pause on/off
     */
    function togglePause(bool toggle) public onlyOwner {
        if (toggle) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * Emergency manual fulfillment if fulfillRandomness fails for some reason.
     * Should only be used with real VRF randomness value, if it is recoverable.
     */
    function emergencyFulfill(bytes32 requestId, uint256 randomness)
        external
        whenMintInitialized
        onlyOwner
    {
        require(
            _linkRequests[requestId] != address(0),
            "Request must be present!"
        );
        fulfillRandomness(requestId, randomness);
    }

    function _mintTokens(uint256 tokenCount) internal {
        require(tokenCount > 0, "Cannot mint 0 tokens");
        require(tokenCount <= 10, "Cannot mint more than 10 tokens");
        require(msg.value >= maticSupply.mintPrice * tokenCount, "Insufficient funds provided");
        require(tokenCount <= maticSupply.remainingMints, "Token count exceeds remaining mint supply");

        for (uint256 i = 0; i < tokenCount; ++i) {
            _mintRandomToken(msg.sender, maticSupply);
        }
    }

    /**
     * Fulfills randomness using random seed.
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        address recipient = _linkRequests[requestId];

        if (recipient != address(0) && _mintIndices.length > 0) {
            // Pick random entry in _mintIndices state, retrieve & remove token ID
            uint256 randomId = randomness % _mintIndices.length;
            uint256 tokenId = _removeMintId(randomId);

            // Mint & remove request to mark as satisfied
            _safeMint(recipient, tokenId);
            delete _linkRequests[requestId];
            emit FulfillMint(requestId, tokenId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        // TODO: replace with base URI once we have it
        return "ipfs://?/";
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "Cannot transfer tokens while contract is paused.");
    }

    /**
     * Initiates a random token mint to the target recipient
     */
    function _mintRandomToken(address recipient, _MintSupply storage supply) private {
        require(supply.remainingMints > 0, "No more mints remaining!");
        require(
            LINK.balanceOf(address(this)) >= _linkFee,
            "Insufficient LINK. Dev should fix this soon!"
        );

        supply.remainingMints--;
        _requestRandomMint(recipient);
    }

    /**
     * Requests a random mint to target recipient.
     * Does **not** check or change mints remaining state!
     */
    function _requestRandomMint(address recipient) private {
        // VRF mint request. Mint callback expected in fulfillRandomness
        bytes32 requestId = requestRandomness(_linkKeyHash, _linkFee);
        _linkRequests[requestId] = recipient;
        emit RequestMint(requestId);
    }
}
