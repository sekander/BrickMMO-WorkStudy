<?php
// includes/blockchain.php

$dataDir = __DIR__ . '/../data';
$blockchainFile = $dataDir . '/blockchain.json';
$pendingFile = $dataDir . '/pending_transactions.json';


function loadBlockchain() {
    global $blockchainFile;
    if (!file_exists($blockchainFile)) {
        $genesisBlock = [
            'index' => 0,
            'timestamp' => time(),
            'transactions' => [],
            'previous_hash' => '0',
            'hash' => '',
            'nonce' => 0
        ];
        $genesisBlock['hash'] = hashBlock($genesisBlock);
        file_put_contents($blockchainFile, json_encode([$genesisBlock], JSON_PRETTY_PRINT));
    }
    return json_decode(file_get_contents($blockchainFile), true);
}

function saveBlockchain($chain) {
    global $blockchainFile;
    file_put_contents($blockchainFile, json_encode($chain, JSON_PRETTY_PRINT));
}

function loadPendingTransactions() {
    global $pendingFile;
    if (!file_exists($pendingFile)) {
        file_put_contents($pendingFile, json_encode([], JSON_PRETTY_PRINT));
    }
    return json_decode(file_get_contents($pendingFile), true);
}

function savePendingTransactions($transactions) {
    global $pendingFile;
    file_put_contents($pendingFile, json_encode($transactions, JSON_PRETTY_PRINT));
}

function hashBlock($block) {
	return hash('sha256', $block['index'] . 
			      $block['timestamp'] . 
			      json_encode($block['transactions']) . 
			      $block['previous_hash'] . 
			      $block['nonce']);
}

function minePendingTransactions() {
    $chain = loadBlockchain();
	
    if (!is_array($chain)){
    	$chain = [];
    }

    $pending = loadPendingTransactions();

    if (count($pending) === 0) {
        return ['error' => 'No transactions to mine'];
    }

    $lastBlock = end($chain);
    $newBlock = [
        'index' => $lastBlock['index'] + 1,
        'timestamp' => time(),
        'transactions' => $pending,
        'previous_hash' => $lastBlock['hash'],
        'nonce' => 0,
        'hash' => ''
    ];

    // Simple Proof of Work (finding a hash starting with '0000')
    while (substr($newBlock['hash'], 0, 4) !== '0000') {
        $newBlock['nonce']++;
        $newBlock['hash'] = hashBlock($newBlock);
    }

    $chain[] = $newBlock;
    saveBlockchain($chain);

    // Clear pending transactions after mining
    savePendingTransactions([]);

    return ['message' => 'Block mined', 'block' => $newBlock];
}

function addPendingTransaction($transaction) {
    $pending = loadPendingTransactions();
    $pending[] = $transaction;
    savePendingTransactions($pending);
}

