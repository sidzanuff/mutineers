rem NOTES

    rem TICKS to second
    rem s=TICKS/10000000


rem GLOBAL VARIABLES

    rem
    rem LIT - last input time
    rem CCX - current chunk x
    rem CCY - current chunk y
    rem PCX - prevous chunk x
    rem PCY - prevous chunk y
    rem CCV - chunk version
    rem PCV - previous chunk verson
    rem CCD - chunk data
    rem CLX - local x
    rem CLY - local y
    rem PLX - previous loxal x
    rem PLY - previous local y
    rem CFA - current facing
    rem PFA - previous facing
    rem PSD - previous screen data
    rem CSD - current screen data
    rem CSC - screen colors
    rem LCX - last cursor x
    rem LCY - last cursor y
    rem SER - server id
    rem ACT - current action

    LIT=INKEY:CCV=0:PCX=0:PCY=0:PLX=0:PLY=0:PFA=-1:PCV=0:DEY=19


rem SETUP DATABASE

    DBFILE$="mnz4"

    rem Chunk table
    rem x, y - chunk coordinates / identifier
    rem v - last chunk update in ticks
    rem d - chunk data 16*16 characters
    rem s - server player id
    @ "create table if not exists c(x integer,y integer,v integer,d text,s integer)"

    rem Players table
    rem i - id
    rem cx,cy - chunk coordinates
    rem lx,ly - local coordinates
    rem f - facing
    rem n - name
    rem a - action (0 - offline, 1 - idle, 2 - forward, 3 - backward, 4 - left, 5 - right, 6 - shoot)
    @ "create table if not exists p(i integer,cx integer,cy integer,lx integer,ly integer,f integer,a integer,n text)"

    rem Messages table
    rem i - id
    rem t - text
    @ "create table if not exists m(i integer primary key, t text)"


rem SETUP SCREEN

    color 2
    cls:home
    rem    123456789012345678901234
    print "+----------------+"
    print "|                | +------+"
    print "|                | |CX:  0|"
    print "|                | |CY:  0|"
    print "|                | |LX:  0|"
    print "|                | |LY:  0|"
    print "|                | +------+"
    print "|                |"
    print "|                |"
    print "|                |"
    print "|                |"
    print "|                |"
    print "|                |"
    print "|                |"
    print "|                |"
    print "|                |"
    print "|                |"
    print "+----------------+"
    home

    LCX=1:LCY=1:PCX=0:PCY=0:PLX=0:PLY=0

    PSD$=""
    for i=1 to 256
        PSD$=PSD$+" "
    next i

gosub checkupdate
!mainloop
    gosub handleinput
    gosub checkupdate
    PCX=CCX:PCY=CCY:PLX=CLX:PLY=CLY:PFA=CFA:PCV=CCV
goto mainloop


!checkupdate
    r$=@ "select cx,cy,lx,ly,f,a from p where i="+str$(USERID)
    if QCOUNT=0 then gosub createplayer:goto checkupdatechunk
    CCX=r$(0,'cx')
    CCY=r$(0,'cy')
    CLX=r$(0,'lx')
    CLY=r$(0,'ly')
    CFA=r$(0,'f')
    ACT=r$(0,'a')
    if ACT=0 then ACT=1:gosub updateaction

    !checkupdatechunk
    r$=@ "select v,s from c where x="+str$(CCX)+" and y="str$(CCY)
    if QCOUNT=0 then gosub createchunk:goto refresh
    CCV=r$(0,'v')
    SER=r$(0,'s')

    if CCX=PCX and CCY=PCY and CLX=PLX and CLY=PLY and CFA=PFA and CCV=PCV then return

    !refresh
    r$=@ "select d from c where x="+str$(CCX)+" and y="str$(CCY)
    CCD$=r$(0,'d')
    CSD$=CCD$
    for i=1 to 256
        CSC(i)=1
    next i
    r$=@ "select lx,ly,f,i from p where a>0 and cx="+str$(CCX)+" and cy="+str$(CCY)
    for i=1 to QCOUNT
        x=r$(i-1,'lx')
        y=r$(i-1,'ly')
        pf=r$(i-1,'f')
        pid=r$(i-1,'i')
        if pf=0 then pc$="A"
        if pf=1 then pc$=">"
        if pf=2 then pc$="V"
        if pf=3 then pc$="<"
        pi=(y-1)*16+x
        if pid=USERID then CSC(pi)=2
        if pid<>USERID then CSC(pi)=4
        if pi=1 then CSD$=pc$+right$(CSD$,255)
        if pi=256 then CSD$=left$(CSD$,255)+pc$
        if pi>1 and pi<256 then CSD$=left$(CSD$,pi-1)+pc$+right$(CSD$,256-pi)
    next i
    for yy=1 to 16
    for xx=1 to 16
        i=(yy-1)*16+xx
        s$=mid$(CSD$,i,1)
        if s$<>mid$(PSD$,i,1) then color CSC(i):x=xx+1:y=yy+1:gosub echo
    next xx
    next yy
    PSD$=CSD$
    rem print status
    rem s$="print status":gosub debug
    color 2
    x=24:
    if PCX<>CCX then y=3:va=CCX:gosub padstr:gosub echo
    if PCY<>CCY then y=4:va=CCY:gosub padstr:gosub echo
    if PLX<>CLX then y=5:va=CLX:gosub padstr:gosub echo
    if PLY<>CLY then y=6:va=CLY:gosub padstr:gosub echo
    rem s$="refresh done":gosub debug
    rem x=CLX+1:y=CLY+1:gosub locate
    return


