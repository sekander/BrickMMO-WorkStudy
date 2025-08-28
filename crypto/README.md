-----

# PHP-Crypto-Wallet

A simplified PHP-based cryptocurrency wallet and blockchain implementation, demonstrating core concepts like user management, wallet creation, transaction processing, and a basic Proof-of-Work mining mechanism.

**Disclaimer:** This project is for educational and demonstrative purposes only and is **not intended for production use** with real funds. It contains known security vulnerabilities (e.g., plaintext PIN storage in `users.json`) and should not be used in any environment where security is critical.

-----

## Features

  * **User Authentication:** Secure login and registration with password hashing.
  * **Wallet Management:** Create new cryptocurrency wallets with address and encrypted private key generation.
  * **Transaction System:** Send coins between wallets, with balance checks.
  * **Proof-of-Work Mining:** A basic mining process to confirm transactions and add blocks to the blockchain.
  * **Admin Functionality:** Ability for administrators to add coins to any wallet (secured by a PIN in the current implementation).
  * **Blockchain Data:** Stores blockchain data in a JSON file (`data/blockchain.json`).
  * **User Data:** Stores user and wallet information (including sensitive data like private keys and PINs) in a MySQL database and `users.json`.

-----

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

  * PHP 7.4+ (with `mysqli`, `json`, `openssl` extensions enabled)
  * MySQL Database
  * Web server (Apache, Nginx, or PHP's built-in server)

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/PHP-Crypto-Wallet.git
    cd PHP-Crypto-Wallet
    ```

2.  **Configure your database:**

      * Create a MySQL database (e.g., `crypto_login`).

      * Import the following SQL schema:

        ```sql
        CREATE TABLE users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(255) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            role VARCHAR(50) DEFAULT 'user',
            wallet_address VARCHAR(255) UNIQUE,
            wallet_private_key_encrypted TEXT
        );
        ```

3.  **Update `config.php`:**

    Open `config.php` and update the database credentials and the `ENCRYPTION_KEY`. **It's crucial to change `ENCRYPTION_KEY` to a strong, random 32-byte string.**

    ```php
    // config.php
    define('DB_HOST', 'localhost'); // Your database host
    define('DB_USERNAME', 'your_db_username');
    define('DB_PASSWORD', 'your_db_password');
    define('DB_NAME', 'crypto_login');

    // !!! IMPORTANT: Change this to a secure random 32-byte string !!!
    define('ENCRYPTION_KEY', 'your_32_byte_encryption_key_here');
    ```

4.  **Ensure directory permissions:**

    Make sure your web server has write permissions to the `data/` directory for `blockchain.json`, `pending_transactions.json`, and `wallets.json`.

    ```bash
    chmod -R 775 data/
    ```

5.  **Serve the application:**

    You can use PHP's built-in web server for quick testing:

    ```bash
    php -S localhost:8000
    ```

    Then, open your browser and navigate to `http://localhost:8000`.

-----

## Project Structure Explained

The project follows a logical and organized structure to separate concerns and make the codebase more manageable.

```
.
├── api/
│   ├── login.php
│   ├── logout.php
│   ├── register.php
│   ├── users.json
│   ├── verify_pin.php
│   └── wallet.php
├── config.php
├── data/
│   ├── blockchain.json
│   ├── pending_transactions.json
│   └── wallets.json
├── includes/
│   ├── blockchain.php
│   └── wallets.php
├── index.html
└── pages/
    ├── admin.html
    ├── auth_check.php
    └── user.html
```

