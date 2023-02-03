import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract WithMintSupply is Context, Ownable {
    uint256 public immutable maxSupply;

    uint16[] internal _mintIndices; // Indices of tokens that are yet to be minted
    bool internal _mintInitialized; // Keep track whether the mint indices array is initialized

    /**
     * @dev throws if minting is not initialized fully
     */
    modifier whenMintInitialized() {
        require(_mintInitialized, "Minting not yet initialized");
        _;
    }

    constructor(
        uint256 initMaxSupply
    ) {
        maxSupply = initMaxSupply;
    }

    /**
     * Initializes mint indices array. Used to split gas costs into a separate
     * function (as it is too expensive for the constructor)
     */
    function initializeMint(uint16 startId, uint16 endId) public onlyOwner {
        require(startId <= endId, "Start ID must not exceed endId!");
        require(endId < maxSupply, "End ID cannot exceed max supply!");
        require(startId >= _mintIndices.length, "Cannot re-add the same IDs!");
        require(
            (_mintIndices.length == 0 && startId == 0) || // First add
                (_mintIndices.length != 0 &&
                    startId == _mintIndices[_mintIndices.length - 1] + 1),
            "Can only add new mint ID in sequence!"
        );
        require(!_mintInitialized, "Minting already initialized!");

        for (uint16 i = startId; i <= endId; ++i) {
            _mintIndices.push(i);
        }

        if (_mintIndices.length == maxSupply) {
            _mintInitialized = true;
        }
    }

    /**
     * Removes the value specified at **index** from '_mintIndices'.
     * Shrinks the array.
     */
    function _removeMintId(uint256 index) internal returns (uint256) {
        // Swap last value & now-removed mint index position in the array
        uint256 lastIndex = _mintIndices.length - 1;
        uint16 indexValue = _mintIndices[index];
        _mintIndices[index] = _mintIndices[lastIndex];

        // Shrink array (removes lastIndex value)
        _mintIndices.pop();

        return indexValue;
    }
}
