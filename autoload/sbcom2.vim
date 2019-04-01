" 全部单词
let g:sbcom2_alltext = []
" 全部匹配的单词
let g:sbcom2_matched = []
" 算进单词的部分,不包括中文字符
let g:sbcom2_isword = []
" 不算进单词的部分
let g:sbcom2_issplit = ""
" 下一个切换的单词
let g:sbcom2_wordnth = 0
" 总共匹配数
let g:sbcom2_wordnum = 0

fun! sbcom2#isword()
  if (&filetype == "vim") " 特判vim格式,把#算进单词
    let g:sbcom2_isword = ["[0-9a-zA-Z:_#]"]
    let g:sbcom2_issplit = ["`", "\\~", "!", "@", "\\$", "%", "\\^", "&", "*", "(", ")", "-", "=", "+", "[", "{", "]", "}", "\\", "|", ";", "\'", "\"", ",", "<", "\\.", ">", "/", "?", " ", "\t", "\n"]
  else
    let g:sbcom2_isword = ["[0-9a-zA-Z:_]"]
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
  call sbcom2#isword()
  let theline = getline(line("."))
  let thehead = col(".") - 2
  let thetail = thehead
  while ((sbcom2#match(theline[thehead], g:sbcom2_isword) == 1)&&(thehead >= 0))
    let thehead -= 1
  endwhile
  while ((sbcom2#match(theline[thetail], g:sbcom2_isword) == 1)&&(thetail <= len(getline(line(".")))))
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
  "==切换单词==
  for i in g:sbcom2_matched " g:sbcom2_wordnum不能为0
    if (i == theword) " 单词已经匹配过
      let g:sbcom2_wordnth += 1
      let g:sbcom2_wordnth = g:sbcom2_wordnth%g:sbcom2_wordnum " 循环
      call sbcom2#replace(thelen, thetail)
      return []
    endif
  endfor
  let theregular = sbcom2#insert(theword)
  "==获取全部单词==
  let lineup = line(".")
  let linedown = line(".") + 1
  let g:sbcom2_alltext = []
  let textlen = len(getline(0, 1000))
  while ((lineup >= 1)||(linedown <= textlen)) " 按就近添加行
    if (lineup >= 1)
      let g:sbcom2_alltext += getline(lineup, lineup)
    endif
    if (linedown <= textlen)
      let g:sbcom2_alltext += getline(linedown, linedown)
    endif
    let lineup -= 1
    let linedown += 1
    if (len(g:sbcom2_alltext) > g:sbcom2_maxline)
      break
    endif
  endwhile
  let alltext_temp = g:sbcom2_alltext 
  for j in g:sbcom2_issplit
    let g:sbcom2_alltext = []
    for i in alltext_temp
      let g:sbcom2_alltext += split(i, j)
    endfor  
    let alltext_temp = g:sbcom2_alltext  
  endfor 
  "==单词去重==
  let alltext_temp = g:sbcom2_alltext
  let g:sbcom2_alltext = []
  let rightspell = -1 " 如果为1,说明是正确的单词
  for i in alltext_temp
    if (i == theword) " 相同单词
      let rightspell += 1
      continue
    endif
    if (sbcom2#exist(i, g:sbcom2_alltext))
      continue
    endif
    let g:sbcom2_alltext += [i]
  endfor
  "==单词匹配==
  let g:sbcom2_wordnth = 0
  let g:sbcom2_wordnum = 0
  let g:sbcom2_matched = [] " 匹配的单词组成的list,清空
  for i in g:sbcom2_alltext
    if (match(i, theregular) == 0) " 找到正则匹配
      if (theword == i) " 相同单词
        continue
      endif
      call add(g:sbcom2_matched, i)
    endif
  endfor
  if (rightspell >= 1) " 目前的单词是有效的
    call add(g:sbcom2_matched, theword)
  endif
  let g:sbcom2_wordnum = len(g:sbcom2_matched)
  if (g:sbcom2_wordnum == 0)
    call sbcom2#fix(theword, thelen, thetail)
  else
    call sbcom2#replace(thelen, thetail)
  endif
  return ""
endfun

fun! sbcom2#replace(thelen, thetail)
  call cursor([line("."), a:thetail + 2])
  call complete(col(".") - a:thelen, [g:sbcom2_matched[g:sbcom2_wordnth]])
endfun

fun! sbcom2#fix(theword, thelen, thetail)
  for i in g:sbcom2_alltext
    let allin = 1 " 是否有匹配的flag
    let j = 0
    while j < len(a:theword)
      if (match(i, a:theword[j]) == -1) " 比较所有字母是否存在于另一个单词中
        let allin = 0 " 匹配失败
        break
      endif
      let j += 1
    endwhile
    if ((allin == 1)&&(i != a:theword))
      if (len(g:sbcom2_matched) == 0) " 第一个匹配
        let g:sbcom2_matched = [i]
        let g:sbcom2_wordnum = 1
      else
        if (i != g:sbcom2_matched[len(g:sbcom2_matched) - 1]) " 后面的匹配
          let g:sbcom2_matched += [i]
          let g:sbcom2_wordnum += 1
        endif
      endif
    endif
  endfor
  if (len(g:sbcom2_matched)!= 0)
    call sbcom2#replace(a:thelen, a:thetail) " 再次调用删除,插入函数
  endif
endfun

