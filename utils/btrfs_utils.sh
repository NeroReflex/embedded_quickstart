#!/bin/bash

# Check if the given directory is a btrfs subvolume
# $1 the directory
# return 0 if the directory is a subvolume, 1 otherwise
is_btrfs_subvolume() {
	local dir=$1
	[ "$(stat -f --format="%T" "$dir")" == "btrfs" ] || return 1
	inode="$(stat --format="%i" "$dir")"
	case "$inode" in
	2 | 256)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

# Ensure the subvolume is in RW state
# PRE=
# POST=the directory is a btrfs subvolume in RW state
# $1 the subvolume to be changed
# stdout "OK" on success, an error string otherwise
btrfs_subvolume_set_rw() {
	local dir=${1}

	if is_btrfs_subvolume "$dir"; then
		local lock_state=$(btrfs property get -fts "$dir")
		if [[ $lock_state == *"ro=true"* ]]; then
			if btrfs property set -fts ${dir} ro false; then
				local lock_state_after_set=$(btrfs property get -fts "$dir")
				if [[ $lock_state_after_set == *"ro=false"* ]]; then
					echo "OK"
				else
					echo "ERROR: The subvolume '$dir' is still read-only"
				fi
			else
				echo "ERROR: Could not set subvolume '$dir' read-write"
			fi
		else
			echo "OK"
		fi
	else
		echo "ERROR: the given argument '$dir' is not a btrfs subvolume"
	fi
}

# Ensure the subvolume is in RO state
#
# PRE=the directory is a btrfs subvolume
# POST=the directory is a btrfs subvolume in RO state
#
# $1 the subvolume to be changed
# stdout "OK" on success, an error string otherwise
btrfs_subvolume_set_ro() {
	local dir=${1}

	if is_btrfs_subvolume "$dir"; then
		local lock_state=$(btrfs property get -fts "$dir")
		if [[ $lock_state == *"ro=false"* ]]; then
			if btrfs property set -fts ${dir} ro true; then
				local lock_state_after_set=$(btrfs property get -fts "$dir")
				if [[ $lock_state_after_set == *"ro=true"* ]]; then
					echo "OK"
				else
					echo "ERROR: The subvolume '$dir' is still read-write"
				fi
			else
				echo "ERROR: Could not set subvolume '$dir' read-only"
			fi
		else
			echo "OK"
		fi
	else
		echo "ERROR: the given argument '$dir' is not a btrfs subvolume"
	fi
}

# Get the btrfs subvolume id of the given subvolume path
#
# PRE=$1 is a btrfs subvolume
# POST=
#
# $1 the subvolume to be inspected
# stdout SubvolID on success, an error string otherwise
btrfs_subvol_get_id() {
	local dir=${1}

	if is_btrfs_subvolume "$dir"; then
		local subvolid=$(btrfs subvolume show $dir | grep "Subvolume ID:" | cut -d ':' -f 2 | tr -d '[:space:]')
		local result=$?

		echo "$subvolid"

        return $result
	else
		echo "ERROR: $dir is not a valid btrfs subvolume"

        return -1
	fi
}
