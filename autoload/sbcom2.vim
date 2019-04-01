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
" let g:sbcom2_rightspell = 0 
" 判断是否能够进行正常匹配
" let g:sbcom2_canmatch = 0 
" 判断是否已经进行超前匹配
" let g:sbcom2_hasmatch = 0 
" 实时位置
" let g:sbcom2_textposition = 0
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
  let thehead = col(".") - 2
  let thetail = thehead
  let linelen = len(getline(line(".")))
  while ((match(theline[thehead], g:sbcom2_isword) != -1)&&(thehead >= 0))
    let thehead -= 1
  endwhile
  while ((match(theline[thetail], g:sbcom2_isword) != -1)&&(thetail <= linelen))
    let thetail += 1
  endwhile
  let thehead += 1
  let thetail -= 1
  let theword = theline[thehead:thetail]
  let thelen = len(theword)
  if (thelen == 0)
    echom "invalid --sbcom2"
    return []
  endif
  let regular = sbcom2#regular(theword) " 正则表达式
  "==实时加载==
  if (g:sbcom2_loading == 0) " 第一次加载
    let g:sbcom2_loading = 1
    let g:sbcom2_up = line(".")
    let g:sbcom2_down = line(".") + 1
    let g:sbcom2_linenum = len(getline(0, 10000))
  endif
  "==loading == 1==
  if (g:sbcom2_up >= 1)
    let g:sbcom2_alltext = g:sbcom2_alltext . getline(g:sbcom2_up)
    let g:sbcom2_up -= 1
  endif
  if (g:sbcom2_down <= g:sbcom2_linenum)
    let g:sbcom2_alltext = g:sbcom2_alltext . getline(g:sbcom2_down)
    let g:sbcom2_down += 1
  endif
  if ((g:sbcom2_up <= 1)&&(g:sbcom2_down >= g:sbcom2_linenum))
    let g:sbcom2_loaded = 1 " 全文加载完毕
  endif
  return []
endfun

fun! sbcom2#replace(thelen, thetail)
  call cursor([line("."), a:thetail + 2])
  call complete(col(".") - a:thelen, [g:sbcom2_matched[g:sbcom2_wordnth]])
  echom "match"
endfun

