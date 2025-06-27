#!/usr/bin/env python3

import sys
import datetime
from git_filter_repo import FilterRepo

start_date = datetime.datetime(2024, 4, 5, 12, 0, 0)
end_date = datetime.datetime.now().replace(hour=12, minute=0, second=0, microsecond=0)

def main():
    repo = FilterRepo()

    commits = list(repo.commits)
    total = len(commits)
    if total == 0:
        print("No commits found. Exiting.")
        sys.exit(1)

    delta = (end_date - start_date).total_seconds()

    # Assign new dates evenly spaced
    for i, commit in enumerate(reversed(commits)):
        offset_seconds = int(i * delta / (total - 1)) if total > 1 else 0
        new_date = start_date + datetime.timedelta(seconds=offset_seconds)
        new_date_str = new_date.strftime("%Y-%m-%dT%H:%M:%S")

        # Set new author and committer dates
        commit.author_date = int(new_date.timestamp())
        commit.author_tz_offset = 0  # UTC
        commit.committer_date = int(new_date.timestamp())
        commit.committer_tz_offset = 0  # UTC

    repo.commit_filter = lambda commit: commit  # Keep all commits
    repo.run()

if __name__ == "__main__":
    main()
