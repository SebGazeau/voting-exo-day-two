// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "./Errors.sol";
/**
 * @title Voting
 * @author Sebastien Gazeau
 * @dev Voting system management
 */
// Different states of a vote

enum WorkflowStatus {
    Registeringvoters,
    ProposalsRegistrationStarted,
    ProposalsRegistrationEnded,
    VotingSessionStarted,
    VotingSessionEnded,
    votesTallied
}

struct Proposal {
    string description;
    uint voteCount;
}

struct voter {
    bool isRegistered;
    bool hasvoted;
}

struct vote {
    Proposal[] proposals;
    mapping(address => voter) voters;
    uint64 startDate;
    uint64 endDate;
    WorkflowStatus workflowStatus;
}

library Voting {
    // :::::::::::::::: GETTERS :::::::::::::::: //
    function getProposal(vote storage v, uint _index) external view returns (Proposal memory proposal_) {
        require(_index < v.proposals.length, Errors.InvalidIndex(keccak256("getProposal")));

        return v.proposals[_index];
    }

    function getAllProposals(vote storage v) external view returns (Proposal[] memory proposals_) {
        return v.proposals;
    }

    function getvoter(vote storage v, address _voter) external view returns (voter memory voter_) {
        return v.voters[_voter];
    }

    function getStartDate(vote storage v) external view returns (uint64 startDate_) {
        return v.startDate;
    }

    function getEndDate(vote storage v) external view returns (uint64 endDate_) {
        return v.endDate;
    }

    function getStatus(vote storage v) external view returns (WorkflowStatus workflowStatus_) {
        return v.workflowStatus;
    }

    // :::::::::::::::: SETTERS :::::::::::::::: //
    function setProposal(vote storage v, string memory _proposal) internal {
        v.proposals.push(Proposal(_proposal, 0));
    }

    function setAllProposals(vote storage v, Proposal[] memory _proposals) internal {
        for (uint i = 0; i < _proposals.length; i++) {
            v.proposals.push(_proposals[i]);
        }
    }

    function setvoter(vote storage v, address _voter) internal {
        v.voters[_voter] = voter(true, false);
    }

    function setStartDate(vote storage v, uint64 _startDate) internal {
        v.startDate = _startDate;
    }

    function setEndDate(vote storage v, uint64 _endDate) internal {
        v.endDate = _endDate;
    }

    function setStatus(vote storage v, WorkflowStatus _workflowStatus) internal {
        v.workflowStatus = _workflowStatus;
    }

    function changeStatus(vote storage v) internal {
        v.workflowStatus = WorkflowStatus(uint8(v.workflowStatus) + 1);
    }
}
