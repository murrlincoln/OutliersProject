//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "hardhat/console.sol";

// TODO: Add the Axiom implementation to get the gas price
//       Determine how many x blocks will be in between bets (ideally 1 but axiom is expensive, so maybe 24hr)
//       Automatically move over user bets to the next block height if they are unclaimed after 18 hours


/**
 * A smart contract to allow users to speculate on the price of gas on the Ethereum network.
 */
contract GasSpeculator {

	// Mapping for block heights that are closed for betting and eligible for rewards
	mapping(uint256 => bool) public blockHeightClosed;

	// double mapping of user to range chosen at given block height
	mapping(address => mapping(uint256 => uint256)) public userRange;

	// double mapping of user deposit to given block height
	mapping(address => mapping(uint256 => uint256)) public userDeposit;

	// mapping of block height to gas price given by Axiom
	mapping(uint256 => uint256) public gasPrice;

	// mapping for total deposit per block height
	mapping(uint256 => uint256) public totalDeposit;
	
	// Event to emit gas price input by Axiom
	event GasPriceInput(uint256 indexed blockHeight, uint256 gasPrice);

	// Event to emit user range and deposit
	event UserRangeDeposit(address indexed user, uint256 indexed blockHeight, uint256 range, uint256 deposit);

	// Event upon user payout
	event UserPayout(address indexed user, uint256 indexed blockHeight, uint256 payout);

	// Owner of the contract
	address public immutable owner;

	// Axiom address
	address public axiomAddress;

	constructor(address _owner) {
		// Set the owner of the contract
		owner = _owner;
	}

	// Function that allows only the owner to change axiomAddress
	function setAxiomAddress(address _axiomAddress) public {
		require(msg.sender == owner, "Not the owner");
		axiomAddress = _axiomAddress;
	}



	function chooseRange(uint256 _range, uint256 blockHeight) public payable {
		// Check that block height is still open
		require(blockHeightClosed[blockHeight] == false, "Block height is closed for betting");	


		//User chooses a range from 0 to _range and sends a certain amount of ETH to the contract. These are stored in mappings
		userRange[msg.sender][blockHeight] = _range;
		userDeposit[msg.sender][blockHeight] = msg.value;
		// added to total deposit
		totalDeposit[blockHeight] += msg.value;

		emit UserRangeDeposit(msg.sender, blockHeight, _range, msg.value);
}

	// Function to allow only the axiomAddress to input a gas price at a given block height
	function inputGasPrice(uint256 _gasPrice, uint256 blockHeight) public {
		require(msg.sender == axiomAddress, "Not the Axiom address");
		// Close block height
		blockHeightClosed[blockHeight] = true;

		gasPrice[blockHeight] = _gasPrice;
		emit GasPriceInput(blockHeight, _gasPrice);
	}

	// Function to calculate the percentage change in gas price from the previous block height to the current block height
	function calculatePercentageChange(uint256 blockHeight) public view returns (uint256) {
		uint256 previousBlockHeight = blockHeight - 1;
		uint256 previousGasPrice = gasPrice[previousBlockHeight];
		uint256 currentGasPrice = gasPrice[blockHeight];
		uint256 percentageChange = ((currentGasPrice - previousGasPrice) / previousGasPrice) * 100;
		return percentageChange;
	}

	// When a user is right about the range of gas price changes, they are rewarded with a percentage of the total ETH in the contract based on their deposit
	// Wrong users get nothing
	function rewardUser(uint256 blockHeight) public {

		// Require that the block height is closed
		require(blockHeightClosed[blockHeight] == true, "Block height is still open for betting");

		uint256 percentageChange = calculatePercentageChange(blockHeight);
		if (percentageChange <= userRange[msg.sender][blockHeight]) {
			uint256 reward = (userDeposit[msg.sender][blockHeight] / totalDeposit[blockHeight]) * 100;
			(bool success, ) = msg.sender.call{ value: reward }("");
			require(success, "Failed to send Ether");

			emit UserPayout(msg.sender, blockHeight, reward);
		}
	}

	// Function to calculate unclaimed user winnings (if any)
	function calculateUnclaimedWinnings(uint256 blockHeight) public view returns (uint256) {
		// require that the block height is closed
		require(blockHeightClosed[blockHeight] == true, "Block height is still open for betting");

		uint256 percentageChange = calculatePercentageChange(blockHeight);
		if (percentageChange <= userRange[msg.sender][blockHeight]) {
			uint256 reward = (userDeposit[msg.sender][blockHeight] / totalDeposit[blockHeight]) * 100;
			return reward;
		}
		else {
			return 0;
		}
	}

	// Function to efficiently move all user's bets to the next block height if they are unclaimed after six hours
	// function moveBet(uint256 blockHeight) public {
	// }

}


/**
 * A smart contract that allows changing a state variable of the contract and tracking the changes
 * It also allows the owner to withdraw the Ether in the contract
 * @author BuidlGuidl
 */
// contract YourContract {
// 	// State Variables
// 	address public immutable owner;
// 	string public greeting = "Building Unstoppable Apps!!!";
// 	bool public premium = false;
// 	uint256 public totalCounter = 0;
// 	mapping(address => uint) public userGreetingCounter;

// 	// Events: a way to emit log statements from smart contract that can be listened to by external parties
// 	event GreetingChange(
// 		address indexed greetingSetter,
// 		string newGreeting,
// 		bool premium,
// 		uint256 value
// 	);

// 	// Constructor: Called once on contract deployment
// 	// Check packages/hardhat/deploy/00_deploy_your_contract.ts
// 	constructor(address _owner) {
// 		owner = _owner;
// 	}

// 	// Modifier: used to define a set of rules that must be met before or after a function is executed
// 	// Check the withdraw() function
// 	modifier isOwner() {
// 		// msg.sender: predefined variable that represents address of the account that called the current function
// 		require(msg.sender == owner, "Not the Owner");
// 		_;
// 	}

// 	/**
// 	 * Function that allows anyone to change the state variable "greeting" of the contract and increase the counters
// 	 *
// 	 * @param _newGreeting (string memory) - new greeting to save on the contract
// 	 */
// 	function setGreeting(string memory _newGreeting) public payable {
// 		// Print data to the hardhat chain console. Remove when deploying to a live network.
// 		console.log(
// 			"Setting new greeting '%s' from %s",
// 			_newGreeting,
// 			msg.sender
// 		);

// 		// Change state variables
// 		greeting = _newGreeting;
// 		totalCounter += 1;
// 		userGreetingCounter[msg.sender] += 1;

// 		// msg.value: built-in global variable that represents the amount of ether sent with the transaction
// 		if (msg.value > 0) {
// 			premium = true;
// 		} else {
// 			premium = false;
// 		}

// 		// emit: keyword used to trigger an event
// 		emit GreetingChange(msg.sender, _newGreeting, msg.value > 0, 0);
// 	}

// 	/**
// 	 * Function that allows the owner to withdraw all the Ether in the contract
// 	 * The function can only be called by the owner of the contract as defined by the isOwner modifier
// 	 */
// 	function withdraw() public isOwner {
// 		(bool success, ) = owner.call{ value: address(this).balance }("");
// 		require(success, "Failed to send Ether");
// 	}

// 	/**
// 	 * Function that allows the contract to receive ETH
// 	 */
// 	receive() external payable {}
// }
