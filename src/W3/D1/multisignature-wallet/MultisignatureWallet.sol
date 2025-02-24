// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultisignatureWallet {
    address[] public owners;
    uint8 public threshold;
    mapping(address => bool) public isOwner;

    // 提案结构体
    struct Proposal {
        address target; // 目标地址，可以是合约地址，也可以是EOA
        uint256 value; // 转账金额
        bytes data; // 调用数据，如果是普通ETH转账则为空
        bool executed; // 是否被执行
        uint256 confirmationCount; // 多签持有人确认数量
    }

    Proposal[] public proposals;
    // 记录每个地址对每个提案的确认状态，proposalId -> 用户地址 -> 是否确认
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // 是否为多签持有者
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    // 提案是否存在
    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposals.length, "Proposal does not exist");
        _;
    }

    // 提案是否被执行
    modifier notExecuted(uint256 proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address target, uint256 value, bytes data);
    event ProposalConfirmed(uint256 indexed proposalId, address indexed confirmer);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event Deposit(address indexed sender, uint amount, uint balance);

    // 创建多签钱包时，确定所有的多签持有⼈和签名门槛
    constructor(address[] memory _owners, uint8 _threshold) {
        require(_threshold > 0, "Threshold must be > 0");
        require(_threshold <= _owners.length, "Threshold should less than owner count");

        // 遍历传入的地址列表，依次设定为多签持有人
        for (uint8 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            require(!isOwner[owner], "The owner already exists");

            isOwner[owner] = true;
            owners.push(owner);
        }

        // 设置签名门槛
        threshold = _threshold;
    }

    // 多签持有⼈可提交提案
    function submitProposal(address _target, uint256 _value, bytes memory _data) public onlyOwner {
        uint256 proposalId = proposals.length;
        // 提交提案时自动 +1，提交者默认确认
        proposals.push(Proposal({target: _target, value: _value, data: _data, executed: false, confirmationCount: 1}));
        isConfirmed[proposalId][msg.sender] = true;

        emit ProposalSubmitted(proposalId, msg.sender, _target, _value, _data);
    }

    // 其他多签⼈确认提案
    function confirmProposal(uint256 proposalId) public onlyOwner proposalExists(proposalId) notExecuted(proposalId) {
        require(!isConfirmed[proposalId][msg.sender], "Already confirmed");
        
        isConfirmed[proposalId][msg.sender] = true;
        proposals[proposalId].confirmationCount++;
        
        emit ProposalConfirmed(proposalId, msg.sender);
    }

    // 达到多签⻔槛、任何⼈都可以执⾏交易
    function excuteProposal(uint256 proposalId) public proposalExists(proposalId) notExecuted(proposalId) {
        Proposal storage proposal = proposals[proposalId]; 
        // 确认达到多签门槛
        require(proposal.confirmationCount >= threshold, "The confirmation count should be at least equal to the threshold");
        
        // 执行交易
        proposal.executed = true;
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Transaction execution failed");
        
        emit ProposalExecuted(proposalId, msg.sender);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}
