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
  call sbcom2#isword() " 初始化全局变量
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
  let regular = sbcom2#insert(theword) " 正则表达式
  "==获取全文==
  let linetotal = len(getline(1, 2000))
  let i = 1
  let g:sbcom2_alltext = ""
  while (i <= linetotal)
    let g:sbcom2_alltext = g:sbcom2_alltext . getline(i)
    let i += 1
  endwhile
  "==分割单词==
  let wordtemp = ""
  let g:sbcom2_allword = []
  for i in g:sbcom2_alltext
    if (sbcom2#exist(i, g:sbcom2_isword) == 1)
      let wordtemp = wordtemp . i
    else
      if (match(wordtemp, regular) != -1)
        let g:sbcom2_matched += [wordtemp]
      endif
      let wordtemp = ""
    endif
  endfor
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

