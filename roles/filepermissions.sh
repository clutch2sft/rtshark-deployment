#!/bin/bash
WATCHED_DIR="/path/to/tshark/output/files"

inotifywait -m -e close_write --format '%w%f' "${WATCHED_DIR}" | while read NEWFILE
do
    # Check if the file is not being written to by lsof command
    if ! lsof "${NEWFILE}" > /dev/null; then
        chmod 644 "${NEWFILE}"
    fi
done
