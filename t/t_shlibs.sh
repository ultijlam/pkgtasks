# $NetBSD$
#
# Copyright (c) 2017 The NetBSD Foundation, Inc.
# All rights reserved.
#
# This code is derived from software contributed to The NetBSD Foundation
# by Johnny C. Lam.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE NETBSD FOUNDATION, INC. AND CONTRIBUTORS
# ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

task_load createfile
task_load shlibs
task_load unittest

test_setup()
{
	: ${GREP:=grep}
	: ${MV:=mv}

	: ${PKGNAME:=${0##*/}}

	dbfile="shlibs"
	dbfile_tmp="$dbfile.tmp.$$"
	task_createfile "$dbfile"
}

# Mock ldconfig that just toggles between adding and removing ${PKGNAME}
# from a flat text file.
#
ldconfig()
{
	if ${GREP} -q "^${PKGNAME}$" < $dbfile; then
		${GREP} -v "${PKGNAME}" < $dbfile > $dbfile_tmp
		${MV} -f "$dbfile_tmp" "$dbfile"
	else
		echo "${PKGNAME}" >> $dbfile
	fi
	return 0
}

test1()
{
	describe="add with empty cache"
	if task_shlibs add; then
		: "success"
	else
		return 1
	fi
	if ${GREP} -q "${PKGNAME}" "$dbfile"; then
		: "success"
	else
		describe="$describe: not in $dbfile!"
		return 1
	fi
	return 0
}

test2()
{
	describe="remove after adding to cache"
	task_shlibs add
	if task_shlibs remove; then
		: "success"
	else
		return 1
	fi
	if ${GREP} -q "${PKGNAME}" "$dbfile"; then
		describe="$describe: still in $dbfile!"
		return 1
	fi
	return 0
}

task_run_tests "$@"
