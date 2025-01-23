// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Voting
 * @author Sebastien Gazeau
 * @dev Voting system management
 */
contract Voting is Ownable {
    // Different states of a vote
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    // block.timestamp<heureFin

    struct Session {
        uint256 startDate;
        uint256 startVoting;
        uint256 endDate;
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    uint256 public lastSession;
    mapping(uint256 => uint256[]) public winningProposalsID;
    mapping(uint256 => Proposal[]) public winningProposals;
    mapping(uint256 => Session) private listSession;
    mapping(uint256 => mapping(address => Voter)) private listVoters;
    mapping(uint256 => Proposal[]) private listProposals;
    mapping(uint256 => WorkflowStatus) private listWorkflowStatus;

    /**
     * @dev Emitted when one voter is added for the voting session
     */
    event VoterRegistered(uint256 index, address voterAddress);
    /**
     * @dev Emitted when multiple voter is added for the voting session
     */
    event VotersRegistered(uint256 index, address[] votersAddress);
    /**
     * @dev Emitted when one voter is excluded for the voting session
     */
    event VoterExcluded(uint256 index, address voterAddress);
    /**
     * @dev Emitted when multiple voter is excluded for the voting session
     */
    event VotersExcluded(uint256 index, address[] votersAddress);
    /**
     * @dev Emitted when a new voting session is created by calling {startVoting}.
     * `lastSession` is the new last index for voting sessions
     */
    event VotingStarted(uint256 lastSession);
    /**
     * @dev Emitted when the owner changes the status of the workflow
     * (from `previousStatus` to `newStatus`) for a voting session `index`.
     */
    event WorkflowStatusChange(uint256 index, WorkflowStatus previousStatus, WorkflowStatus newStatus);
    /**
     * @dev Emitted when a new proposal is created.
     * `proposalId` is the id of the proposal for voting sessions `index`
     */
    event ProposalRegistered(uint256 index, uint256 proposalId, address proposalSender);
    /**
     * @dev Emitted when a proposal is deleted.
     * `proposalId` is the id of the proposal for voting sessions `index`
     */
    event ProposalDeleted(uint256 index, uint256 proposalId);
    /**
     * @dev Emitted when a vote is submit.
     * `proposalId` is the id of the proposal for voting sessions `index`chosose by the `voter`
     */
    event Voted(uint256 index, address voter, uint256 proposalId);

    /**
     * @dev modifier to check if caller is an authorized voter
     */
    modifier anAuthorizedVoter(uint256 _index) {
        require(listVoters[_index][msg.sender].isRegistered, "Caller is not authorised");
        _;
    }
    /**
     * @dev modifier to check if caller can add voters
     */

    modifier inRegisteringStatus(uint256 _index) {
        require(listWorkflowStatus[_index] == WorkflowStatus.RegisteringVoters, "The registration phase is over");
        _;
    }
    /**
     * @dev modifier to check if caller can add voters
     */

    modifier inProposalsRegistrationStatus(uint256 _index) {
        require(
            listWorkflowStatus[_index] == WorkflowStatus.ProposalsRegistrationStarted, "The previous vote is not over"
        );
        _;
    }

    /**
     * @dev start voting
     * @param _session all the dates of the new session
     * @param _index the voting session index
     */
    function startVoting(Session calldata _session, uint256 _index) external onlyOwner {
        require(listSession[_index].startDate == 0, "the session already exists");
        listSession[_index].startDate = _session.startDate;
        listSession[_index].startVoting = _session.startVoting;
        listSession[_index].endDate = _session.endDate;
        lastSession++;
        emit VotingStarted(lastSession);
    }
    /**
     * @dev Get information for a voting session
     * @param _index the voting session index
     * @return session_ information for a voting session
     */

    function getVotingSession(uint256 _index) external view returns (Session memory session_) {
        return (listSession[_index]);
    }

    /**
     * @dev change workflow status for a voting session
     * @param _index the voting session index
     */
    function nextWorkflowStatus(uint256 _index) external onlyOwner {
        require(uint256(listWorkflowStatus[_index]) != 5, "this session is over");
        require(uint256(listWorkflowStatus[_index]) != 4, "start tally votes for this session");
        WorkflowStatus old = listWorkflowStatus[_index];
        listWorkflowStatus[_index] = WorkflowStatus(uint256(listWorkflowStatus[_index]) + 1);
        emit WorkflowStatusChange(_index, old, listWorkflowStatus[_index]);
    }

    /**
     *
     */
    /**
     * Voter Action ******************************************
     */
    /**
     *
     */
    // :::::::::::::::: SETTERS :::::::::::::::: //
    /**
     * @dev add a voter
     * @param _address address to add
     */
    function voterRegistered(address _address, uint256 _index) public onlyOwner inRegisteringStatus(_index) {
        listVoters[_index][_address].isRegistered = true;
        emit VoterRegistered(_index, _address);
    }

    /**
     * @dev add voters
     * @param _address table of addresses to add
     * @param _index the voting session index
     */
    function votersRegistered(address[] memory _address, uint256 _index)
        external
        onlyOwner
        inRegisteringStatus(_index)
    {
        for (uint256 i = 0; i < _address.length; i++) {
            listVoters[_index][_address[i]].isRegistered = true;
        }
        emit VotersRegistered(_index, _address);
    }
    /**
     * @dev exclude a voter
     * @param _address address to eclude
     * @param _index the voting session index
     */

    function voterExcluded(address _address, uint256 _index) public onlyOwner inRegisteringStatus(_index) {
        listVoters[_index][_address].isRegistered = false;
        emit VoterExcluded(_index, _address);
    }
    /**
     * @dev exclude voters
     * @param _address table of addresses to exclude
     * @param _index the voting session index
     */

    function votersExcluded(address[] memory _address, uint256 _index) public onlyOwner inRegisteringStatus(_index) {
        for (uint256 i = 0; i < _address.length; i++) {
            listVoters[_index][_address[i]].isRegistered = false;
        }
        emit VotersExcluded(_index, _address);
    }
    // :::::::::::::::: GETTERS ::::::::::::::::::::://
    /**
     * @dev Get one voter
     * @param _addressVoter address of a voter
     * @param _index the voting session index
     * @return voterReq_ one Voter
     */

    function getVoter(address _addressVoter, uint256 _index) external view returns (Voter memory voterReq_) {
        // voterReq = listVoters[_index][_addressVoter];
        return (listVoters[_index][_addressVoter]);
    }
    /**
     *
     */
    /**
     * Proposal Action ****************************************
     */
    /**
     *
     */
    // :::::::::::::::: SETTER :::::::::::::::: //
    /**
     * @dev set new proposal
     * @param _index the voting session index
     * @param _description a new proposal description
     */

    function setProposal(uint256 _index, string memory _description)
        external
        inProposalsRegistrationStatus(_index)
        anAuthorizedVoter(_index)
    {
        require(listProposals[_index].length < 11, "The number of proposals maximal is 10");
        require(bytes(_description).length > 0, "Proposal is empty");
        listProposals[_index].push(Proposal({description: _description, voteCount: 0}));
        emit ProposalRegistered(_index, listProposals[_index].length - 1, msg.sender);
    }
    // :::::::::::::::: GETTERS ::::::::::::::::::::://
    /**
     * @dev Get all proposal
     * @param _index the voting session index
     * @param _id identifier of the proposal
     * @return proposal_ details proposal
     */

    function getProposal(uint256 _index, uint256 _id) external view returns (Proposal memory proposal_) {
        return (listProposals[_index][_id]);
    }
    /**
     * @dev Get proposals
     * @param _index the voting session index
     * @return proposals_ array proposals
     */

    function getAllProposal(uint256 _index) external view returns (Proposal[] memory proposals_) {
        return (listProposals[_index]);
    }
    // :::::::::::::::: DELETE ::::::::::::::::::::://
    /**
     * @dev delete a proposal
     * @param _index the voting session index
     * @param _id a new proposal description
     */

    function deleteProposal(uint256 _index, uint256 _id) external onlyOwner inProposalsRegistrationStatus(_index) {
        delete listProposals[_index][_id];
        emit ProposalDeleted(_index, _id);
    }
    /**
     *
     */
    /**
     * Vote Action ******************************************
     */
    /**
     *
     */
    // :::::::::::::::: SETTER :::::::::::::::: //
    /**
     * @dev set vote
     * @param _index the voting session index
     * @param _proposalId id of the proposal voted
     */

    function setVoted(uint256 _index, uint256 _proposalId) external anAuthorizedVoter(_index) {
        require(listWorkflowStatus[_index] == WorkflowStatus.VotingSessionStarted, "you can't vote at the moment");
        require(listVoters[_index][msg.sender].hasVoted == false, "You have already voted");
        listVoters[_index][msg.sender].votedProposalId = _proposalId;
        listVoters[_index][msg.sender].hasVoted = true;
        listProposals[_index][_proposalId].voteCount++;
        emit Voted(_index, msg.sender, _proposalId);
    }

    /**
     * @dev calcul the winner of the proposal with egality
     * @param _index the voting session index
     */
    function tallyVotes(uint256 _index) external onlyOwner {
        require(
            listWorkflowStatus[_index] == WorkflowStatus.VotingSessionEnded,
            "Current status is not voting session ended"
        );
        uint256 highestCount;
        uint256[5] memory winners;
        uint256 nbWinners;
        for (uint256 i = 0; i < listProposals[_index].length; i++) {
            if (listProposals[_index][i].voteCount == highestCount) {
                if (nbWinners < 5) {
                    winners[nbWinners] = i;
                    nbWinners++;
                }
            }
            if (listProposals[_index][i].voteCount > highestCount) {
                delete winners;
                winners[0] = i;
                highestCount = listProposals[_index][i].voteCount;
                nbWinners = 1;
            }
        }
        for (uint256 j = 0; j < nbWinners; j++) {
            winningProposalsID[_index].push(winners[j]);
            winningProposals[_index].push(listProposals[_index][winners[j]]);
        }
        listWorkflowStatus[_index] = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(_index, WorkflowStatus.VotingSessionEnded, listWorkflowStatus[_index]);
    }
    // :::::::::::::::: GETTERS ::::::::::::::::::::://
    /**
     * @dev Get winning proposals ID
     * @param _index the voting session index
     * @return winningProposalsID_ list winning proposals ID
     */

    function getWinningProposalsID(uint256 _index) external view returns (uint256[] memory winningProposalsID_) {
        return (winningProposalsID[_index]);
    }
    /**
     * @dev Get winning proposals
     * @param _index the voting session index
     * @return winningProposals_ list winning proposals
     */

    function getWinningProposals(uint256 _index) external view returns (Proposal[] memory winningProposals_) {
        return (winningProposals[_index]);
    }
}