Let's break down each component:

  * **`/api/`**:
    This directory houses all the backend PHP scripts that expose functionality as API endpoints. These scripts typically handle requests from the frontend, interact with the database or data files, and return JSON responses.

      * `login.php`: Handles user authentication and session creation.
      * `logout.php`: Manages user session termination.
      * `register.php`: Processes new user registrations, including wallet creation and initial data storage.
      * `users.json`: **(Security Concern - See Disclaimer)** A flat-file JSON database containing user details, including sensitive information like plaintext PINs and private keys (for demonstration purposes only).
      * `verify_pin.php`: Checks a provided PIN against the one stored in the user's session for verification purposes.
      * `wallet.php`: The central API endpoint for all cryptocurrency wallet and blockchain-related operations (e.g., creating wallets, sending transactions, mining, checking balances, and admin coin additions).

  * **`config.php`**:
    This file serves as the central configuration hub for the entire application. It contains:

      * Database connection parameters (host, username, password, database name).
      * The `ENCRYPTION_KEY` used for encrypting sensitive data (crucial to change for production).
      * Helper functions like `jsonResponse` for consistent API output and `sanitizeInput` for basic input sanitation.
      * Encryption and decryption utilities (`encryptData`, `decryptData`).

  * **`/data/`**:
    This directory is dedicated to storing persistent data files related to the blockchain and wallets. Using JSON files here simplifies the demonstration but is **not suitable for scalable production environments**.

      * `blockchain.json`: The immutable ledger of all confirmed blocks and transactions, representing the core blockchain.
      * `pending_transactions.json`: Temporarily holds transactions that have been submitted but not yet mined into a block.
      * `wallets.json`: A flat-file JSON database for storing wallet addresses and their corresponding private keys (for demonstration purposes only; often managed by users or a secure wallet service in real applications).

  * **`/includes/`**:
    This directory contains reusable PHP functions and logic that are common across different parts of the application, promoting modularity and preventing code duplication.

      * `blockchain.php`: Contains core functions for managing the blockchain, such as loading/saving the chain, adding blocks, calculating hashes, and implementing the Proof-of-Work algorithm.
      * `wallets.php`: Provides functions for generating new wallet addresses, private keys, and potentially interacting with `wallets.json` to find wallet details.

  * **`index.html`**:
    This is the main entry point for the web application. It likely serves as the primary user interface from which users can interact with the various API functionalities, potentially linking to other HTML pages within the `pages/` directory.

  * **`/pages/`**:
    This directory is intended for additional frontend HTML pages or client-side components that make up the user interface beyond the main `index.html`.

      * `admin.html`: The administrative interface, likely providing tools for managing users, adding coins, or viewing blockchain data with elevated privileges.
      * `auth_check.php`: A PHP script likely used for server-side checks to ensure a user is authenticated and authorized before serving certain pages or content.
      * `user.html`: The main user dashboard or interface, where logged-in users can view their wallet balance, send transactions, and access other user-specific features.

-----

## API Endpoints

The `api/` directory serves various functionalities:

### `api/login.php`

Handles user login.

  * **Method:** `POST`
  * **Request Body (JSON):**
    ```json
    {
        "username": "user",
        "password": "password123"
    }
    ```
  * **Success Response:**
    ```json
    {
        "success": true,
        "user": {
            "username": "user",
            "role": "user",
            "walletAddress": "..."
        }
    }
    ```
  * **Error Response:**
    ```json
    {
        "error": "Invalid username or password"
    }
    ```

### `api/logout.php`

Handles user logout by destroying the session.

  * **Method:** `GET` (or `POST` in a typical application)
  * **Success Response:**
    ```json
    {
        "success": true,
        "message": "Logged out successfully"
    }
    ```

### `api/register.php`

Registers a new user and creates their wallet.

  * **Method:** `POST`
  * **Request Body (JSON):**
    ```json
    {
        "username": "newUser",
        "password": "strongpassword",
        "pin": "1234",
        "walletAddress": "generated_wallet_address",
        "walletPrivateKey": "generated_private_key"
    }
    ```
    **Note:** The `pin` and `walletPrivateKey` are sent in plaintext. This is a **security vulnerability** in the provided code and should be handled with much greater care in a production environment.
  * **Success Response:**
    ```json
    {
        "success": true
    }
    ```
  * **Error Response:**
    ```json
    {
        "error": "Username already exists"
    }
    ```

### `api/wallet.php`

