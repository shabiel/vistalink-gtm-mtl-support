XOBVSKT ;;2019-12-26  9:12 AM; 07/27/2002  13:00
 ;;1.6;VistALink;**3,11310000**;May 08, 2009
 ;Per VHA directive 2004-038, this routine should not be modified.
 ; **11310000** ven/smh - GT.M support + TCP Socket send and receive optimization
 QUIT
 ;
 ; ------------------------------------------------------------------------------------
 ;                          Methods for Read from/to TCP/IP Socket
 ; ------------------------------------------------------------------------------------
READ(XOBROOT,XOBREAD,XOBTO,XOBFIRST,XOBSTOP,XOBDATA,XOBHDLR) ;
 N X,EOT,OUT,STR,LINE,PIECES,DONE,TOFLAG,XOBCNT,XOBLEN,XOBBH,XOBEH,BS,ES,XOBOK,XOBX,SAML
 ;
 S STR="",EOT=$C(4),DONE=0,LINE=0,XOBOK=1,SAML=0
 ;
 ; -- READ tcp stream to global buffer | main calling tag NXTCALL^XOBVLL
 NEW READTRYCOUNT SET READTRYCOUNT=0
 F  R XOBX#XOBREAD:XOBTO S TOFLAG=$T D:XOBFIRST CHK D:'XOBSTOP!('DONE)  Q:DONE
 . ;
 . ; debugging
 . ; I $I(^SAM(^SAM,"READ"))
 . ; S ^SAM(^SAM,"READ",^SAM(^SAM,"READ"),"DATA")=XOBX
 . ; S ^SAM(^SAM,"READ",^SAM(^SAM,"READ"),"TIME")=$G(%ZH2)
 . ;
 . ; Throttle GT.M since timeout is zero for GT.M
 . IF 'TOFLAG,XOBX="",XOBOS="GTM" DO  QUIT
 . . SET READTRYCOUNT=READTRYCOUNT+1
 . . IF READTRYCOUNT>3 SET DONE=1,XOBOK=0
 . . HANG .01
 . . ; debugging
 . . ; S ^SAM(^SAM,"READ",^SAM(^SAM,"READ"),"HANG")=$G(^("HANG"))+.01
 . ;
 . ; -- if length of (new intake + current) is too large for buffer then store current
 . I $L(STR)+$L(XOBX)>400 D ADD(STR) S STR=""
 . S STR=STR_XOBX
 . ;
 . ; -- if end-of-text marker found then wrap up and quit
 . I STR[EOT S STR=$P(STR,EOT) D ADD(STR) S DONE=1 Q
 . ; 
 . ; -- M XML parser cannot handle an element name split across nodes
 . ; Not needed in the M XML Parser v2.5 (https://github.com/shabiel/VISTA-xml-processing-utilities)
 . ;SET PIECES=$LENGTH(STR,">")
 . ;IF PIECES>1 DO ADD($PIECE(STR,">",1,PIECES-1)_">") SET STR=$PIECE(STR,">",PIECES,999)
 ;
 K ^TMP($J,"SAML")
 I $G(^XTMP($J,"SAML")) D
 . S NC=2,NC1=1 F  S NC=$O(^XTMP($J,"SAML",NC)) Q:$G(NC)'>0  S ^TMP($J,"SAML",NC1)=$G(^XTMP($J,"SAML",NC)),NC1=NC1+1
 ;
 Q XOBOK
 ;
ADD(TXT) ; -- add new intake line
 S LINE=LINE+1
 S @XOBROOT@(LINE)=TXT
 S:TXT["SAML"&($G(SAML)'=2) SAML=1 S:$G(SAML)=1&($G(TXT)["<soapenv:Envelope") SAML=2
 S:TXT["]]" SAML=3
 S:$G(SAML)=2 ^XTMP($J,"SAML",LINE)=$G(TXT)
 S:$G(SAML)=3 ^XTMP($J,"SAML",LINE)=$P(TXT,"]]",1)_"]]"
 Q
 ;
CHK ; -- check if first read and change timeout and chars to read
 S XOBFIRST=0
 ;
 ; -- abort if time out occurred and nothing was read
 I 'TOFLAG,$G(XOBX)="" S XOBSTOP=1,DONE=1,XOBOK=0 Q
 ;
 ; -- intercept for transport sinks
 I $E(XOBX)'="<" D SINK
 ;
 ; -- set up for subsequent reads
 S XOBREAD=4096,XOBTO=1
 I XOBOS="GTM" S XOBTO=0
 Q
 ;
 ; ------------------------------------------------------------------------------------
 ;                      Execute Proprietary Format Reader
 ; ------------------------------------------------------------------------------------
SINK ;
 ; -- get size of sink indicator >> then get sink indicator >> load req handler
 S XOBHDLR=$$MSGSINK^XOBVRH($$GETSTR(+$$GETSTR(2,.XOBX),.XOBX),.XOBHDLR)
 ;
 ; -- execute proprietary stream reader
 I $G(XOBHDLR(XOBHDLR)) X $G(XOBHDLR(XOBHDLR,"READER"))
 ;
 S DONE=1
 Q
 ;
 ; -- get string of length LEN from stream buffer
GETSTR(LEN,XOBUF) ;
 N X
 F  Q:($L(XOBUF)'<LEN)  D RMORE(LEN-$L(XOBUF),.XOBUF)
 S X=$E(XOBUF,1,LEN)
 S XOBUF=$E(XOBUF,LEN+1,999)
 Q X
 ;
 ; -- read more from stream buffer but only needed amount
RMORE(LEN,XOBUF) ;
 N X
 R X#LEN:1 S XOBUF=XOBUF_X
 Q
 ;
 ; ------------------------------------------------------------------------------------
 ;                      Methods for Opening and Closing Socket
 ; ------------------------------------------------------------------------------------
OPEN(XOBPARMS) ; -- Open tcp/ip socket
 N I,POP
 S POP=1
 ;
 ; -- set up os var
 D OS
 ;
 ; -- preserve client io
 D SAVDEV^%ZISUTL("XOB CLIENT")
 ;
 F I=1:1:XOBPARMS("RETRIES") D CALL^%ZISTCP(XOBPARMS("ADDRESS"),XOBPARMS("PORT")) Q:'POP
 ; -- device open
 I 'POP U IO Q 1
 ; -- device not open
 Q 0
 ;
CLOSE(XOBPARMS) ; -- close tcp/ip socket
 ; -- tell server to Stop() connection if close message is needed to close
 I $G(XOBPARMS("CLOSE MESSAGE"))]"" D
 . D PRE
 . D WRITE($$XMLHDR^XOBVLIB()_XOBPARMS("CLOSE MESSAGE"))
 . D POST
 ;
 D FINAL
 D CLOSE^%ZISTCP
 D USE^%ZISUTL("XOB CLIENT")
 D RMDEV^%ZISUTL("XOB CLIENT")
 Q
 ;
INIT ; -- set up variables needed in tcp/ip processing
 K XOBNULL
 ;
 ; -- setup os var
 D OS
 ;
 ; -- set RPC Broker os variable (so $$BROKER^XWBLIB returns true)
 S XWBOS=XOBOS
 ;
 ; -- setup null device called "NULL"
 S %ZIS="0H",IOP="NULL" D ^%ZIS
 I 'POP D
 . S XOBNULL=IO
 . D SAVDEV^%ZISUTL("XOBNULL")
 Q
 ;
OS ; -- os var
 ; VEN/SMH **11310000**
 ; was SET XOBOS=$SELECT(^%ZOSF("OS")["OpenM":"OpenM",^("OS")["DSM":"DSM",^("OS")["UNIX":"UNIX",^("OS")["MSM":"MSM",1:"")
 S XOBOS=$SELECT(^%ZOSF("OS")["OpenM":"OpenM",^("OS")["DSM":"DSM",^("OS")["GT.M":"GTM",^("OS")["MSM":"MSM",1:"")
 Q
 ;
FINAL ; -- kill variables used in tcp/ip processing
 ;
 ; -- close null device
 I $D(XOBNULL) D
 . D USE^%ZISUTL("XOBNULL")
 . D CLOSE^%ZISUTL("XOBNULL")
 . K XOBNULL
 ;
 K XOBOS,XWBOS
 ;
 Q
 ;
 ; ------------------------------------------------------------------------------------
 ;                          Methods for Writing to TCP/IP Socket
 ; ------------------------------------------------------------------------------------
PRE ; -- prepare socket for writing
 S $X=0
 Q
 ;
WRITE(STR) ; -- Write a data string to socket
 ; Optimized by OSEHRA/SMH to buffer.
 ; NB: No easy way to obtain MTU on M, so I will just assume best case scenario
 ; of MTU of 64k. Normally it's just 1500. The Linux Kernel will fragment down
 ; the packet.
 I XOBOS="MSM" W STR Q
 ;
 ; Short Strings. Just buffer and quit.
 IF $LENGTH(STR)+$LENGTH(XOBSENDSTR)<32768 SET XOBSENDSTR=XOBSENDSTR_STR QUIT
 ;
 ; Long Strings: Case 1: Not too long: Send what's in buffer, and store long string in buffer.
 ; Long Strings: Case 2: Send what's in the buffer, and send this the long string too.
 ; NB: Possible only on GT.M--Cache can't do strings > 32k.
 DO FLUSH
 IF $LENGTH(STR)<32767 SET XOBSENDSTR=STR
 ELSE  WRITE STR
 QUIT
 ;
POST ; -- send eot and flush socket buffer
 D WRITE($C(4))
 D FLUSH
 Q
 ;
FLUSH ; flush buffer
 ; debugging
 ;S ^SAM(^SAM,"WRITE")=$L(XOBSENDSTR)
 WRITE XOBSENDSTR,!
 SET XOBSENDSTR=""
 QUIT
 ;
