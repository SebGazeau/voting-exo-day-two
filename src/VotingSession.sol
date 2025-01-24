// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./libraries/Voting.sol";
import "./interfaces/IVotingSession.sol";
/**
 * @title VotingSession
 * @author Sebastien Gazeau
 * @dev Voting Session management
 */

contract VotingSession is IVotingSession, Ownable2Step {
    using Voting for vote;

    struct Session {
        vote vote;
        Proposal winningProposal;
    }

    uint16 private lotOfTen;
    Session[10] private sessionList;
    mapping(uint => Session[10]) private sessionArchive;

    constructor() Ownable(msg.sender) {}

    function getOneSession(uint8 _index)
        external
        view
        returns (
            Proposal[] memory proposals_,
            uint64 startDate_,
            uint64 endDate_,
            uint64 numberOfRegistered_,
            WorkflowStatus workflowStatus_,
            Proposal memory winningProposal_
        )
    {
        proposals_ = getProposalForOneSession(_index);
        (startDate_, endDate_) = getDatesForOneSession(_index);
        workflowStatus_ = getStatusForOneSession(_index);
        numberOfRegistered_ = getNumberOfRegisteredForOneSession(_index);
        winningProposal_ = sessionList[_index].winningProposal;
    }

    function getProposalForOneSession(uint8 _index) public view returns (Proposal[] memory proposals_) {
        return sessionList[_index].vote.getAllProposals();
    }

    function getDatesForOneSession(uint8 _index) public view returns (uint64 startDate_, uint64 endDate_) {
        return (sessionList[_index].vote.getStartDate(), sessionList[_index].vote.getEndDate());
    }

    function getNumberOfRegisteredForOneSession(uint8 _index) public view returns (uint64 numberOfRegistered_) {
        return sessionList[_index].vote.getNumberOfRegistered();
    }

    function getStatusForOneSession(uint8 _index) public view returns (WorkflowStatus workflowStatus_) {
        return sessionList[_index].vote.workflowStatus;
    }

    function setProposalForOneSession(uint8 _index, string memory _description) external onlyOwner {
        if (getStatusForOneSession(_index) != WorkflowStatus.ProposalsRegistrationStarted) {
            revert Errors.InvalidWorkflowStatus(1);
        }

        sessionList[_index].vote.setProposal(_description);
    }

    function initNewVote(uint64 _startDate, uint64 _endDate) external onlyOwner {
        addSessions(_startDate, _endDate);
    }

    function changeStatusForOneSession(uint8 _index) external onlyOwner {
        sessionList[_index].vote.changeStatus();

        if (sessionList[_index].vote.workflowStatus == WorkflowStatus.VotesTallied) {
            sessionList[_index].winningProposal = sessionList[_index].vote.proposals[0];
        }
    }

    function excludeVoter(uint8 _index, address _voter) external onlyOwner {
        if (getStatusForOneSession(_index) != WorkflowStatus.RegisteringVoters) revert Errors.InvalidWorkflowStatus(0);

        sessionList[_index].vote.toggleVoterRegistration(_voter);
    }

    function toVote(uint8 _indexSession, uint8 _indexProposal) external {
        if (getStatusForOneSession(_indexSession) != WorkflowStatus.VotingSessionStarted) {
            revert Errors.InvalidWorkflowStatus(0);
        }

        sessionList[_indexSession].vote.toVote(_indexProposal, msg.sender);
    }

    function registerYourself(uint8 _index) external {
        if (getStatusForOneSession(_index) != WorkflowStatus.RegisteringVoters) revert Errors.InvalidWorkflowStatus(0);

        sessionList[_index].vote.setVoter(msg.sender);
    }

    function registerVoter(uint8 _index, address _voter) external onlyOwner {
        if (getStatusForOneSession(_index) != WorkflowStatus.RegisteringVoters) revert Errors.InvalidWorkflowStatus(0);

        sessionList[_index].vote.setVoter(_voter);
    }

    function getSessionSize() public view returns (uint length_) {
        for (uint i = 0; i < 10; i++) {
            if (
                keccak256(abi.encodePacked(sessionList[i].winningProposal.description))
                    != keccak256(abi.encodePacked(""))
            ) {
                length_++;
            }
        }
    }

    // function getSessions() public view returns (Session[10] calldata sessions_) {
    //     return sessionList;
    // }

    function addSessions(uint64 _startDate, uint64 _endDate) private {
        uint currentSize = getSessionSize();
        if (currentSize >= 9) {
            transferInArchive();
            lotOfTen++;
            resetCurrentSession();
        }

        sessionList[currentSize].vote.setStartDate(_startDate);
        sessionList[currentSize].vote.setEndDate(_endDate);
    }

    function transferInArchive() private {
        for (uint i = 0; i < 10; i++) {
            Session storage session = sessionList[i];
            sessionArchive[lotOfTen][i].vote.setAllProposals(session.vote.getAllProposals());
            sessionArchive[lotOfTen][i].vote.setStartDate(session.vote.getStartDate());
            sessionArchive[lotOfTen][i].vote.setEndDate(session.vote.getEndDate());
            sessionArchive[lotOfTen][i].vote.setNumberOfRegistered(session.vote.getNumberOfRegistered());
            sessionArchive[lotOfTen][i].vote.setStatus(session.vote.getStatus());
            sessionArchive[lotOfTen][i].winningProposal = session.winningProposal;
        }
    }

    function resetCurrentSession() private {
        for (uint i = 0; i < 10; i++) {
            delete sessionList[i];
        }
    }
}
