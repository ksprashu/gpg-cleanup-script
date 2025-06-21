# GPG Cleanup Script

This script helps you clean up your GPG keyring by identifying and deleting expired or unknown keys.

## Usage

1.  **Make the script executable:**
    ```bash
    chmod +x gpg-cleanup-script.sh
    ```

2.  **Perform a dry run:**
    ```bash
    ./gpg-cleanup-script.sh
    ```
    This will list the keys that are flagged for deletion without actually deleting them.

3.  **Delete the keys:**
    ```bash
    ./gpg-cleanup-script.sh --delete
    ```
    This will prompt you for confirmation and then delete the flagged keys.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
