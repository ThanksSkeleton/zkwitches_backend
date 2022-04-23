// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Base64.sol";

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[65] memory input
    ) external view returns (bool);
}

contract zkWitches {

    // Action Types
    uint constant FOOD = 0;
    uint constant LUMBER = 1;
    uint constant BRIGAND = 2;
    uint constant INQUISITOR = 3;

    // GameState Types
    uint constant GAME_STARTING = 0;
    uint constant WAITING_FOR_PLAYER_TURN = 1;
    uint constant WAITING_FOR_PLAYER_ACCUSATION_RESPONSE = 2;
    uint constant GAME_OVER = 3;

    struct TotalGameState 
    {
        SharedState shared;
        // not an index! an index+1 (1,2,3,4) (this allows 0 to be "not found")
        mapping (address => uint) slotByAddress;
        // slot to player
        mapping (uint => PlayerState) player;
    }

    struct SharedState 
    {
        uint stateEnum;        
        uint playerSlotWaiting;

        uint currentNumberOfPlayers;

        // Active Accusation Info
        uint playerAccusing;
        uint accusationWitchType;

        uint previous_action_game_block;
        uint current_block;
        uint current_sequence_number;
    }

    struct PlayerState 
    {
        uint slot;
        address playerAddress;
        bool isAlive;
        uint handCommitment;

        uint food;
        uint lumber;

        uint[4] WitchAlive;
    }

    TotalGameState tgs;

    address public hc_verifierAddr;
    address public vm_verifierAddr;
    address public nw_verifierAddr;

    // using Counters for Counters.Counter;
    // Counters.Counter private _tokenIds;

    constructor(address hc_verifier, address vm_verifier, address nw_verifier) {
        hc_verifierAddr = hc_verifier;
        vm_verifierAddr = vm_verifier;
        nw_verifierAddr = nw_verifier;

        DEBUG_Reset();
    }

    // Debug Surface Area:

    function DEBUG_SetGameState(TotalGameState inputTgs) public 
    {
        tgs = inputTgs;
    }

    function DEBUG_Reset() public
    {
        // TODO Initialize
    }

    // Joining The game
    // TODO Payable + all that

    function JoinGame(
        // proof             
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        // proof output                  
        // signal output Hash;
        uint[1] memory input
    ) public
    {
        require(!tgs.slotByAddress[msg.sender], "You are already in the game");
        require(tgs.shared.stateEnum == GAME_STARTING, "Game has already started");
        
        // TODO: proof();

        tgs.sharedState.currentNumberOfPlayers++;
        let playerSlot = tgs.sharedState.currentNumberOfPlayers;
        tgs.slotByAddress[msg.sender] = playerSlot;
        let newPlayer = PlayerState 
        {   
            slot: playerSlot,
            playerAddress: msg.sender,
            isAlive: true,
            handCommitment: input[0],

            food: 0,
            lumber: 0,

            WitchAlive: [1,1,1,1]
        }
        tgs.player[playerSlot] = newPlayer;

        // TODO: Advance game state if full
    }

    // Game Action Stuff

    function ActionWithProof(
        // required but not part of the proof
        // ignored if not relevant to action
        uint actionTarget,
        uint witchType,
        // proof             
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        // proof publics                  
        // signal input ExpectedHash;
        // signal input WitchAlive[4]; 
        // signal input citizenType;
        // signal input requiredCitizenCount;
        uint[7] memory input
    ) public 
    {
        require(tgs.slotByAddress[msg.sender], "Address is Not a valid Player");        
        
        let slot = tgs.slotByAddress[msg.sender];

        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_TURN, "Not waiting for a player action");
        require(tgs.shared.playerSlotWaiting == slot, "Not your turn.");

        // Check proof inputs match contract state

        require(tgs.player[slot].handCommitment == input[0], "Hand commitments do not match");

        require(tgs.player[slot].WitchAlive[0] == input[1], "Witch 0 Alive does not match");
        require(tgs.player[slot].WitchAlive[1] == input[2], "Witch 1 Alive does not match");
        require(tgs.player[slot].WitchAlive[2] == input[3], "Witch 2 Alive does not match");
        require(tgs.player[slot].WitchAlive[3] == input[4], "Witch 3 Alive does not match");

        //TODO: proof();

        ActionCore(input[5], actionTarget, input[6]);
    }

    public ActionNoProof(uint actionType, uint actionTarget, uint witchType) public 
    {
        require(tgs.slotByAddress[msg.sender], "Address is Not a valid Player");        
        
        let slot = tgs.slotByAddress[msg.sender];

        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_TURN, "Not waiting for a player action");
        require(tgs.shared.playerSlotWaiting == slot, "Not your turn.");

        ActionCore(actionType, actionTarget, witchType, 0);
    }

    function ActionCore(uint actionType, uint actionTarget, uint witchType, uint actionLevel) private
    {
        require(actionType >= 0 && actionType <= 3, "Unknown action");
        if (actionType == FOOD)
        {
            // TODO Action
            // TODO Advance Game State
        } 
        else if (actionType == LUMBER) 
        {
            // TODO Action
            // TODO Advance Game State
        } 
        else if (actionType == BRIGAND)
        {
            require(tgs.slotByAddress[msg.sender] != actionTarget, "Cannot target yourself");
            require(tgs.player[actionTarget].slot, "Must target a existing player");
            require(tgs.player[actionTarget].alive, "Cannot target a dead player");

            // TODO Require enough resources
            // TODO Action
            // TODO Advance Game State
        } 
        else if (actionType == INQUISITOR) 
        {
            require(tgs.slotByAddress[msg.sender] != actionTarget, "Cannot target yourself");
            require(tgs.player[actionTarget].slot, "Must target a existing player");
            require(tgs.player[actionTarget].alive, "Cannot target a dead player");

            // TODO Require enough resources
            // TODO Action
            // TODO Advance Game State to WAITING_FOR_PLAYER_ACCUSATION_RESPONSE
        }
    }

    // Witch Accusations 

    function RespondAccusation_NoWitch (
        // proof             
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        // proof publics    
        // signal input ExpectedHash;
        // signal input WitchAlive[4]; 
        // signal input citizenType;
        uint[6] memory input
    ) public
    {
        require(tgs.slotByAddress[msg.sender], "Address is Not a valid Player");        
        
        let slot = tgs.slotByAddress[msg.sender];

        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_ACCUSATION_RESPONSE, "Not waiting for a player response to accusation");
        require(tgs.shared.playerSlotWaiting == slot, "Not your response.");

        // Check proof inputs match contract state

        require(tgs.player[slot].handCommitment == input[0], "Hand commitments do not match");

        require(tgs.player[slot].WitchAlive[0] == input[1], "Witch 0 Alive does not match");
        require(tgs.player[slot].WitchAlive[1] == input[2], "Witch 1 Alive does not match");
        require(tgs.player[slot].WitchAlive[2] == input[3], "Witch 2 Alive does not match");
        require(tgs.player[slot].WitchAlive[3] == input[4], "Witch 3 Alive does not match");

        require(tgs.shared.accusationWitchType == input[5], "Responding to wrong accusation type")

        // TODO Proof();
        // TODO Apply Penalties
        // TODO Advance Game State
    }

    function RespondAccusation_YesWitch() public
    {
        require(tgs.slotByAddress[msg.sender], "Address is Not a valid Player");        
        
        let slot = tgs.slotByAddress[msg.sender];

        RespondAccusation_YesWitch_Inner(slot);
    }

    function RespondAccusation_YesWitch_Inner(uint slot) private
    {
        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_ACCUSATION_RESPONSE, "Not waiting for a player response to accusation");
        require(tgs.shared.playerSlotWaiting == slot, "Not your response.");

        // TODO Apply Penalties
        // TODO Advance Game State
    }

    // Game Loss and Surrender

    function Surrender() public 
    {
        require(tgs.slotByAddress[msg.sender], "Address is Not a valid Player");        
        
        let slot = tgs.slotByAddress[msg.sender];

        ForceLoss(slot);
    }

    function KickCurrentPlayer() public
    {
        // TODO Check if player has been waiting too long
        let slot = -1;
        if (false) 
        {
            ForceLoss(slot);
        }
    }

    function ForceLoss(uint slot) private
    {
        require(tgs.shared.stateEnum != GAME_STARTING, "A Player cannot lose before the game starts."); // TODO fix - just need to write some logic for this case
        require(tgs.shared.stateEnum != GAME_OVER, "The game is already over.");
        require(tgs.player[slot].isAlive, "Player is already dead.");

        // If the player is active we need to advance the game and THEN kick the player

        if (tgs.shared.stateEnum == WAITING_FOR_PLAYER_TURN && tgs.shared.playerSlotWaiting == slot) 
        {
            // TODO Special "Pass" Action
            // TODO Advance Game State
        } 
        else if (tgs.shared.stateEnum == WAITING_FOR_PLAYER_ACCUSATION_RESPONSE && tgs.shared.playerSlotWaiting == slot) 
        {
            RespondAccusation_YesWitch_Inner(slot);
        }

        // TODO Mark Surrender
        // TODO Check Victory
    }



    // /**
    //  * @dev mint a photo given the proof and the tokenURI
    //  */
    // function mint(
    //     string calldata name,
    //     string calldata description,
    //     string calldata image,
    //     uint256[2][16] calldata a,
    //     uint256[2][2][16] calldata b,
    //     uint256[2][16] calldata c,
    //     uint256[65][16] calldata input
    // ) public returns (uint256) {
    //     bytes32 _hash = generateHash(input);

    //     require(!hashExists[_hash], "Image already exists");

    //     for (uint256 i = 0; i < 16; i++) {
    //         uint256[2] memory _a = [a[i][0], a[i][1]];
    //         uint256[2][2] memory _b = [
    //             [b[i][0][0], b[i][0][1]],
    //             [b[i][1][0], b[i][1][1]]
    //         ];
    //         uint256[2] memory _c = [c[i][0], c[i][1]];
    //         uint256[65] memory _input;
    //         for (uint256 j = 0; j < 65; j++) {
    //             _input[j] = input[i][j];
    //         }
    //         require(
    //             IVerifier(verifierAddr).verifyProof(_a, _b, _c, _input),
    //             "Invalid proof"
    //         );
    //     }

    //     _tokenIds.increment();

    //     uint256 newtokenId = _tokenIds.current();
    //     _mint(msg.sender, newtokenId);
    //     _setTokenURI(newtokenId, generateTokenURI(name, description, image));
    //     data[newtokenId] = input;
    //     hashExists[_hash] = true;
    //     return newtokenId;
    // }

    // /**
    //  * @dev retrieve on chain data by NFT id
    //  * @param tokenId token id
    //  */
    // function getData(uint256 tokenId)
    //     public
    //     view
    //     returns (uint256[65][16] memory)
    // {
    //     require(_exists(tokenId), "Nonexistent token");
    //     return data[tokenId];
    // }
}
