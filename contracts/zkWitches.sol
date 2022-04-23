// SPDX-License-Identifier: GPL-3.0
// ZK Witches

pragma solidity ^0.8.4;

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
    int8 constant FOOD = 0;
    int8 constant LUMBER = 1;
    int8 constant BRIGAND = 2;
    int8 constant INQUISITOR = 3;

    // GameState Types
    int8 constant GAME_STARTING = 0;
    int8 constant WAITING_FOR_PLAYER_TURN = 1;
    int8 constant WAITING_FOR_PLAYER_ACCUSATION_RESPONSE = 2;
    int8 constant GAME_OVER = 3;

    int8 constant INVALID_SLOT = -1;

    struct TotalGameState 
    {
        SharedState shared;

        address[4] playerAddresses;
        PlayerState[4] players;
    }

    struct SharedState 
    {
        int8 stateEnum;        
        int8 playerSlotWaiting;

        int8 currentNumberOfPlayers;

        // Active Accusation Info
        int8 playerAccusing;
        int8 accusationWitchType;

        // TODO Tracking time for kick and UI state
        uint previous_action_game_block;
        uint current_block;
        uint current_sequence_number;
    }

    struct PlayerState 
    {
        bool isAlive;
        uint handCommitment;

        int8 food;
        int8 lumber;

        int8[4] WitchAlive;
    }

    TotalGameState tgs;

    address public hc_verifierAddr;
    address public vm_verifierAddr;
    address public nw_verifierAddr;

    function slotByAddress(address a) public view returns (int8) 
    {
        for (uint i=0; i<4; i++)
        {   
            if (tgs.playerAddresses[i] == a) 
            {
                return int8(uint8 (i));
            }
        }
        return -1;
    }

    function getPlayer(int8 slot) public view returns (PlayerState memory) 
    {
        return tgs.players[uint(uint8 (slot))];
    }

    constructor(address hc_verifier, address vm_verifier, address nw_verifier) {
        hc_verifierAddr = hc_verifier;
        vm_verifierAddr = vm_verifier;
        nw_verifierAddr = nw_verifier;

        // DEBUG_Reset();
    }

    // Debug Surface Area:

    // function DEBUG_SetGameState(TotalGameState memory inputTgs) public 
    // {
    //     tgs = inputTgs;
    // }

    // function DEBUG_Reset() public
    // {
    //     // TODO Initialize
    // }

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
        require(slotByAddress(msg.sender) == INVALID_SLOT, "You are already in the game");
        require(tgs.shared.stateEnum == GAME_STARTING, "Game has already started");
        
        // TODO: proof();

        tgs.shared.currentNumberOfPlayers++;
        int8 playerSlot = tgs.shared.currentNumberOfPlayers-1;
        tgs.playerAddresses[uint(uint8 (playerSlot))] = msg.sender;
        PlayerState memory newPlayer = PlayerState( 
        {   
            isAlive: true,
            handCommitment: input[0],

            food: 0,
            lumber: 0,

            WitchAlive: [int8(1),1,1,1]
        });
        tgs.players[uint(uint8 (playerSlot))] = newPlayer;

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
        require(slotByAddress(msg.sender) != INVALID_SLOT, "Address is Not a valid Player");        
        
        int8 slot = slotByAddress(msg.sender);

        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_TURN, "Not waiting for a player action");
        require(tgs.shared.playerSlotWaiting == slot, "Not your turn.");

        // Check proof inputs match contract state

        PlayerState memory player = getPlayer(slot);

        require(player.handCommitment == input[0], "Hand commitments do not match");

        require(player.WitchAlive[0] == int8(uint8 (input[1])), "Witch 0 Alive does not match");
        require(player.WitchAlive[1] == int8(uint8 (input[2])), "Witch 1 Alive does not match");
        require(player.WitchAlive[2] == int8(uint8 (input[3])), "Witch 2 Alive does not match");
        require(player.WitchAlive[3] == int8(uint8 (input[4])), "Witch 3 Alive does not match");

        //TODO: proof();

        ActionCore(int8(uint8 (input[5])), int8(uint8 (actionTarget)), int8(uint8 (input[6])), int8(uint8 (witchType)));
    }

    function ActionNoProof(uint actionType, uint actionTarget, uint witchType) public 
    {
        require(slotByAddress(msg.sender) != INVALID_SLOT, "Address is Not a valid Player");        
        
        int8 slot = slotByAddress(msg.sender);

        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_TURN, "Not waiting for a player action");
        require(tgs.shared.playerSlotWaiting == slot, "Not your turn.");

        ActionCore(int8(uint8 (actionType)), int8(uint8 ( actionTarget)), int8(uint8 (witchType)), 0);
    }

    function ActionCore(int8 actionType, int8 actionTarget, int8 witchType, int8 actionLevel) private
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
            require(slotByAddress(msg.sender) != actionTarget, "Cannot target yourself");
            require(actionTarget >=0 && actionTarget <= 3, "Must target a existing player");
            require(getPlayer(actionTarget).isAlive, "Cannot target a dead player");

            // TODO Require enough resources
            // TODO Action
            // TODO Advance Game State
        } 
        else if (actionType == INQUISITOR) 
        {
            require(slotByAddress(msg.sender) != actionTarget, "Cannot target yourself");
            require(actionTarget >=0 && actionTarget <= 3, "Must target a existing player");
            require(getPlayer(actionTarget).isAlive, "Cannot target a dead player");

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
        require(slotByAddress(msg.sender) != INVALID_SLOT, "Address is Not a valid Player");        
        
        int8 slot = slotByAddress(msg.sender);

        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_ACCUSATION_RESPONSE, "Not waiting for a player response to accusation");
        require(tgs.shared.playerSlotWaiting == slot, "Not your response.");

        // Check proof inputs match contract state

        PlayerState memory player = getPlayer(slot);

        require(player.handCommitment == input[0], "Hand commitments do not match");

        require(player.WitchAlive[0] == int8(uint8 (input[1])), "Witch 0 Alive does not match");
        require(player.WitchAlive[1] == int8(uint8 (input[2])), "Witch 1 Alive does not match");
        require(player.WitchAlive[2] == int8(uint8 (input[3])), "Witch 2 Alive does not match");
        require(player.WitchAlive[3] == int8(uint8 (input[4])), "Witch 3 Alive does not match");

        require(tgs.shared.accusationWitchType == int8(uint8 (input[5])), "Responding to wrong accusation type");

        // TODO Proof();
        // TODO Apply Penalties
        // TODO Advance Game State
    }

    function RespondAccusation_YesWitch() public
    {
        require(slotByAddress(msg.sender) != INVALID_SLOT, "Address is Not a valid Player");        
        
        int8 slot = slotByAddress(msg.sender);

        RespondAccusation_YesWitch_Inner(slot);
    }

    function RespondAccusation_YesWitch_Inner(int8 slot) private
    {
        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_ACCUSATION_RESPONSE, "Not waiting for a player response to accusation");
        require(tgs.shared.playerSlotWaiting == slot, "Not your response.");

        // TODO Apply Penalties
        // TODO Advance Game State
    }

    // Game Loss and Surrender

    function Surrender() public 
    {
        require(slotByAddress(msg.sender) != INVALID_SLOT, "Address is Not a valid Player");        
        
        int8 slot = slotByAddress(msg.sender);

        ForceLoss(slot);
    }

    function KickCurrentPlayer() public
    {
        // TODO Check if player has been waiting too long
        int8 slot = -1;
        if (false) 
        {
            ForceLoss(slot);
        }
    }

    function ForceLoss(int8 slot) private
    {
        require(tgs.shared.stateEnum != GAME_STARTING, "A Player cannot lose before the game starts."); // TODO fix - just need to write some logic for this case
        require(tgs.shared.stateEnum != GAME_OVER, "The game is already over.");
        require(getPlayer(slot).isAlive, "Player is already dead.");

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

    // Game State Advancement




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
