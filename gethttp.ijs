NB. =========================================================
NB. J interface for Wget/cURL to retrieve files using http, ftp, https

require '~system\packages\misc\task.ijs'

coclass 'wgethttp'

IFCURL=: IFUNIX *. UNAME-:'Darwin'
HTTPCMD=: (jpath '~tools/ftp/')&,^:(-.IFUNIX) 'wget'
HTTPCMD=: IFCURL{:: HTTPCMD;'curl'

3 : 0 ''
  if. IFUNIX do.   NB. fix task.ijs definition of spawn on mac/unix
    spawn=: [: 2!:0 '(' , ' || true)' ,~ ]
  end.
  ''
)

NB.*gethttp v Retrieve URI using Wget/cURL tools
NB. [option] gethttp uri
NB. result: depends on options, Default is URI contents
NB. y is: URI to retrieve
NB. x is: Optional retrieval options. One of:
NB.       'stdout' (Default)
NB.       'help'
NB.       'file' or ('file';jpath '~temp/myfile.htm')
NB.       Anything else is assumed to be a valid Wget/cURL option string
NB. eg: 'file' gethttp 'http://www.jsoftware.com'
NB. eg: ('-o - --stderr ',jpath '~temp/gethttp.log') gethttp 'http://www.jsoftware.com'
gethttp=: 3 : 0
  'stdout' gethttp y
:
  url=. y
  'jopts fnme'=. 2{. boxopen x
  select. jopts
  case. 'stdout' do.  NB. content retrieved from stdout, log suppressed
    opts=. IFCURL{:: '-O - -q';'-o - -s -S'
  case. 'file' do. 
    if. #fnme do.     NB. save as filename
      opts=. IFCURL{:: '-O ';'-o '
      opts=. opts,fnme
    else.             NB. copy file to current dir
      opts=. IFCURL{:: ' ';'-O'
    end.
  case. 'help' do.    NB. help
    opts=. '--help'
  case. do.           NB. custom option string?
    if. 2 131072 e.~ 3!:0 x do. opts=. x
    else. 'Invalid left argument for getHTTP' return. end.
  end.
  opts=. ' ',opts,' '
  spawn HTTPCMD , opts , url
)

NB. =========================================================
NB. Export z locale

gethttp_z_ =: gethttp_wgethttp_
