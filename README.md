# GPG Cleanup Script

This script helps you clean up your GPG keyring by identifying and deleting expired or unknown keys.

## Usage

1.  **Make the script executable:**
    ```bash
    chmod +x gpg-cleanup-script.sh
    ```

2.  **Run the script:**
    ```bash
    ./gpg-cleanup-script.sh
    ```

The script will list all the keys that are either expired or have an unknown validity. It will then prompt you for confirmation before deleting them.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
