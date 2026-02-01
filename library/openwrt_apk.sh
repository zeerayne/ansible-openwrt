#!/bin/sh
# GNU General Public License v3.0 (see https://www.gnu.org/licenses/gpl-3.0.txt)

PARAMS="
    name=pkg/str/r
    state/str//present
    force/str
    update_cache/bool
"

query_package() {
    apk info -e "$1" >/dev/null 2>&1
}

install_packages() {
    local _IFS pkg
    _IFS="$IFS"; IFS=","; set -- $name; IFS="$_IFS"
    for pkg; do
        ! query_package "$pkg" || continue
        [ -n "$_ansible_check_mode" ] || {
            try apk add$force "$pkg"
            query_package "$pkg" || fail "failed to install $pkg: $_result"
        }
        changed
    done
}

remove_packages() {
    local _IFS pkg
    _IFS="$IFS"; IFS=","; set -- $name; IFS="$_IFS"
    for pkg; do
        query_package "$pkg" || continue
        [ -n "$_ansible_check_mode" ] || {
            try apk del$force "$pkg"
            ! query_package "$pkg" || fail "failed to remove $pkg: $_result"
        }
        changed
    done
}

main() {
    case "$state" in
        present|installed|absent|removed) :;;
        *) fail "state must be present or absent";;
    esac
    [ -z "$force" ] || {
        case "$force" in
            overwrite|broken-world|refresh|non-repository|binary-stdout) :;;
            *) fail "unknown force option: $force";;
        esac
        force=" --force-$force"
    }

    [ -z "$update_cache" -o -n "$_ansible_check_mode" ] || try apk update
    case "$state" in
        present|installed) install_packages;;
        absent|removed) remove_packages;;
    esac
}
