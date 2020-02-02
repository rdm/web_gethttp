NB. =========================================================
NB. web/gethttp
NB. J interface for Wget/cURL to retrieve files using http, ftp, https

require 'task strings socket'

coclass 'wgethttp'

3 : 0 ''

  IFWGET=: 0
  HTTPCMD=: ''
  select. <UNAME
  case. 'Android' do.
    if. 1=ftype f=. '/system/xbin/wget' do.  NB. android busybox
      IFWGET=: 1
      HTTPCMD=: f
    elseif. 1=ftype f=. '/system/bin/wget' do.  NB. alternate location
      IFWGET=: 1
      HTTPCMD=: f
    end.
  case. 'Win' do.
    if. fexist f=. jpath '~addons/web/gethttp/bin/curl.exe' do.
      HTTPCMD=: f
    elseif. fexist f=. jpath '~tools/ftp/wget.exe' do.
      IFWGET=: 1
      HTTPCMD=: f
    end.
  case. 'Darwin' do.
    HTTPCMD=: 'curl'
  case. do.   NB. Linux
    try.
      2!:0'which wget 2>/dev/null'
      IFWGET=: 1 [ HTTPCMD=: 'wget' catch. end.
    if. -.IFWGET do.
    try.
      2!:0'which curl 2>/dev/null'
      HTTPCMD=: 'curl' catch. end.
    end.
  end.
  if. IFUNIX do.   NB. fix task.ijs definition of spawn on mac/unix
    spawn=: [: 2!:0 '(' , ' || true)' ,~ ]
  else.
    spawn=: spawn_jtask_
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
  if. IFIOS +. HTTPCMD-:'' do.
    if. 'http://'-.@-:7{.url do.
      'only http:// supported' return.
    end.
    output=. 0
    fil=. ''
    select. jopts
    case. 'stdout' do.  NB. content retrieved from stdout, log suppressed
    case. 'help' do.    NB. help
      'no help available' return.
    case. 'file' do.
      output=. 1
      if. #fnme do.     NB. save as filename
        fil=. fnme
      end.
    end.
    server=. ({.~ i.&'/') (7}.url)
    aurl=. }.(}.~ i.&'/') (7}.url)
    try.
    'header data'=. jwget server;aurl
    catch.
    'getHTTP error' return.
    end.
    if. 0=output do.
      data return.
    else.
      if. #fil do.
        if. '/' e. fil=. jpathsep fil do. mkdir_j_ ({.~ i:&'/') fil end.
        data fwrite fil
      else.
        fil=. }:^:('/'={:) aurl
        fil=. (}.~ i:&'/') fil
        fil=. }.^:('/'={.) fil
        if. 0=#fil do. fil=. 'httpresult' end.
        data fwrite fil
      end.
      '' return.
    end.
  end.
  select. jopts
  case. 'stdout' do.  NB. content retrieved from stdout, log suppressed
    opts=. IFWGET{:: '-o - -s -S';'-O - -q'
  case. 'file' do. 
    if. #fnme do.     NB. save as filename
      opts=. IFWGET{:: '--stderr - -o ';'-O '
      opts=. opts,fnme
    else.             NB. copy file to current dir
      opts=. IFWGET{:: '-O --stderr -';' '
    end.
  case. 'help' do.    NB. help
    opts=. '--help'
  case. do.           NB. custom option string?
    if. 2 131072 262144 e.~ 3!:0 x do. opts=. utf8 x
    else. 'Invalid left argument for getHTTP' return. end.
  end.
  opts=. ' ',opts,' '
  spawn HTTPCMD , opts , url
)

NB. =========================================================
NB.! does not work when server response with HTTP 1.1

NB.! following code should be made as robust and general as possible
NB.  it should then be refactored into JHS (where it came from)

NB. send socket data
NB. return count of bytes sent
NB. errors: timeout, socket error, no data sent (disconnect)
ssend=: 4 : 0
'socket timeout'=. y
z=. sdselect_jsocket_ '';socket;'';timeout
'server send not ready' assert socket=>2{z
'c r'=. x sdsend_jsocket_ socket,0
('server send error: ',sderror_jsocket_ c) assert 0=c
'server send no data' assert 0<r
r
)

NB. data putdata socket,timeout
putdata=: 4 : 'while. #x do. x=. (x ssend y)}.x end.'

ssrecv=: 3 : 0
'socket timeout bufsize'=. y
z=. sdselect_jsocket_ socket;'';'';timeout
'server recv timeout' assert  socket e.>1{z  NB.0;'';'';'' is a timeout
'server recv not ready' assert socket=>1{z
'c r'=. sdrecv_jsocket_ socket,bufsize,0
('server recv error: ',sderror_jsocket_ c) assert 0=c
'server recv no data'       assert 0<#r
r
)

NB. get/post data - headers end with CRLF,CRLF
NB. post has Content-Length: bytes after the header
NB. listen and read until a complete request is ready
getdata=: 3 : 0
'socket timeout bufsize'=. y
h=. d=. ''
cl=. 0
while. (0=#h)+.cl>#d do. NB. read until we have header and all data
 r=. ssrecv socket,timeout,bufsize
 d=. d,r
 if. 0=#h do. NB. get headers
  i=. (d E.~ CRLF,CRLF)i.1 NB. headers CRLF delimited with CRLF at end
  if. i<#d do. NB. have headers
   i=. 4+i
   h=. i{.d NB. headers
   d=. i}.d
   i=. ('Content-Length:'E. h)i.1
   if. i<#h do.
    t=. (15+i)}.h
    t=. (t i.CR){.t
    cl=. _1".t
    assert _1~:cl
   else.
    cl=._1
   end.
  end.
 end.
end.
h;d
)

RECVBUFSIZE=: 50000
SENDTIMEOUT=: 20*60*1000 NB. 20 minutes for a send
TIMEOUT=: 20*60*1000 NB. 20 minutes for a response

jwget=: 3 : 0
'server url'=. y
i=. server i.':'
server=. i{.server
port=. {. 0".(>:i)}.server
port=. (0=port){port,80
if. #server-.'0123456789.' do.
  ip=. >2{sdgethostbyname_jsocket_ server
else.
  ip=. server
end.
try.
 t=. gettemplate rplc '<SERVER>';server;'<URL>';url
 sk=. >0{sdcheck_jsocket_ sdsocket_jsocket_''
NB. sdcheck_jsocket_ sdioctl_jsocket_ sk,FIONBIO_jsocket_,1
 sdcheck_jsocket_ sdconnect_jsocket_ sk;AF_INET_jsocket_;ip;port
 t putdata sk,SENDTIMEOUT
 hd=. getdata sk,RECVBUFSIZE,TIMEOUT
catch.
 sdclose_jsocket_ sk
 (13!:12'') assert 0
end.
sdclose_jsocket_ sk
hd
)

gettemplate=: toCRLF 0 : 0
GET /<URL> HTTP/1.0
User-Agent: Mozilla/5.0 (Linux; Android 4.4; Nexus 5 Build/_BuildID_) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/30.0.0.0 Mobile Safari/537.36
Accept: */*
Host: <SERVER>
Connection: Keep-Alive

)

NB. =========================================================
NB. Export z locale

gethttp_z_ =: gethttp_wgethttp_
urlencode_z_=: urlencode_wgethttp_
urlquery_z_=: urlquery_wgethttp_
