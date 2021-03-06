pragma solidity ^0.4.18;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) pure internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a < b ? a : b;
  }
}

 /**
 * ERC223 token by Dexaran
 *
 * https://github.com/Dexaran/ERC223-token-standard
 */


contract ERC20 {
    function totalSupply()  public constant returns (uint256 supply);
    function balanceOf( address who )  public constant returns (uint256 value);
    function allowance( address owner, address spender )  public constant returns (uint256 _allowance);

    function transfer( address to, uint256 value)  public returns (bool ok);
    function transferFrom( address from, address to, uint256 value)  public returns (bool ok);
    function approve( address spender, uint256 value )  public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
}
 
 contract ContractReceiver {
     function tokenFallback(address _sender,
                       uint256 _value,
                       bytes _extraData) public returns (bool);
 }
 

contract Proposal is ContractReceiver {
    using SafeMath for uint256;

    event TokenFallback(address _sender,
                       uint256 _value,
                       bytes _extraData);

    Vote[] public votes;
    uint256 public goal;
    uint256 public progress;
    string public description;

    address public token;
    uint public periodInMinutes;
    uint public votingDeadline;
    string public status;

    struct Vote {
        address voter;
        uint256 amount;
    }

    /**
     * Add Proposal
     *
     * Propose to send KATIN Token for voting
     *
     * @param _token address of KATIN Coin
     * @param _goal Amount of KATIN Coin goal
     * @param _description Description of proposal
     * @param _periodInMinutes Goal deadline in minutes
     */
    function Proposal(
        address _token,
        uint256 _goal,
        string _description,
        uint _periodInMinutes
    )
        public
    {
        token = _token;
        goal = _goal;
        description = _description;
        periodInMinutes = _periodInMinutes;
        votingDeadline = now + _periodInMinutes * 1 minutes;
        status = "Voting";
    }

    // Need action: check to only accept KATIN Token
    function tokenFallback(address _sender,
                       uint256 _value,
                       bytes _extraData) public returns (bool) {
        require(keccak256(status) == keccak256("Voting"));
        require(token == msg.sender);
        require(now <= votingDeadline);
        require(goal >= progress.add(_value));

        uint voteID = votes.length++;
        votes[voteID] = Vote({voter: _sender, amount: _value});

        progress = progress.add(_value);

        if (goal == progress) {
            status = "Success";
        }

        TokenFallback(_sender, _value, _extraData);
    }

    function verify() public {
        // Passed deadline
        if (now > votingDeadline) {
            if(progress < goal) {
                status = "Failed";
                // returnTokens();
            } else {
                status = "Success";
            }
        }
    }

    function returnTokens() public {
        ERC20 katinCoin = ERC20(token);
        for (uint i = 0; i <  votes.length; ++i) {
            Vote storage v = votes[i];
            
            
            require(katinCoin.transfer( v.voter, v.amount));
        }
    }

    // function returnToken2() public {
    //     address  myAddress = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;

    //     ERC20 t = ERC20(token);
    //     // send to caller
    //     require(t.transfer(myAddress, 1));
    // }

    function voteBy(address _voter) public view returns (uint256) {
        uint256 amount = 0;
        for (uint i = 0; i <  votes.length; ++i) {
            Vote storage v = votes[i];
            if (v.voter == _voter) {
                amount = amount.add(v.amount);
            }
        }
        return amount;
    }
}
