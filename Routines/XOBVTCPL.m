XOBVTCPL ;;2017-08-12  10:31 AM; 07/27/2002  13:00
 ;;1.6;VistALink;**11310000**;May 08, 2009
 ;Per VHA directive 2004-038, this routine should not be modified.
 ;
 ; **11310000** VEN/SMH many many changes to support GT.M Native MTL.
 ; NB: Works only on GT.M >= 6.1
 QUIT
 ;
 ; -- Important: Should always be JOBed using START^XOBVTCP
LISTENER(XOBPORT,XOBCFG) ; -- Start Listener
 ;
 ; -- quit if not Cache for NT or GT.M/Linux
 N XOBVOS S XOBVOS=$$GETOS^XOBVTCP()
 ; ven/smh - I applied demorgan's law. Now I don't have a clue what it means, but it should work.
 I '((XOBVOS["OpenM-NT")!(XOBVOS["GT.M")) QUIT
 NEW $ETRAP,$ESTACK SET $ETRAP="D ^%ZTER HALT"
 ;
 NEW X,POP,XOBDA,U,DTIME,DT,XOBIO
 SET U="^",DTIME=900,DT=$$DT^XLFDT()
 IF $GET(DUZ)="" NEW DUZ SET DUZ=.5,DUZ(0)="@"
 ;
 ; -- only start if not already started
 ; VEN/SMH - Looks like Try/Catch/Finally
 ; The status variable is really reallly confusing.
 ; See, the $$ call blocks endlessly until we say let's exit.
 ; If we exit, the status is 1, b/c that's what the $$ returns upon success/exit.
 ; But if we can't open the port, we will get a zero. Which means we say that
 ; we failed to start.
 ; Thus, if Status is 1, then we CLOSE the port, since we are done with the
 ; listening b/c we were asked to exit.
 ; If status is 0, it means that we didn't open the port in the first place.
 ; So say there is an error.
 ; Hope that this clarifies it.
 ; Yours Truly, Sam
 DO SETNM^%ZOSV("VLinkM_"_$J) ;
 N XOBVSTUS ; Status
 IF $$LOCK^XOBVTCP(XOBPORT) D
 . S:XOBVOS["OpenM" XOBVSTUS=$$OPENM(.XOBIO,XOBPORT)
 . S:XOBVOS["GT.M" XOBVSTUS=$$GTM(.XOBIO,XOBPORT)
 . ; -- listener started and now stopping
 . I XOBVSTUS D
 . . SET IO=XOBIO
 . . DO CLOSE^%ZISTCP
 . .; -- update status to 'stopped'
 . .DO UPDATE^XOBVTCP(XOBPORT,4,$GET(XOBCFG))
 . ELSE  DO
 . . ; -- listener failed to start
 . . ; -- update status to 'failed'
 . . DO UPDATE^XOBVTCP(XOBPORT,5,$GET(XOBCFG))
 . ;
 . ; (finally)
 . DO UNLOCK^XOBVTCP(XOBPORT)
 QUIT
 ;
 ; -- open/start listener port
OPENM(XOBIO,XOBPORT) ;
 NEW XOBBOX,%ZA
 SET XOBBOX=+$$GETBOX^XOBVTCP()
 SET XOBIO="|TCP|"_XOBPORT
 OPEN XOBIO:(:XOBPORT:"AT"):30
 ;
 ; -- if listener port could not be opened then gracefully quit
 ;    (other namespace using port maybe?)
 IF '$TEST QUIT 0
 ;
 ; -- indicate listener is 'running'
 DO UPDATE^XOBVTCP(XOBPORT,2,$GET(XOBCFG))
 ; -- read & spawn loop
 FOR  DO  QUIT:$$EXIT(XOBBOX,XOBPORT)
 . USE XOBIO
 . READ *X:60 IF '$TEST QUIT
 . JOB CHILDNT^XOBVTCPL():(:4:XOBIO:XOBIO):10 SET %ZA=$ZA
 . IF %ZA\8196#2=1 WRITE *-2 ;Job failed to clear bit
 QUIT 1
 ;
GTM(XOBIO,XOBPORT) ; GT.M M controlled listener (not xinetd); SIS/LM and VEN/SMH
 ; ZEXCEPT: LISTEN,WAIT,detach (not variables)
 NEW XOBBOX,XOBSTOP
 ;
 I +$P($ZV,"V",2)<6.1 QUIT 0  ; Not supported under 6.1 of GT.M
 ;
 S @("$ZINTERRUPT=""I $$JOBEXAM^ZU($ZPOSITION)""") ; for GT.M, set interrupt
 ;
 ; Get our "box" (#.01 from #14.7 (TSP))
 SET XOBBOX=+$$GETBOX^XOBVTCP(),XOBSTOP=0
 ;
 ; Open server port
 SET XOBIO="$SCK"_XOBPORT
 OPEN XOBIO:(LISTEN=XOBPORT_":TCP":DELIM=$C(10,12,13):ATTACH="SERVER"):5:"SOCKET"  ; Like Cache AT mode
 ;
 ; -- if listener port could not be opened then gracefully quit
 IF '$TEST QUIT 0
 ;
 ; -- indicate listener is 'running'
 DO UPDATE^XOBVTCP(XOBPORT,2,$GET(XOBCFG))
 ;
 USE XOBIO  ; tada
 ;
 ; It only takes 5 microseconds or so to create a child socket; and then
 ; this becomes available again.
 W /LISTEN(5)
 ;
 ; Wait for 5 secs; quit if connection or if listener was asked to shut down.
 F  D  QUIT:$$EXIT(XOBBOX,XOBPORT)
 . W /WAIT(5) ; wait wait wait wait wait
 . Q:$KEY=""  ; no connection; loop around, and check if we need to shut down.
 . N CHILDSOCK S CHILDSOCK=$P($KEY,"|",2) ; child socket from server.
 . U XOBIO:(detach=CHILDSOCK) ; detach it so that we can job it off.
 . N Q S Q="""" ; next three lines build job command's argument.
 . N ARG S ARG=Q_"SOCKET:"_CHILDSOCK_Q ; ditto
 . N J S J="CHILDGTM:(input="_ARG_":output="_ARG_":error="_Q_"/dev/null"_Q_")" ; ditto
 . J @J ; and take off!
 ;
 QUIT 1
 ;
CHILDNT() ;Child process for OpenM
 NEW XOBEC
 SET $ETRAP="D ^%ZTER L  HALT"
 SET IO=$PRINCIPAL ;Reset IO to be $P
 USE IO:(::"-M") ;Packet mode like DSM
 ; -- do quit to save a stack level
 SET XOBEC=$$NEWOK()
 IF XOBEC DO LOGINERR(XOBEC,IO)
 IF 'XOBEC DO VAR,SPAWN^XOBVLL
 QUIT
 ;
CHILDGTM ;Child process for GT.M ; SIS/LM and VEN/SMH
 NEW XOBEC
 SET $ETRAP="D ^%ZTER L  HALT"
 SET IO=$PRINCIPAL ; Jobbed Child Socket in V6.1 is now Principe.
 ; No -M in GT.M.
 ; -M: Read auto completes
 ; -M: Buffered output which is flushed with *-3 or !.
 ; -M: Max is 1024 chars to write or else error
 ; -M: etc etc. Never mind. Too crazy. -M is supposed to emulate "packets"?
 X "U IO:(nowrap:nodelimiter:IOERROR=""TRAP"")" ;Setup device ; VEN/SMH (but this isn't quite like "-M")
 SET XOBEC=$$NEWOK()
 IF XOBEC DO LOGINERR(XOBEC,IO)
 IF 'XOBEC DO VAR,SPAWN^XOBVLL
 QUIT
 ;
VAR ;Setup IO variables
 SET IO(0)=IO,IO(1,IO)="",POP=0
 SET IOT="TCP",IOF="#",IOST="P-TCP",IOST(0)=0
 QUIT
 ;
NEWOK() ;Is it OK to start a new process
 NEW XQVOL,XUCI,XUENV,XUVOL,X,Y,XOBCODE
 DO XUVOL^XUS
 IF $$INHIB1^XUSRB() QUIT 181004
 IF $$INHIB2^XUSRB() QUIT 181003
 QUIT 0
 ;
 ; -- process error
LOGINERR(XOBEC,XOBPORT) ;
 DO ERROR^XOBVLL(XOBEC,$$EZBLD^DIALOG(XOBEC),XOBPORT)
 ;
 ; -- give client time to process stream
 HANG 2
 QUIT
 ;
EXIT(XOBBOX,XOBPORT) ;
 ; -- is status 'stopping'
 QUIT ($PIECE($GET(^XOB(18.04,+$$GETLOGID(XOBBOX,XOBPORT),0)),U,3)=3)
 ;
GETLOGID(XOBBOX,XOBPORT) ;
 QUIT +$ORDER(^XOB(18.04,"C",XOBBOX,XOBPORT,""))
 ;
GTMSTOP(XOBPORT) ;;SIS/LM - Convenience stop for GT.M
 NEW XOBBOX SET XOBBOX=+$$GETBOX^XOBVTCP()
 NEW XOBID SET XOBID=+$$GETLOGID(XOBBOX,XOBPORT)
 QUIT:'XOBID  SET $PIECE(^XOB(18.04,XOBID,0),"^",3)=3
 WRITE !,"Listener on port "_XOBPORT_" has been asked to stop!"
 QUIT
