EMPTY_COMMIT := 242b9994083b723eef46c7f6b1d7b7fbd4a76eab
IF_FETCHED = git show-ref --verify --quiet "refs/heads/$@" >/dev/null 2>&1
IF_EXIST_ON_ORIGIN = git ls-remote --quiet --heads --exit-code origin "refs/heads/$@" >/dev/null 2>&1

.PHONY: prune list

prune:
	git worktree prune

list:
	@# Remove "refs/heads/" with awk
	@git ls-remote --quiet --heads --exit-code origin | awk '{ print substr($$2, 12) }'

%::
	@if $(IF_FETCHED); then \
		git worktree add "$@" "$@"; \
	else \
		$(IF_EXIST_ON_ORIGIN); case $$? in \
		0 ) \
			git fetch origin "refs/heads/$@"; \
			git worktree add --track -b "$@" "$@" "origin/$@"; \
			;; \
		1 ) \
			echo >2 "Failed to connect to the remote"; exit 1;; \
		2 ) \
			echo "No matching remote branch; creating new one..."; \
			git worktree add --detach "$@" $(EMPTY_COMMIT) && git -C "$@" checkout --orphan="$@";; \
		esac \
	fi