Manages wallet operations and blockchain interactions. This file uses a `GET` parameter `action` to determine the operation.

  * **`?action=load_blockchain`**

      * **Method:** `GET`
      * **Description:** Retrieves the entire blockchain.
      * **Response:** `{"success": true, "blockchain": [...]}`

  * **`?action=create_wallet`**

      * **Method:** `GET`
      * **Description:** Generates a new wallet address and private key.
      * **Response:** `{"success": true, "wallet": {"address": "...", "privateKey": "..."}}`

  * **`?action=get_balances`**

      * **Method:** `GET`
      * **Description:** Calculates and returns the balances for all known wallets.
      * **Response:** `{"success": true, "balances": {"address1": amount1, "address2": amount2}}`

  * **`?action=send`**

      * **Method:** `POST`
      * **Description:** Creates a new transaction and adds it to the pending transactions, then mines a new block to include it.
      * **Request Body (JSON)::**
        ```json
        {
            "from": "sender_address",
            "private_key": "sender_private_key",
            "to": "recipient_address",
            "amount": 10.5
        }
        ```
      * **Response:** `{"success": true, "transaction": {"from": "...", "to": "...", "amount": ...}}`

  * **`?action=mine`**

      * **Method:** `GET`
      * **Description:** Mines any pending transactions into a new block.
      * **Response:** `{"success": true, "message": "Block mined!", "block": {...}}` (or an error if no pending transactions)

  * **`?action=admin_add_coins`**

      * **Method:** `POST`
      * **Description:** Allows an admin to directly add coins to a specified wallet. Requires a session PIN check.
      * **Request Body (JSON):**
        ```json
        {
            "address": "target_wallet_address",
            "amount": 100,
            "pin": "admin_session_pin"
        }
        ```
      * **Response:** `{"success": true, "message": "...", "transaction": {...}}`

### `api/verify_pin.php`

Verifies the user's PIN against the one stored in the session.

  * **Method:** `POST`
  * **Request Body (JSON):**
    ```json
    {
        "pin": "1234"
    }
    ```
  * **Success Response:**
    ```json
    {
        "success": true
    }
    ```
  * **Error Response:**
    ```json
    {
        "success": false,
        "error": "Invalid PIN"
    }
    ```

-----

## Security Considerations (IMPORTANT)

As noted, this project is for learning and demonstrating, and it has several areas that need significant improvement for any real-world application:

  * **`users.json`:** Stores `privateKey` and `pin` in plaintext. This file should **never** contain sensitive information in a production system. Private keys should remain encrypted and only be decrypted client-side or for very specific, secure server-side operations with robust access control.
  * **PIN Storage:** Storing the **PIN** in the session (`$_SESSION['pin']`) after reading it from `users.json` is highly insecure. A PIN, if used, should ideally be hashed and compared securely, never stored in plain view, even temporarily in a session.
  * **`ENCRYPTION_KEY`:** The `ENCRYPTION_KEY` in `config.php` is hardcoded to `'your_32_byte_encryption_key_here'`. This must be changed to a truly random and securely managed key for any real encryption.
  * **Admin PIN:** The `admin_add_coins` functionality relies on a session PIN. This is a weak authentication mechanism for such a critical operation. Robust authentication and authorization (e.g., proper role-based access control with secure credentials) would be required.
  * **Input Validation & Sanitization:** While `sanitizeInput()` is used, comprehensive input validation beyond basic length checks is essential for all inputs, especially for financial transactions.
  * **Error Handling:** Generic error messages like "Missing parameters" or "Database connection failed" can sometimes leak information. More specific but non-revealing error messages are preferred.
  * **Session Management:** Review and harden session management, including session fixation, hijacking, and timeout settings.
  * **No Digital Signatures:** The current transaction model doesn't appear to implement digital signatures, which are fundamental to cryptocurrencies to prove ownership and prevent tampering. Transactions are merely structures.
  * **Scalability & Performance:** JSON files for blockchain and user data are not scalable for high-volume transactions or a large number of users. A proper database solution for the blockchain itself would be necessary for any significant usage.

-----

## Contributing

Feel free to fork this repository, open issues, and submit pull requests. This project is a great starting point for understanding blockchain and wallet concepts in a simplified environment.

