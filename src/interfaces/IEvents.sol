// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;
// import "./WorkflowStatus.sol";

import "../libraries/Voting.sol";
/**
 * @dev Collection of common custom Events used in multiple contracts
 */

interface IEvents {
    // // Different states of a vote
    // enum WorkflowStatus {
    //     RegisteringVoters,
    //     ProposalsRegistrationStarted,
    //     ProposalsRegistrationEnded,
    //     VotingSessionStarted,
    //     VotingSessionEnded,
    //     VotesTallied
    // }
    /**
     * @dev Emitted when one voter is added for the voting session
     */
    event VoterRegistered(uint index, address voterAddress);
    /**
     * @dev Emitted when multiple voter is added for the voting session
     */
    event VotersRegistered(uint index, address[] votersAddress);
    /**
     * @dev Emitted when one voter is excluded for the voting session
     */
    event VoterExcluded(uint index, address voterAddress);
    /**
     * @dev Emitted when multiple voter is excluded for the voting session
     */
    event VotersExcluded(uint index, address[] votersAddress);
    /**
     * @dev Emitted when a new voting session is created by calling {startVoting}.
     * `lastSession` is the new last index for voting sessions
     */
    event VotingStarted(uint lastSession);
    /**
     * @dev Emitted when the owner changes the status of the workflow
     * (from `previousStatus` to `newStatus`) for a voting session `index`.
     */
    event WorkflowStatusChange(uint index, WorkflowStatus previousStatus, WorkflowStatus newStatus);
    /**
     * @dev Emitted when a new proposal is created.
     * `proposalId` is the id of the proposal for voting sessions `index`
     */
    event ProposalRegistered(uint index, uint proposalId, address proposalSender);
    /**
     * @dev Emitted when a proposal is deleted.
     * `proposalId` is the id of the proposal for voting sessions `index`
     */
    event ProposalDeleted(uint index, uint proposalId);
    /**
     * @dev Emitted when a vote is submit.
     * `proposalId` is the id of the proposal for voting sessions `index`chosose by the `voter`
     */
    event Voted(uint index, address voter, uint proposalId);
}
