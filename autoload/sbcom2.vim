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
  "==获取全文==
  let linenum = len(getline(1, 2000))
  let lineup = line(".")
  let linedown = line(".") + 1
  let g:sbcom2_alltext = ""
  while ((lineup >= 1)||(linedown <= linenum)) " 按就近添加行
    if (lineup >= 1)
      let g:sbcom2_alltext = g:sbcom2_alltext . getline(lineup) . " "
    endif
    if (linedown <= linenum)
      let g:sbcom2_alltext = g:sbcom2_alltext . getline(linedown) . " "
    endif
    let lineup -= 1
    let linedown += 1
  endwhile
  "==分割单词==
  let g:sbcom2_matched = [] " 清空之前匹配的单词
  return []
  let textlen = len(g:sbcom2_alltext)
  let rightspell = 0
  let i = 0
  let wordtemp = ""
  while (i < textlen)
    let thechar = g:sbcom2_alltext[i]
    for j in ["j"]
      if (match(thechar, g:sbcom2_isword) != -1) " 是单词字符
        let wordtemp = wordtemp . thechar " 添加到单词
      else " 非单词
        if (sbcom2#exist(wordtemp, g:sbcom2_matched) == 1) " 已经存在
          continue " 跳过
        endif
        if (match(wordtemp, regular) != 0) " 头部匹配成功
          if (wordtemp == theword) " 等于当前单词
            if (rightspell == 0) " 第一次匹配
              let rightspell = 1 " 进行标记
            else " 该单词是正确的单词
              let g:sbcom2_matched += [wordtemp]
            endif
          else " 非当前单词
            let g:sbcom2_matched += [wordtemp]
          endif
        endif
      endif
    endfor
    let wordtemp = ""
    let i += 1
  endwhile
  return []
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

