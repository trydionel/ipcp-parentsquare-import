# IPCP ParentSquare import tools

## ParentSquare SFTP Data Sync instructions

[Instructions from ParentSquare](https://parentsquare.zendesk.com/hc/en-us/articles/115002279443-Data-Upload-Sync-SFTP-Data-Sync)

## Process

1. Collect latest reports from ProCare into one directory
2. Run the clean script: `ruby ./clean.rb <input directory>`
3. Watch for messages indicating incomplete data, especially in mapping
   teachers to classrooms. Reach out to school administration to help fill in
   the gaps if needed.
4. Transfer the files in `./output` to ParentSquare via SFTP.
