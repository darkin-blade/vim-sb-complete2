" 全部单词
let g:sbcom2_allword = []
" 全文
let g:sbcom2_alltext = []
" 全部匹配的单词
let g:sbcom2_matched = []
" 临时修正的单词
let g:sbcom2_fixed = []
" 算进单词的部分,不包括中文字符
let g:sbcom2_isword = []
" 不算进单词的部分
let g:sbcom2_issplit = ""
" 下一个切换的单词
let g:sbcom2_wordnth = 0
" 总共匹配数
let g:sbcom2_wordnum = 0
" 判断当前单词是否有效
let g:sbcom2_rightspell = 0 
" 判断是否能够进行正常匹配
let g:sbcom2_canmatch = 0 
" 判断是否已经进行超前匹配
let g:sbcom2_hasmatch = 0 
" 实时位置
let g:sbcom2_textposition = 0

fun! sbcom2#isword()
  if (&filetype == "vim") " 特判vim格式,把#算进单词
    let g:sbcom2_isword = "[0-9a-zA-Z:_#]"
    let g:sbcom2_issplit = ["`", "\\~", "!", "@", "\\$", "%", "\\^", "&", "*", "(", ")", "-", "=", "+", "[", "{", "]", "}", "\\", "|", ";", "\'", "\"", ",", "<", "\\.", ">", "/", "?", " ", "\t", "\n"]
  else
    let g:sbcom2_isword = "[0-9a-zA-Z:_]"
    let g:sbcom2_issplit = ["`", "\\~", "!", "@", "#", "\\$", "%", "\\^", "&", "*", "(", ")", "-", "=", "+", "[", "{", "]", "}", "\\", "|", ";", "\'", "\"", ",", "<", "\\.", ">", "/", "?", " ", "\t", "\n"]
  endif
endfun

fun! sbcom2#insert(word) " 将单词改成正则表达式
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

fun! sbcom2#match(elem, lists)
  for i in a:lists
    if (match(a:elem, i) != -1)
      return 1
    endif
  endfor
  return 0
endfun

fun! sbcom2#find() " 主函数
  "==获取目前单词==
  call sbcom2#isword() " 初始化全局变量
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
  let regular = sbcom2#insert(theword) " 正则表达式
  "==切换单词==
  for i in g:sbcom2_matched
    if (i == theword)
      let g:sbcom2_wordnth += 1
      let g:sbcom2_wordnth = g:sbcom2_wordnth % g:sbcom2_wordnum " 循环
      call sbcom2#replace(thelen, thetail)
      return []
    endif
  endfor
  "==特殊变量==
  let g:sbcom2_textposition = 0 " 全文实时位置
  let g:sbcom2_rightspell = 0 " 判断当前单词是否有效
  let g:sbcom2_canmatch = 0 " 判断是否能够进行正常匹配
  let g:sbcom2_hasmatch = 0 " 判断是否已经进行超前匹配
  let g:sbcom2_matched = [] " 清空之前匹配的单词
  let g:sbcom2_fixed = [] " 清空之前匹配的单词
  let g:sbcom2_alltext = ""
  "==获取全文==
  let linenum = len(getline(1, 2000)) " 全文长度
  let lineup = line(".") " 向上增加行数
  let linedown = line(".") + 1 " 向下增加行数
  while ((lineup >= 1)||(linedown <= linenum)) " 按就近添加行
    if (lineup >= 1)
      let g:sbcom2_alltext = g:sbcom2_alltext . getline(lineup) . " "
    endif
    if (linedown <= linenum)
      let g:sbcom2_alltext = g:sbcom2_alltext . getline(linedown) . " "
    endif
    if (linedown - lineup > g:sbcom2_maxline) " 行数上限
      break
    endif
    call sbcom2#realtime(thelen, theword, regular, thetail)
    let lineup -= 1
    let linedown += 1
  endwhile
  "==更正模式==
  if (len(g:sbcom2_matched) == 0) " 开启更正模式
    let g:sbcom2_matched = g:sbcom2_fixed
  endif
  let g:sbcom2_wordnum = len(g:sbcom2_matched)
  if ((g:sbcom2_hasmatch == 0)&&(len(g:sbcom2_matched) != 0))
    call sbcom2#replace(thelen, thetail)
  endif
  return []
endfun

fun! sbcom2#realtime(thelen, theword, regular, thetail)
  let textlen = len(g:sbcom2_alltext) " 实时的全文长度
  let wordtemp = ""
  while (g:sbcom2_textposition < textlen)
    let thechar = g:sbcom2_alltext[g:sbcom2_textposition]
    if (match(thechar, g:sbcom2_isword) != -1) " 是单词字符
      let wordtemp = wordtemp . thechar " 添加到单词
    else
      if ((sbcom2#exist(wordtemp, g:sbcom2_matched) == 0)&&(match(wordtemp, a:regular) == 0)) " 没重复,匹配成功,普通模式
        if (wordtemp != a:theword) " 非当前单词
          let g:sbcom2_canmatch = 1
          let g:sbcom2_matched += [wordtemp]
        else " 等于当前单词
          if (g:sbcom2_rightspell == 0) " 第一次匹配
            let g:sbcom2_rightspell = 1 " 进行标记
          else " 该单词是正确的单词
            let g:sbcom2_canmatch = 1
            let g:sbcom2_matched += [wordtemp]
          endif
        endif
      elseif ((sbcom2#exist(wordtemp, g:sbcom2_fixed) == 0)&&(g:sbcom2_canmatch == 0)) " 开启修正(正常匹配为空时才能触发)
        let canfix = 1
        let j = 0
        while (j < a:thelen)
          if (match(wordtemp, a:theword[j]) == -1)
            let canfix = 0
            break " 更正失败
          endif
          let j += 1
        endwhile
        if (canfix == 1) " 字母全部在该单词中
          let g:sbcom2_fixed += [wordtemp]
        endif
      endif
      if ((g:sbcom2_canmatch == 1)&&(g:sbcom2_hasmatch == 0)) " 超前匹配
        let g:sbcom2_hasmatch = 1
        let g:sbcom2_wordnth = 0
        call sbcom2#replace(a:thelen, a:thetail)
      endif
      let wordtemp = ""
    endif
    let g:sbcom2_textposition += 1
  endwhile
endfun

fun! sbcom2#replace(thelen, thetail)
  call cursor([line("."), a:thetail + 2])
  call complete(col(".") - a:thelen, [g:sbcom2_matched[g:sbcom2_wordnth]])
endfun

