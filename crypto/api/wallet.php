<?php
// api/wallet.php
header('Content-Type: application/json');

require_once __DIR__ . '/../includes/blockchain.php';
require_once __DIR__ . '/../includes/wallets.php';

$action = $_GET['action'] ?? '';





// Helper: get all wallet balances by scanning blockchain
function getBalances() {
    $wallets = loadWallets();
    $chain = loadBlockchain();

    

    $balances = [];

    foreach ($wallets as $wallet) {
        $address = $wallet['address'];
        $balance = 0;
        foreach ($chain as $block) {
            foreach ($block['transactions'] ?? [] as $tx) {
                if ($tx['to'] === $address) {
                    $balance += $tx['amount'];
                }
                if ($tx['from'] === $address) {
                    $balance -= $tx['amount'];
                }
            }
        }
        $balances[$address] = $balance;
    }

    return $balances;
}

if ($action === 'load_blockchain') {
    $chain = loadBlockchain();
    echo json_encode(['success' => true, 'blockchain' => $chain]);
    exit;
}

if ($action === 'create_wallet') {
    $wallet = createWallet();
    echo json_encode(['success' => true, 'wallet' => $wallet]);
    exit;
}

if ($action === 'get_balances') {
    $balances = getBalances();
    echo json_encode(['success' => true, 'balances' => $balances]);
    exit;
}

if ($action === 'send') {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input || !isset($input['from'], $input['private_key'], $input['to'], $input['amount'])) {
        echo json_encode(['error' => 'Missing transaction data']);
        exit;
    }

    $from = $input['from'];
    $privateKey = $input['private_key'];
    $to = $input['to'];
    $amount = (float)$input['amount'];
    
    $wallet = findWalletByAddress($from);
    if (!$wallet) {
        echo json_encode(['error' => 'Sender wallet not found']);
        exit;
    }
    if ($wallet['privateKey'] !== $privateKey) {
        echo json_encode(['error' => 'Invalid private key']);
        exit;
    }
    
    // Check balance
    $balances = getBalances();
    if (!isset($balances[$from]) || $balances[$from] < $amount) {
        echo json_encode(['error' => 'Insufficient funds']);
        exit;
    }

    // Add transaction to pending
    $transaction = ['from' => $from, 'to' => $to, 'amount' => $amount];
    addPendingTransaction($transaction);
      // Return the input back in the response
    
    //Mine
    minePendingTransactions();

    echo json_encode(['success' => true, 'transaction' => $transaction]);
    
    
    exit;
}


if ($action === 'mine') {
    $result = minePendingTransactions();


    echo json_encode($result);
    exit;
}

// ======= ADMIN: Add coins directly to wallet ==========
// Admin adds coins without needing a private key
if ($action === 'admin_add_coins') {
    session_start();  // Needed to access session PIN

    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input || !isset($input['address'], $input['amount'], $input['pin'])) {
        echo json_encode(['error' => 'Missing data (address, amount, or PIN)']);
        exit;
    }

    $address = $input['address'];
    $amount = (float)$input['amount'];
    $entered_pin = $input['pin'];

    if (!isset($_SESSION['pin']) || $_SESSION['pin'] !== $entered_pin) {
        echo json_encode(['error' => 'Invalid or missing session PIN']);
        exit;
    }

    $wallet = findWalletByAddress($address);
    if (!$wallet) {
        echo json_encode(['error' => 'Wallet not found']);
        exit;
    }

    $transaction = ['from' => 'ADMIN', 'to' => $address, 'amount' => $amount];
    addPendingTransaction($transaction);
    minePendingTransactions();

    echo json_encode([
        'success' => true,
        'message' => "Added $amount coins to $address",
        'transaction' => $transaction
    ]);
    exit;
}



// if ($action === 'admin_add_coins') {
//     $input = json_decode(file_get_contents('php://input'), true);

//     if (!$input || !isset($input['address'], $input['amount'], $input['admin_password'])) {
//         echo json_encode(['error' => 'Missing admin add coins data']);
//         exit;
//     }

//     $address = $input['address'];
//     $amount = (float)$input['amount'];
//     $admin_password = $input['admin_password'];

//     /*
//     // Simple admin password check (change this in real app)
//     $correct_password = 'supersecretadminpass';

//     if ($admin_password !== $correct_password) {
//         echo json_encode(['error' => 'Invalid admin password']);
//         exit;
//     }
//     */

//     // Validate wallet exists
//     $wallet = findWalletByAddress($address);
//     if (!$wallet) {
//         echo json_encode(['error' => 'Wallet not found']);
//         exit;
//     }

//     // Create a special transaction "from" address 'ADMIN' or null to add coins
//     $transaction = ['from' => 'ADMIN', 'to' => $address, 'amount' => $amount];

//     addPendingTransaction($transaction);

//     //Mine
//     minePendingTransactions();

//     echo json_encode(['success' => true, 'message' => "Added $amount coins to $address", 'transaction' => $transaction]);
//     exit;
// }


echo json_encode(['error' => 'Invalid action']);

