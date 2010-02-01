NB. =========================================================
NB. web/gethttp
NB. J interface for Wget/cURL to retrieve files using http, ftp, https

require 'task strings'

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

NB. ---------------------------------------------------------
NB. Utility verbs
safe=. (33}.127{.a.)-.'=&%+'
encode=:  [: toupper ('%',(I.'6'=,3!:3'f') {&, 3!:3)
nvp=: >@{.,'=',urlencode@":@>@{:
args=: [: }.@; ('&'<@,nvp)"1

NB. ---------------------------------------------------------
NB. Public verbs

NB.*urlencode v Encode string as valid url
urlencode=:  [: ; encode^:(safe -.@e.~ ])&.>

NB.*urlquery v Creates urlencoded string of namevalue pairs.
NB. returns: urlencoded string of namevalue pairs for appending to url
NB. y is: rank 1 or 2 array of boxed namevalue pairs
NB.        rank 1 assumes name;value;name;value...
NB.        rank 2 assumes 0{"1 is names & 1{"1 is values
NB. eg: urlquery ('action';'query'),('name';'S&P Inc'),:('format';'json')
urlquery=: 3 : 0
  if. 0 e. $y do. '' return. end.
  'arg should be boxed' assert 32 = 3!:0 y
  'arg should be rank 1 or 2' assert 1 2 e.~ rnk=. #$y
  if. rnk = 1 do. 
    'arg should be name-value pairs' assert 0 = 2|#y
    y=. _2]\ y
  else. 'arg should only have 2 cols' assert 2 = {:$y end.
  args y
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
urlencode_z_=: urlencode_wgethttp_
urlquery_z_=: urlquery_wgethttp_