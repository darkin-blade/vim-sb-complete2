" 全文
" let g:sbcom2_alltext = []
" 全部匹配的单词
let g:sbcom2_matched = []
" 临时修正的单词
" let g:sbcom2_fixed = []
" 算进单词的部分,不包括中文字符
" let g:sbcom2_isword = []
" 不算进单词的部分
" let g:sbcom2_issplit = []
" 下一个切换的单词
let g:sbcom2_wordnth = 0
" 总共匹配数
let g:sbcom2_wordnum = 0
" 判断当前单词是否有效
" let g:sbcom2_spell = 0 
" 判断是否能够进行正常匹配
" let g:sbcom2_canmatch = 0 
" 判断是否已经进行超前匹配
" let g:sbcom2_hasmatch = 0 
" 实时位置
" let g:sbcom2_position = 0
" 是否正在搜索
let g:sbcom2_loading = 0
" 全文是否搜遍
let g:sbcom2_loaded = 0

fun! sbcom2#init()
  if (&filetype == "vim") " 特判vim格式,把#算进单词
    let g:sbcom2_isword = "[0-9a-zA-Z:_#]"
    let g:sbcom2_issplit = ["`", "\\~", "!", "@", "\\$", "%", "\\^", "&", "*", "(", ")", "-", "=", "+", "[", "{", "]", "}", "\\", "|", ";", "\'", "\"", ",", "<", "\\.", ">", "/", "?", " ", "\t", "\n"]
  else
    let g:sbcom2_isword = "[0-9a-zA-Z:_]"
    let g:sbcom2_issplit = ["`", "\\~", "!", "@", "#", "\\$", "%", "\\^", "&", "*", "(", ")", "-", "=", "+", "[", "{", "]", "}", "\\", "|", ";", "\'", "\"", ",", "<", "\\.", ">", "/", "?", " ", "\t", "\n"]
  endif
endfun

fun! sbcom2#regular(word) " 将单词改成正则表达式
  let theword = a:word
  let thelen = len(theword)
  let i = thelen - 1
  while i >= 0
    let theword = theword[0:i] . "\.*" . theword[i + 1:len(theword) - 1] " 从第一个字母到最后一个字母全部增加正则表达式
    let i -= 1
  endwhile
  return theword
endfun

fun! sbcom2#exist(elem, lists)
  for i in a:lists
    if (a:elem == i)
      return 1
    endif
  endfor
  return 0
endfun

fun! sbcom2#find() " 主函数
  "==获取目前单词==
  call sbcom2#init() " 初始化单词和非单词
  let theline = getline(line("."))
  let g:sbcom2_thehead = col(".") - 2
  let g:sbcom2_thetail = g:sbcom2_thehead
  let linelen = len(getline(line(".")))
  while ((match(theline[g:sbcom2_thehead], g:sbcom2_isword) != -1)&&(g:sbcom2_thehead >= 0))
    let g:sbcom2_thehead -= 1
  endwhile
  while ((match(theline[g:sbcom2_thetail], g:sbcom2_isword) != -1)&&(g:sbcom2_thetail <= linelen))
    let g:sbcom2_thetail += 1
  endwhile
  let g:sbcom2_thehead += 1
  let g:sbcom2_thetail -= 1
  let g:sbcom2_theword = theline[thehead:thetail]
  let g:sbcom2_thelen = len(g:sbcom2_theword)
  if (g:sbcom2_thelen == 0)
    echom "invalid --sbcom2"
    return []
  endif
  "==实时加载==
  if (len(g:sbcom2_theword) == 0) " 新的单词
    call sbcom2#reset()
    call sbcom2#add()
  elseif (g:sbcom2_theword == g:sbcom2_matched[g:sbcom2_wordnth]) " 上一个单词
    call sbcom2#add()
  else " 不同的单词
    call sbcom2#reset()
    call sbcom2#add()
  endif
  "==判断是否开启更正模式==
  if (len(g:sbcom2_matched) == 0)
    let g:sbcom2_matched = g:sbcom2_fixed
  endif
  return []
endfun

fun! sbcom2#add()
  while (g:sbcom2_loaded == 0)
    if (g:sbcom2_up >= 1)
      let g:sbcom2_alltext = g:sbcom2_alltext . getline(g:sbcom2_up)
      let g:sbcom2_up -= 1
    endif
    if (g:sbcom2_down <= g:sbcom2_linenum)
      let g:sbcom2_alltext = g:sbcom2_alltext . getline(g:sbcom2_down)
      let g:sbcom2_down += 1
    endif
    if (sbcom2#match() == 1)
      call sbcom2#replace() " 一旦找到匹配或者搜索完成就进行补全
      return 1
    endif
    if ((g:sbcom2_up <= 1)&&(g:sbcom2_down >= g:sbcom2_linenum))
      let g:sbcom2_loaded = 1 " 全文加载完毕
    endif
  endwhile
endfun

fun! sbcom2#match()
  let wordtemp = ""
  let textlen = len(g:sbcom2_alltext)
  while (g:sbcom2_position < textlen)
    let thechar = g:sbcom2_alltext[g:sbcom2_position] " 按字符匹配
    if (match(thechar, g:sbcom2_isword) != -1) " 是单词字符
      let wordtemp = wordtemp . thechar
    else " 非单词字符,清空单词
      if ((match(wordtemp, g:sbcom2_regular) == 0)&&(sbcom2#exist(wordtemp, g:sbcom2_matched) == 0)) " 匹配成功且不重复
        if ((wordtemp != g:sbcom2_theword)||(g:sbcom2_spell == 1)) " 非当前单词,或拼写正确
          let g:sbcom2_matched += [wordtemp]
          let g:sbcom2_wordnth += 1
          return 1
        else
          let g:sbcom2_spell = 1 " 进行记录
        endif
      elseif ((sbcom2#exist(wordtemp, g:sbcom2_fixed) == 0)&&(g:sbcom2_linenum <= 300)) " 暂未匹配成功且不重复
        let canfix = 1
        let i = 0
        while (i < g:sbcom2_thelen)
          if (match(wordtemp, g:sbcom2_theword[i]) == -1) " 更正失败
            let canfix = 0
            break
          endif
          let i += 1
        endwhile
        if (canfix == 1) " 可以更正
          let g:sbcom2_fixed += [wordtemp]
        endif
      endif
      let wordtemp = ""
    endif
    let g:sbcom2_position += 1
  endwhile
  return 0
endfun

fun! sbcom2#replace()
  call cursor([line("."), g:sbcom2_thetail + 2])
  call complete(col(".") - g:sbcom2_thelen, [g:sbcom2_matched[g:sbcom2_wordnth]])
endfun

fun! sbcom2#reset()
  let g:sbcom2_regular = sbcom2#regular(g:sbcom2_theword) " 正则表达式
  let g:sbcom2_up = line(".")
  let g:sbcom2_down = line(".") + 1
  let g:sbcom2_linenum = len(getline(0, 10000))
  let g:sbcom2_matched = []
  let g:sbcom2_fixed = []
  let g:sbcom2_spell = 0 " 判断当前单词是否有效
endfun
