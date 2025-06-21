# GPG Cleanup Script

A script to safely find and delete expired or unknown GPG keys from your keyring.

It is designed with safety and clarity in mind, providing a clear summary of its findings before taking any action.

## Features

-   **Safety First:** Runs in a "dry run" mode by default. No keys are deleted without the explicit `--delete` flag.
-   **Clarity:** Provides a color-coded summary of its analysis:
    -   **Green:** Valid keys that will be retained.
    -   **Red:** Expired or unknown keys that are flagged for deletion.
-   **Human-Readable:** Displays full User IDs (name, email, comment) for all keys, not just cryptic IDs.

## Usage

1.  **Make the script executable:**
    ```bash
    chmod +x gpg-cleanup-script.sh
    ```

2.  **Perform a Dry Run:**
    ```bash
    ./gpg-cleanup-script.sh
    ```
    Review the color-coded output to see which keys will be retained and which are flagged for deletion.

3.  **Delete the Keys:**
    Once you are confident in the dry run's output, run the script with the `--delete` flag:
    ```bash
    ./gpg-cleanup-script.sh --delete
    ```
    You will be shown the same summary and asked for a final confirmation before any keys are deleted.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
