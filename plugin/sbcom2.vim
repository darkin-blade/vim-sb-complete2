if (exists('g:sbcom2_active')&&(g:sbcom2_active != 0)) " 启动插件
  if (exists('g:sbcom2_trigger')) " 有自定义按键
    au BufEnter * execute("inoremap ".g:sbcom2_trigger." <c-r>=sbcom2#find()<cr>")
  else " 没有自定义按键
    au BufEnter * execute("inoremap <tab> <c-r>=sbcom2#find()<cr>")
  endif
  if (!exists('g:sbcom2_maxline')) " 有自定义最大长度
    let g:sbcom2_maxline = 2000
  endif
endif

" 关闭插件
command! Sbcom2Off call Sbcom2Toggle(0)
" 开启插件
command! Sbcom2On call Sbcom2Toggle(1)

fun! Sbcom2Toggle(para)
  if (a:para == 0) " 关闭插件
    if (exists('g:sbcom2_trigger')) " 有自定义按键
      execute("iunmap ".g:sbcom2_trigger)
    else " 没有自定义按键
      execute("iunmap <tab>")
    endif
  else
    if (exists('g:sbcom2_trigger'))
      execute("inoremap ".g:sbcom2_trigger." <c-r>=sbcom2#find()<cr>")
    else
      execute("inoremap <tab> <c-r>= sbcom2#find()<cr>")
    endif
  endif
endfun
