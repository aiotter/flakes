EMPTY_COMMIT := 242b9994083b723eef46c7f6b1d7b7fbd4a76eab
IF_EXIST = git show-ref --verify --quiet "refs/heads/$@"

%::
# Branch already exists
	@if $(IF_EXIST); then \
		git worktree add "$@" "refs/heads/$@"; \
	fi
# Branch does not exist
	@if ! $(IF_EXIST); then \
		git worktree add --detach "$@" $(EMPTY_COMMIT) && git -C "$@" checkout --orphan="$@"; \
	fi
