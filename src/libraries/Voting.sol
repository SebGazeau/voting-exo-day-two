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
    RegisteringVoters,
    ProposalsRegistrationStarted,
    ProposalsRegistrationEnded,
    VotingSessionStarted,
    VotingSessionEnded,
    VotesTallied
}

struct Proposal {
    string description;
    uint voteCount;
}

struct voter {
    bool isRegistered;
    bool hasVoted;
}

struct vote {
    Proposal[] proposals;
    mapping(address => voter) voters;
    uint64 startDate;
    uint64 endDate;
    uint64 numberOfRegistered;
    WorkflowStatus workflowStatus;
}

library Voting {
    // :::::::::::::::: GETTERS :::::::::::::::: //

    function getProposal(vote storage v, uint _index) external view returns (Proposal memory proposal_) {
        if (_index >= v.proposals.length) revert Errors.InvalidIndex(keccak256("getProposal"));

        return v.proposals[_index];
    }

    function getAllProposals(vote storage v) external view returns (Proposal[] memory proposals_) {
        return v.proposals;
    }

    function getVoter(vote storage v, address _voter) external view returns (voter memory voter_) {
        if (_voter == address(0)) revert Errors.InvalidVoter();
        return v.voters[_voter];
    }

    function getStartDate(vote storage v) external view returns (uint64 startDate_) {
        return v.startDate;
    }

    function getEndDate(vote storage v) external view returns (uint64 endDate_) {
        return v.endDate;
    }

    function getNumberOfRegistered(vote storage v) external view returns (uint64 numberOfRegistered_) {
        return v.numberOfRegistered;
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

    function setVoter(vote storage v, address _voter) internal {
        if (_voter == address(0)) revert Errors.InvalidVoter();

        v.voters[_voter] = voter(true, false);
        v.numberOfRegistered++;
    }

    function setStartDate(vote storage v, uint64 _startDate) internal {
        if (block.timestamp + 1 weeks > _startDate) revert Errors.StartDateTooClose();

        v.startDate = _startDate;
    }

    function setEndDate(vote storage v, uint64 _endDate) internal {
        if (block.timestamp + 2 weeks > _endDate) revert Errors.EndDateTooClose();

        v.endDate = _endDate;
    }

    function setNumberOfRegistered(vote storage v, uint64 _numberOfRegistered) internal {
        v.numberOfRegistered = _numberOfRegistered;
    }

    function setStatus(vote storage v, WorkflowStatus _workflowStatus) internal {
        v.workflowStatus = _workflowStatus;
    }
    // :::::::::::::::: ACTIONS :::::::::::::::: //

    function changeStatus(vote storage v) internal {
        if (v.workflowStatus == WorkflowStatus.VotesTallied) {
            revert Errors.VotingIsOver();
        }
        if (v.workflowStatus == WorkflowStatus.VotingSessionEnded) {
            sortProposalsByVoteCountDesc(v);
        }
        v.workflowStatus = WorkflowStatus(uint8(v.workflowStatus) + 1);
    }

    function toggleVoterRegistration(vote storage v, address _voter) internal {
        if (_voter == address(0)) revert Errors.InvalidVoter();

        bool currentStatus = v.voters[_voter].isRegistered;
        v.voters[_voter].isRegistered = !currentStatus;

        if (currentStatus) {
            v.numberOfRegistered -= 1;
        } else {
            v.numberOfRegistered += 1;
        }
    }

    function toVote(vote storage v, uint _indexProposal, address _voter) internal {
        if (!isAuthorizedVoter(v, _voter)) revert Errors.UnauthorizedVoter();

        v.proposals[_indexProposal].voteCount++;
        v.voters[_voter].hasVoted = true;
    }

    function sortProposalsByVoteCountDesc(vote storage v) private {
        uint length = v.proposals.length;
        for (uint i = 0; i < length; i++) {
            for (uint j = i + 1; j < length; j++) {
                if (v.proposals[j].voteCount > v.proposals[i].voteCount) {
                    Proposal memory temp = v.proposals[i];
                    v.proposals[i] = v.proposals[j];
                    v.proposals[j] = temp;
                }
            }
        }
    }

    function isAuthorizedVoter(vote storage v, address _voter) private view returns (bool) {
        if (_voter == address(0)) revert Errors.InvalidVoter();
        if (!v.voters[_voter].isRegistered) revert Errors.UnregisteredVoter();
        if (v.voters[_voter].hasVoted) revert Errors.AlreadyVoted();

        return true;
    }
}
