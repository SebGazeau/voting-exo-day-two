// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

/**
 * @dev Collection of common custom errors used in multiple contracts
 */
library Errors {
    error InvalidIndex(bytes32 functionName);
    error InvalidWorkflowStatus(uint8 workflow);
    error InvalidVoter();
    error UnregisteredVoter();
    error UnauthorizedVoter();
    error AlreadyVoted();
    error VotingIsOver();
    error StartDateTooClose();
    error EndDateTooClose();
}