!createplayer
    s$="createplayer":gosub debug
    CCX=0:CCY=0:CFA=1:ACT=1
    CLX=int(rnd()*16)+1
    CLY=int(rnd()*16)+1
    s$="insert into p(i,lx,ly,cx,cy,f,a,n) values("+str$(USERID)+","+str$(CLX)+","+str$(CLY)+",0,0,1,1,'"+USERNAME$+"')"
    gosub debug
    @ s$
    return


!createchunk
    s$="createchunk":gosub debug
    pi=(CLY-1)*16+CLX
    CCD$=""
    for y=1 to 16
    for x=1 to 16
        i=(y-1)*16+x
        c$=" "
        if x>1 and x<16 and y>1 and y<16 and i<>pi and rnd()<.25 then c$="#"
        CCD$=CCD$+c$
    next x
    next y
    CCV=TICKS
    SER=USERID
    @ "insert into c(x,y,d,v,s) values("+str$(CCX)+","+str$(CCY)+",'"+CCD$+"',"+str$(CCV)+","+str$(SER)")"
    return


!updateaction
    s$="update p set a="+str$(ACT)+" where i="+str$(USERID)
    @ s$
    if ACT<>0 then return
    @ "update c set s=-1 where x="+str$(CCX)+" and y="+str$(CCY)
    end


!handleinput
    if LIT=INKEY then return
    k$=INKEY$:LIT=INKEY
    if k$="q" then ACT=0:goto updateaction
    if ACT>1 then return
    if k$="w" then m=1:goto walk
    if k$="s" then m=-1:goto walk
    if k$="a" then m=-1:goto turn
    if k$="d" then m=1:goto turn
    return


!turn
    CFA=(CFA+m)%4
    if CFA<0 then CFA=3
    goto updateplayer


!walk
    nx=CLX:ny=CLY
    if CFA=0 then ny=CLY-m
    if CFA=1 then nx=CLX+m
    if CFA=2 then ny=CLY+m
    if CFA=3 then nx=CLX-m
    if nx>16 then CLX=1:CCX=CCX+1:goto updateplayer
    if nx<1 then CLX=16:CCX=CCX-1:goto updateplayer
    if ny>16 then CLY=1:CCY=CCY+1:goto updateplayer
    if ny<1 then CLY=16:CCY=CCY-1:goto updateplayer
    i=(ny-1)*16+nx
    c$=mid$(CCD$,i,1)
    if asc(c$)=32 then CLX=nx:CLY=ny
    rem TODO: check player collision
    goto updateplayer


!updateplayer
    @ "update p set cx="+str$(CCX)+",cy="+str$(CCY)+",lx="+str$(CLX)+",ly="+str$(CLY)+",f="+str$(CFA)+",a=1 where i="+str$(USERID)
    @ "update c set v="+str$(TICKS)+" where x="+str$(PCX)+" and y="+str$(PCY)
    @ "update c set v="+str$(TICKS)+" where x="+str$(CCX)+" and y="+str$(CCY)
    return


!padstr
    s$=str$(va)
    !padstr2
    if len(s$)=3 then return
    s$=" "+s$
    goto padstr2


!locate
    if LCX<x then right x-LCX
    if LCX>x then left LCX-x
    if LCY<y then down y-LCY
    if LCY>y then up LCY-y
    LCX=x
    LCY=y
    return


!echo
    gosub locate
    print s$;
    LCX=LCX+len(s$)
    return


!debug
    if len(s$)<32 then s$=s$+" ": goto debug
    rem if len(s$)>32 then s$=left$(s$, 32)
    y=DEY
    x=1
    gosub echo
    DEY=DEY+1
    if DEY>24 then DEY=19
    return
