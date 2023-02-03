import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract WithWhitelist is Context, Ownable {
    mapping(address => bool) public whitelist;
    mapping(address => bool) public tokenYWhitelist;
    mapping(address => bool) public teamAddresses;

    function addToWhitelist(address[] memory addresses) public onlyOwner {
        for (uint8 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory addresses) public onlyOwner {
        for (uint8 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    function addToTokenYWhitelist(address[] memory addresses) public onlyOwner {
        for (uint8 i = 0; i < addresses.length; i++) {
            tokenYWhitelist[addresses[i]] = true;
        }
    }

    function removeFromTokenYWhitelist(address[] memory addresses) public onlyOwner {
        for (uint8 i = 0; i < addresses.length; i++) {
            tokenYWhitelist[addresses[i]] = false;
        }
    }

    function addToTeamAddresses(address[] memory addresses) public onlyOwner {
        for (uint8 i = 0; i < addresses.length; i++) {
            teamAddresses[addresses[i]] = true;
        }
    }

    function removeFromTeamAddresses(address[] memory addresses) public onlyOwner {
        for (uint8 i = 0; i < addresses.length; i++) {
            teamAddresses[addresses[i]] = false;
        }
    }
}
