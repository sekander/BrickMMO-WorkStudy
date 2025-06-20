<?php
// includes/wallets.php

$walletsFile = __DIR__ . '/../data/wallets.json';

function loadWallets() {
    global $walletsFile;
    if (!file_exists($walletsFile)) {
        file_put_contents($walletsFile, json_encode([], JSON_PRETTY_PRINT));
    }
    return json_decode(file_get_contents($walletsFile), true);
}

function saveWallets($wallets) {
    global $walletsFile;
    file_put_contents($walletsFile, json_encode($wallets, JSON_PRETTY_PRINT));
}

function createWallet() {
    $privateKey = bin2hex(random_bytes(32));
    $publicKey = hash('sha256', $privateKey);
    $address = substr($publicKey, 0, 40);

    $wallet = [
        'privateKey' => $privateKey,
        'publicKey' => $publicKey,
        'address' => $address
    ];

    $wallets = loadWallets();
    $wallets[] = $wallet;
    saveWallets($wallets);

    return $wallet;
}

function findWalletByAddress($address) {
    $wallets = loadWallets();
    foreach ($wallets as $wallet) {
        if ($wallet['address'] === $address) {
            return $wallet;
        }
    }
    return null;
}

