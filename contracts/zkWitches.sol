// SPDX-License-Identifier: GPL-3.0
// ZK Witches

pragma solidity ^0.8.4;

interface IHCVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external view returns (bool);
}

interface INWVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[6] memory input
    ) external view returns (bool);
}

interface IVMVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[7] memory input
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

        address address0;
        address address1;
        address address2;
        address address3;

        PlayerState player0;
        PlayerState player1;
        PlayerState player2;
        PlayerState player3;
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

        int8 WitchAlive0;
        int8 WitchAlive1;
        int8 WitchAlive2;
        int8 WitchAlive3;
    }


    TotalGameState public tgs;

    address public hc_verifierAddr;
    address public vm_verifierAddr;
    address public nw_verifierAddr;

    function slotByAddress(address a) public view returns (int8) 
    {
        for (uint i=0; i<4; i++)
        {   
            if (getPlayerAddress(int8(uint8 (i))) == a) 
            {
                return int8(uint8 (i));
            }
        }
        return -1;
    }

    function getPlayer(int8 slot) public view returns (PlayerState memory) 
    {
        if (slot == 0) 
        {
            return tgs.player0;
        } 
        else if (slot == 1) 
        {
            return tgs.player1;
        } 
        else if (slot == 2) 
        {
            return tgs.player2;
        } 
        else if (slot == 3) 
        {
            return tgs.player3;
        } 
        else 
        {
            assert(false); 
            return tgs.player0; // Todo Stupid
        }
    }

    
    function setPlayer(int8 slot, PlayerState memory input) private 
    {
        if (slot == 0) 
        {
            tgs.player0 = input;
        } 
        else if (slot == 1) 
        {
            tgs.player1 = input;
        } 
        else if (slot == 2) 
        {
            tgs.player2 = input;
        } 
        else if (slot == 3) 
        {
            tgs.player3 = input;
        } 
        else 
        {
            assert(false);
        }
    }

    function getPlayerAddress(int8 slot) public view returns (address) 
    {
        if (slot == 0) 
        {
            return tgs.address0;
        } 
        else if (slot == 1) 
        {
            return tgs.address1;
        } 
        else if (slot == 2) 
        {
            return tgs.address2;
        } 
        else if (slot == 3) 
        {
            return tgs.address3;
        } 
        else 
        {
            assert(false);
            return tgs.address0; // Todo Stupid
        }
    }

    function setPlayerAddress(int8 slot, address input) private 
    {
        if (slot == 0) 
        {
            tgs.address0 = input;
        } 
        else if (slot == 1) 
        {
            tgs.address1 = input;
        } 
        else if (slot == 2) 
        {
            tgs.address2 = input;
        } 
        else if (slot == 3) 
        {
            tgs.address3 = input;
        } 
        else 
        {
            assert(false);
        }
    }

    function getWitchAlive(PlayerState memory inputPlayer, int8 witchType) public view returns (int8) 
    {
        if (witchType == 0) 
        {
            return inputPlayer.WitchAlive0;
        } 
        else if (witchType == 1) 
        {
            return inputPlayer.WitchAlive1;
        } 
        else if (witchType == 2) 
        {
            return inputPlayer.WitchAlive2;
        } 
        else if (witchType == 3) 
        {
            return inputPlayer.WitchAlive3;
        } 
        else 
        {
            assert(false);
        }
    }


    constructor(address hc_verifier, address vm_verifier, address nw_verifier) {
        hc_verifierAddr = hc_verifier;
        vm_verifierAddr = vm_verifier;
        nw_verifierAddr = nw_verifier;

        DEBUG_Reset();
    }

    // Debug Surface Area:

     function DEBUG_Reset() public 
     {
         tgs = TotalGameState( 
         {

         shared : SharedState
         ({
            stateEnum : GAME_STARTING,  
            playerSlotWaiting : 0,

            currentNumberOfPlayers : 0,

            // Active Accusation Info
            playerAccusing : 0,
            accusationWitchType : 0,

            // TODO Tracking time for kick and UI state
            previous_action_game_block : 0,
            current_block : 0,
            current_sequence_number : 0
         }),

         address0 : address(0),
         address1 : address(0),
         address2 : address(0),
         address3 : address(0),

         player0 : PlayerState({
             isAlive: false,
             handCommitment : 0,
             food : 0,
             lumber : 0,
             WitchAlive0 : 0,
             WitchAlive1 : 0,
             WitchAlive2 : 0,
             WitchAlive3 : 0
         }), 

        player1 : PlayerState({
             isAlive: false,
             handCommitment : 0,
             food : 0,
             lumber : 0,
             WitchAlive0 : 0,
             WitchAlive1 : 0,
             WitchAlive2 : 0,
             WitchAlive3 : 0
         }) ,

        player2 : PlayerState({
             isAlive: false,
             handCommitment : 0,
             food : 0,
             lumber : 0,
             WitchAlive0 : 0,
             WitchAlive1 : 0,
             WitchAlive2 : 0,
             WitchAlive3 : 0
         }) ,

        player3 : PlayerState({
             isAlive: false,
             handCommitment : 0,
             food : 0,
             lumber : 0,
             WitchAlive0 : 0,
             WitchAlive1 : 0,
             WitchAlive2 : 0,
             WitchAlive3 : 0
         }) 
         });
     }


     function DEBUG_SetGameState(TotalGameState memory inputTgs) public 
     {
         //
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
        require(slotByAddress(msg.sender) == INVALID_SLOT, "You are already in the game");
        require(tgs.shared.stateEnum == GAME_STARTING, "Game has already started");
        
        require(IHCVerifier(hc_verifierAddr).verifyProof(a, b, c, input), "Invalid handcommitment proof");

        tgs.shared.currentNumberOfPlayers++;
        int8 playerSlot = tgs.shared.currentNumberOfPlayers-1;
        setPlayerAddress(playerSlot, msg.sender);
        PlayerState memory newPlayer = PlayerState( 
        {   
            isAlive: true,
            handCommitment: input[0],

            food: 0,
            lumber: 0,

             WitchAlive0 : 1,
             WitchAlive1 : 1,
             WitchAlive2 : 1,
             WitchAlive3 : 1
        });
        setPlayer(playerSlot, newPlayer);

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

        require(getWitchAlive(player,0) == int8(uint8 (input[1])), "Witch 0 Alive does not match");
        require(getWitchAlive(player,1) == int8(uint8 (input[2])), "Witch 1 Alive does not match");
        require(getWitchAlive(player,2) == int8(uint8 (input[3])), "Witch 2 Alive does not match");
        require(getWitchAlive(player,3) == int8(uint8 (input[4])), "Witch 3 Alive does not match");

        require(IVMVerifier(vm_verifierAddr).verifyProof(a, b, c, input), "Invalid validmove proof");

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

        // TODO: We don't need WitchAlive for Accusation Responses because we check if the accusation is valid on the accuser's step.
        // It can be removed from the circuit and contract.

        require(getWitchAlive(player,0) == int8(uint8 (input[1])), "Witch 0 Alive does not match");
        require(getWitchAlive(player,1) == int8(uint8 (input[2])), "Witch 1 Alive does not match");
        require(getWitchAlive(player,2) == int8(uint8 (input[3])), "Witch 2 Alive does not match");
        require(getWitchAlive(player,3) == int8(uint8 (input[4])), "Witch 3 Alive does not match");

        require(tgs.shared.accusationWitchType == int8(uint8 (input[5])), "Responding to wrong accusation type");

        require(INWVerifier(nw_verifierAddr).verifyProof(a, b, c, input), "Invalid nowitch proof");

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
