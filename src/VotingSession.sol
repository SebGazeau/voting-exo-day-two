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
        address winningVoter;
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
            WorkflowStatus workflowStatus_,
            Proposal memory winningProposal_,
            address winningVoter_
        )
    {
        proposals_ = getProposalForOneSession(_index);
        (startDate_, endDate_) = getDatesForOneSession(_index);
        workflowStatus_ = getStatusForOneSession(_index);
        winningProposal_ = sessionList[_index].winningProposal;
        winningVoter_ = sessionList[_index].winningVoter;
    }

    function getProposalForOneSession(uint8 _index) public view returns (Proposal[] memory proposals_) {
        return sessionList[_index].vote.getAllProposals();
    }

    function getDatesForOneSession(uint8 _index) public view returns (uint64 startDate_, uint64 endDate_) {
        return (sessionList[_index].vote.getStartDate(), sessionList[_index].vote.getEndDate());
    }

    function getStatusForOneSession(uint8 _index) public view returns (WorkflowStatus workflowStatus_) {
        return sessionList[_index].vote.workflowStatus;
    }

    function setProposalForOneSession(uint8 _index, string memory _description) external {
        sessionList[_index].vote.setProposal(_description);
    }

    function initNewVote(uint64 _startDate, uint64 _endDate) public {
        addSessions(_startDate, _endDate);
        uint currentSize = getSessionSize();
        Session storage session = sessionList[currentSize];
        session.vote.setStartDate(_startDate);
        session.vote.setEndDate(_endDate);
    }

    function getSessionSize() public view returns (uint length_) {
        for (uint i = 0; i < 10; i++) {
            if (address(sessionList[i].winningVoter) != address(0)) {
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
            sessionArchive[lotOfTen][i].vote.setStatus(session.vote.getStatus());
            sessionArchive[lotOfTen][i].winningProposal = session.winningProposal;
            sessionArchive[lotOfTen][i].winningVoter = session.winningVoter;
        }
    }

    function resetCurrentSession() private {
        for (uint i = 0; i < 10; i++) {
            delete sessionList[i];
        }
    }
}
