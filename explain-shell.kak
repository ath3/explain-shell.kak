declare-option -docstring "name of the client in which documentation is to be displayed" \
    str docsclient
declare-option -hidden int explain_shell_cols

define-command -docstring "Explain the selected shell command (online api)" explain-shell %{ try %{
    evaluate-commands -try-client %opt{docsclient} %{
        set-option global explain_shell_cols %val{window_width}
    }
    evaluate-commands %sh{
        sel=$(echo ${kak_selection} | sed 's/^[ \t\v\f]*//;s/[ \t\v\f]*$//')
        sel_len=$(echo -n ${sel} | wc -m)
        if [ ${sel_len} -gt 1 ]; then
            expl=$(mktemp "${TMPDIR:-/tmp}"/kak-explain-shell-XXXXXX)
            cols=$((${kak_opt_explain_shell_cols}-5))
            curl -Gs "https://www.mankier.com/api/explain/?cols=${cols}" \
                --data-urlencode "q=${sel}" -o ${expl}
            retval=$?
            if [ "${retval}" -eq 0 ]; then
                  printf %s\\n "evaluate-commands -try-client '${kak_opt_docsclient}' %{
                      edit -scratch *explain-shell*
                      execute-keys 'gjo${sel}<ret>${sel}<esc><a-h>r=;d<a-o>j|cat<space>${expl}<ret>gj'
                      nop %sh{rm -f ${expl}}
                  }"
            else
              printf %s\\n "
                  echo -markup %{{Error}explain-shell '${sel}' failed: see *debug* buffer for details}
                  nop %sh{rm -f ${expl}}
              "
            fi
        fi
    }
}}
