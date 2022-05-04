// SPDX-License-Identifier: GPL-3.0
// ZK Witches
import "@openzeppelin/contracts/access/Ownable.sol";

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
        uint256[2] memory input
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

contract zkWitches is Ownable {

    // Action Types
    uint8 constant FOOD = 0;
    uint8 constant LUMBER = 1;
    uint8 constant BRIGAND = 2;
    uint8 constant INQUISITOR = 3;

    // GameState Types
    uint8 constant GAME_STARTING = 0;
    uint8 constant WAITING_FOR_PLAYER_TURN = 1;
    uint8 constant WAITING_FOR_PLAYER_ACCUSATION_RESPONSE = 2;

    uint8 constant INVALID_SLOT = 5;

    uint8 constant STARTING_FOOD = 2;
    uint8 constant STARTING_LUMBER = 2;

    struct TotalGameState 
    {
        SharedState shared;

        address[4] addresses;
        PlayerState[4] players;
    }

    struct SharedState 
    {
        uint8 stateEnum;        
        uint8 playerSlotWaiting;

        uint8 currentNumberOfPlayers;

        // Active Accusation Info
        uint8 playerAccusing;
        uint8 accusationWitchType;

        // TODO Tracking time for kick and UI state
        uint previous_action_game_block;
        uint current_block;
        uint current_sequence_number;

        int gameId;
    }

    struct PlayerState 
    {
        bool isAlive;
        uint handCommitment;

        uint8 food;
        uint8 lumber;

        bool[4] WitchAlive; 
    }

    event GameStartEvent(int indexed gameId);
    event JoinGameEvent(int indexed gameId, address indexed player, uint8 slot);
    event ActionEvent(int indexed gameId, uint8 slot, uint8 action, uint8 target, uint8 witchType, uint8 actionLevel);
    event LossEvent(int indexed gameId, uint8 slot, uint8 leaveType);
    event GameOverEvent(int indexed gameId, uint8 winnerSlot, uint8 victoryReason);

    TotalGameState public tgs;

    address public hc_verifierAddr;
    address public vm_verifierAddr;
    address public nw_verifierAddr;

    function GetTGS() external view returns (TotalGameState memory) 
    {
        return tgs;
    }

    function slotByAddress(address a) internal view returns (uint8) 
    {
        for (uint i=0; i<tgs.shared.currentNumberOfPlayers; i++)
        {   
            if (tgs.addresses[i] == a) 
            {
                return uint8 (i);
            }
        }
        return uint8 (INVALID_SLOT);
    }

    constructor(address hc_verifier, address vm_verifier, address nw_verifier) {
        hc_verifierAddr = hc_verifier;
        vm_verifierAddr = vm_verifier;
        nw_verifierAddr = nw_verifier;
    }

    function DEBUG_SetGameState(TotalGameState calldata inputTgs) public onlyOwner
    {
        tgs = inputTgs;
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
    ) external
    {
        require(slotByAddress(msg.sender) == INVALID_SLOT, "You are already in the game");
        require(tgs.shared.stateEnum == GAME_STARTING, "Game has already started");
        
        require(IHCVerifier(hc_verifierAddr).verifyProof(a, b, c, input), "Invalid handcommitment proof");
        
        uint8 playerSlot = tgs.shared.currentNumberOfPlayers;

        tgs.addresses[playerSlot] = msg.sender;
        tgs.players[playerSlot].isAlive = true;
        tgs.players[playerSlot].handCommitment = input[0];
        tgs.players[playerSlot].food = STARTING_FOOD;
        tgs.players[playerSlot].lumber = STARTING_LUMBER;
        for (uint i=0; i<4; i++)
        {   
            tgs.players[playerSlot].WitchAlive[i] = true;
        }

        emit JoinGameEvent(tgs.shared.gameId, msg.sender, playerSlot);

        tgs.shared.currentNumberOfPlayers++;

        if (tgs.shared.currentNumberOfPlayers == 4)
        { 
            emit GameStartEvent(tgs.shared.gameId);     
            tgs.shared.stateEnum = WAITING_FOR_PLAYER_TURN;
            tgs.shared.playerSlotWaiting = 0;
            tgs.shared.playerAccusing = INVALID_SLOT;
            tgs.shared.accusationWitchType = INVALID_SLOT;
        }
    }

    // Game Action Stuff

    function ActionWithProof(
        // required but not part of the proof
        // ignored if not relevant to action
        uint8 actionTarget,
        uint8 witchType,
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
    ) external 
    {
        require(slotByAddress(msg.sender) != INVALID_SLOT, "Address is Not a valid Player");        
        
        uint8 slot = slotByAddress(msg.sender);

        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_TURN, "Not waiting for a player action");
        require(tgs.shared.playerSlotWaiting == slot, "Not your turn.");

        require(tgs.players[slot].handCommitment == input[0], "Hand commitments do not match");

        for (uint i=0; i<4; i++)
        {   
            require(tgs.players[slot].WitchAlive[i] == (input[1+i] > 0), "Witch Alive does not match for index"); // TODO better message
        }

        require(IVMVerifier(vm_verifierAddr).verifyProof(a, b, c, input), "Invalid validmove proof");

        ActionCore(slot, uint8(input[5]), actionTarget, uint8(input[6]), witchType);
    }

    function ActionNoProof(uint8 actionType, uint8 actionTarget, uint8 witchType) external 
    {
        require(slotByAddress(msg.sender) != INVALID_SLOT, "Address is Not a valid Player");        
        
        uint8 slot = slotByAddress(msg.sender);

        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_TURN, "Not waiting for a player action");
        require(tgs.shared.playerSlotWaiting == slot, "Not your turn.");

        ActionCore(slot, actionType, actionTarget, witchType, 0);
    }

    function ActionCore(uint8 playerSlot, uint8 actionType, uint8 actionTarget, uint8 witchType, uint8 actionLevel) private
    {
        emit ActionEvent(tgs.shared.gameId, playerSlot, actionType, actionTarget, witchType, actionLevel);

        require(actionType >= FOOD && actionType <= INQUISITOR, "Unknown action");
        if (actionType == FOOD)
        {
            addResources(playerSlot, actionLevel+1, 0);
            Advance();
        } 
        else if (actionType == LUMBER) 
        {
            addResources(playerSlot, 0, actionLevel+1);
            Advance();
        } 
        else if (actionType == BRIGAND)
        {
            require(slotByAddress(msg.sender) != actionTarget, "Cannot target yourself");
            require(actionTarget >=0 && actionTarget <= 3, "Must target a existing player");
            require(tgs.players[actionTarget].isAlive, "Cannot target a dead player");

            uint8[8] memory brigandTrades = [2,0, 0,2, 0,0, 0,0];
            uint8[8] memory brigandSteal =  [0,1, 1,0, 0,1, 1,0];

            takeResources(playerSlot, brigandTrades[actionLevel*2], brigandTrades[actionLevel*2+1]);
            addResources(playerSlot,  brigandSteal[actionLevel*2],  brigandSteal[actionLevel*2+1]);

            addResources(actionTarget, brigandTrades[actionLevel*2], brigandTrades[actionLevel*2+1]);
            takeResources(actionTarget,  brigandSteal[actionLevel*2],  brigandSteal[actionLevel*2+1]);

            Advance();
        } 
        else if (actionType == INQUISITOR) 
        {
            require(slotByAddress(msg.sender) != actionTarget, "Cannot target yourself");
            require(actionTarget >=0 && actionTarget <= 3, "Must target a existing player");
            require(tgs.players[actionTarget].isAlive, "Cannot target a dead player");

            uint8[8] memory inquisitionCosts = [3,3, 2,2, 1,1, 0,0];

            takeResources(playerSlot, inquisitionCosts[actionLevel*2], inquisitionCosts[actionLevel*2+1]);

            tgs.shared.playerAccusing = playerSlot;
            tgs.shared.accusationWitchType = witchType;
            tgs.shared.playerSlotWaiting = actionTarget;
            tgs.shared.stateEnum = WAITING_FOR_PLAYER_ACCUSATION_RESPONSE;
        }
    }

    function addResources(uint8 slot, uint8 food, uint8 lumber) private
    {
        tgs.players[slot].food += food;
        tgs.players[slot].lumber += lumber;
    }

    function takeResources(uint8 slot, uint8 food, uint8 lumber) private
    {
        require(tgs.players[slot].food >= food, "too little food");
        require(tgs.players[slot].lumber >= lumber, "too little lumber");
        tgs.players[slot].food -= food;
        tgs.players[slot].lumber -= lumber;
    }

    // Witch Accusations 

    function RespondAccusation_NoWitch (
        // proof             
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        // proof publics    
        // signal input ExpectedHash;
        // signal input citizenType;
        uint[2] memory input
    ) external
    {
        require(slotByAddress(msg.sender) != INVALID_SLOT, "Address is Not a valid Player");        
        
        uint8 slot = slotByAddress(msg.sender);

        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_ACCUSATION_RESPONSE, "Not waiting for a player response to accusation");
        require(tgs.shared.playerSlotWaiting == slot, "Not your response.");

        // Check proof inputs match contract state

        require(tgs.players[slot].handCommitment == input[0], "Hand commitments do not match");

        require(tgs.shared.accusationWitchType == uint8(input[1]), "Responding to wrong accusation type");

        require(INWVerifier(nw_verifierAddr).verifyProof(a, b, c, input), "Invalid nowitch proof");

        // no reward
        Advance();
    }

    function RespondAccusation_YesWitch() external
    {
        require(slotByAddress(msg.sender) != INVALID_SLOT, "Address is Not a valid Player");        

        RespondAccusation_YesWitch_Inner(slotByAddress(msg.sender));
        Advance();
    }

    function RespondAccusation_YesWitch_Inner(uint8 slot) internal
    {
        require(tgs.shared.stateEnum == WAITING_FOR_PLAYER_ACCUSATION_RESPONSE, "Not waiting for a player response to accusation");
        require(tgs.shared.playerSlotWaiting == slot, "Not your response.");

        addResources(tgs.shared.playerAccusing, 2, 2);
        tgs.players[slot].WitchAlive[tgs.shared.playerAccusing] = false;
        if (tgs.players[slot].food >= 2 && tgs.players[slot].lumber >=2)
        {
            takeResources(slot, 2, 2);
        } else {
            Die(slot, LOSS_INQUISITION);
        }
    }

    // Game Loss and Surrender

    uint8 constant LOSS_SURRENDER = 0;
    uint8 constant LOSS_KICK = 1;
    uint8 constant LOSS_INQUISITION = 2;

    function Surrender() external 
    {
        if (CheckVictory()) { return; }

        require(slotByAddress(msg.sender) != INVALID_SLOT, "Address is Not a valid Player");        
        
        ForceLoss(slotByAddress(msg.sender), LOSS_SURRENDER);
    }

    function KickCurrentPlayer() external
    {
        if (CheckVictory()) { return; }

        if (false || owner() == msg.sender) 
        {
            ForceLoss(tgs.shared.playerSlotWaiting, LOSS_KICK);
        }
    }

    function ForceLoss(uint8 slot, uint8 reason) internal
    {
        require(tgs.shared.stateEnum != GAME_STARTING, "A Player cannot lose before the game starts."); // TODO fix - just need to write some logic for this case
        require(tgs.players[slot].isAlive, "Player is already dead.");

        // If the player is active we need to advance the game and THEN kick the player
        Die(slot, reason);

        if (tgs.shared.stateEnum == WAITING_FOR_PLAYER_TURN && tgs.shared.playerSlotWaiting == slot) 
        {
            Advance();
        } 
        else if (tgs.shared.stateEnum == WAITING_FOR_PLAYER_ACCUSATION_RESPONSE && tgs.shared.playerSlotWaiting == slot) 
        {
            RespondAccusation_YesWitch_Inner(slot);
            Advance();
        } 
        else 
        {
            // Don't need to advance turn, but check victory
            CheckVictory();
        }
    }

    function Die(uint8 slot, uint8 reason) internal
    {
        tgs.players[slot].isAlive = false;
        emit LossEvent(tgs.shared.gameId, slot, reason);
    }

    function Advance() internal
    {
        if (tgs.shared.stateEnum == WAITING_FOR_PLAYER_ACCUSATION_RESPONSE) 
        {
            tgs.shared.playerSlotWaiting = (tgs.shared.playerAccusing+1) % 4;
            tgs.shared.stateEnum = WAITING_FOR_PLAYER_TURN;
            tgs.shared.playerAccusing = INVALID_SLOT;
            tgs.shared.accusationWitchType = INVALID_SLOT;
        } else {
            tgs.shared.playerSlotWaiting = (tgs.shared.playerSlotWaiting+1) % 4;
            tgs.shared.stateEnum = WAITING_FOR_PLAYER_TURN;
        }

        if (!tgs.players[tgs.shared.playerSlotWaiting].isAlive) 
        {
            Advance();
        }
        CheckVictory();
    }

    uint8 constant VICTORY_RESOURCES = 0;
    uint8 constant VICTORY_ELIMINATED = 1;

    function CheckVictory() internal returns (bool)
    {
        uint8 dead = 0;
        uint8 alivePlayer = 5;
        for (uint8 i=0; i<4; i++)
        {   
            if (tgs.players[i].food >= 10 && tgs.players[i].lumber >= 10) 
            {
                emit GameOverEvent(tgs.shared.gameId, i, VICTORY_RESOURCES);
                ResetGame();
                return true;
            } 
            if (!tgs.players[i].isAlive) 
            { 
                dead++; 
            } 
            else 
            {
                alivePlayer = i;
            }
        }
        if (dead >= 3) 
        {
            emit GameOverEvent(tgs.shared.gameId, alivePlayer, VICTORY_ELIMINATED);
            ResetGame();
            return true;
        }

        return false;
    }

    function ResetGame() internal 
    {
        for (uint i=0; i<4; i++)
        {   
            tgs.addresses[i] = address(0);
        }

        tgs.shared.currentNumberOfPlayers = 0;
        tgs.shared.gameId++;
        tgs.shared.stateEnum = GAME_STARTING;
    }


    // TODO ADD RESET

    // Game State Advancement
}
