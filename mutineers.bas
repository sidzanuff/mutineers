rem Global variables:
rem
rem LI - last input time
rem CX - chunk x
rem CY - chunk y
rem CV - chunk version
rem CD - chunk data
rem LX - local x
rem LY - local y
rem F  - directon
rem SP - previous screen data
rem SD - current screen data
rem SC - screen colors
rem LCX - last cursor x
rem LCY - last cursor y

cls

DBFILE$="mz"
LI=INKEY
SERVE=0

LCX=1
LCY=1

for i=1 to 256
    SP$=SP$+" "
next i

@ "create table if not exists c(x integer,y integer,v integer, d text)"
@ "create table if not exists p(id integer,cx integer,cy integer,lx integer,ly integer,f intger, l integer)"

gosub loadplayer
@ "update p set l=1 where id="+str$(USERID)
gosub loadchunk

!mainloop
    gosub checkupdate
    gosub handleinput
    gosub server
goto mainloop

!loadplayer
    r$=@ "select * from u where id="+str$(USERID)
    if QCOUNT<1 then goto createplayer
    CX=r$(0,'cx')
    CY=r$(0,'cy')
    LX=r$(0,'lx')
    LY=r$(0,'ly')
    F=r$(0,'f')
    return

!createplayer
    LX=int(rnd()*16)+1
    LY=int(rnd()*16)+1
    CX=0:CY=0:F=1
    @ "insert into p(id,lx,ly,cx,cy,f) values("+str$(USERID)+","+str$(LX)+","+str$(LY)+","+"0,0,0)"
    return

!loadchunk
    r$=@ "select * from c where x="+str$(cx)+" and y="+str$(cy)
    if QCOUNT<1 then goto createchunk
    CD$=r$(0,'d')
    CV=r$(0,'v')
    goto render

!createchunk
    pi=(LY-1)*16+LX
    CD$=""
    for i=1 to 256
        c$=" "
        if i<>pi and rnd()<.25 then c$="#"
        CD$=CD$+c$
    next i
    CV=0
    @ "insert into c(x,y,d,v) values("+str$(CX)+","+str$(CY)+",'"+CD$+"',0)"
    goto render

!checkupdate
    q$="from c where x="+str$(CX)+" and y="+str$(CY`)
    r$=@ "select v "+q$
    if QCOUNT<1 then goto createchunk
    v=r$(0,'v')
    if v=CV then return
    CV=v
    r$=@ "select d "+q$
    CD$=r$(0,'d')
    goto render

!handleinput
    if li=INKEY then return
    k$=INKEY$
    li=INKEY
    pcx=cx:pcy=cy
    if k$="q" then goto signout
    if k$="a" then f=(f-1)%4
    if k$="d" then f=(f+1)%4
    if f<0 then f=3
    if k$="w" then d=1:gosub walk
    if k$="s" then d=-1:gosub walk
    gosub updateplayer
    if pcx<>cx or pcy<>cy then gosub updatechunk
    pcx=cx:pcy=cy
    gosub updatechunk
    gosub loadchunk
    return

!walk
    nlx=lx:nly=ly
    if f=0 then nly=ly-d
    if f=1 then nlx=lx+d
    if f=2 then nly=ly+d
    if f=3 then nlx=lx-d
    if nlx>16 then lx=1:cx=cx+1:return
    if nlx<1 then lx=16:cx=cx-1:return
    if nly<1 then ly=16:cy=cy-1:return
    if nly>16 then ly=1:cy=cy+1:return
    i=(nly-1)*16+nlx
    cc$=mid$(cd$,i,1)
    if asc(cc$)=32 then goto dowalk
    return
    !dowalk
    lx=nlx:ly=nly
    return

!signout
    @ "update u set l=0 where id="+str$(USERID)
    gosub updatechunk
    end

!updatechunk
    s$="update c set v="+str$(cv)+" where x="
    s$=s$+str$(pcx)+" and y="
    s$=s$+str$(pcy)
    @ s$
    return

!updateplayer
    s$="update u set lx="
    s$=s$+str$(lx)+", ly="
    s$=s$+str$(ly)+", cx="
    s$=s$+str$(cx)+", cy="
    s$=s$+str$(cy)+", f="
    s$=s$+str$(f)+" where id="
    s$=s$+str$(USERID)
    @ s$
    return

!render
    SD$=CD$
    for i=1 to 256
        SC(i)=1
    next i
    r$=@ "select lx,ly,f,id from p where l=1 and cx="+str$(CX)+" and cy="+str$(CY)
    for i=1 to QCOUNT
        x=r$(i-1,'lx')
        y=r$(i-1,'ly')
        pf=r$(i-1,'f')
        pid=r$(i-1,'id')
        if pf=0 then pc$="A"
        if pf=1 then pc$=">"
        if pf=2 then pc$="V"
        if pf=3 then pc$="<"
        pi=(y-1)*16+x
        if pid=USERID then SC(pi)=2
        if pid<>USERID then SC(pi)=4
        if pi=1 then SD$=pc$+right$(SD$,255)
        if pi=256 then SD$=left$(SD$,255)+pc$
        if pi>1 and pi<256 then SD$=left$(SD$,pi-1)+pc$+right$(SD$,256-pi)
    next i
    for y=1 to 16
    for x=1 to 16
        i=(y-1)*16+x
        s$=mid$(SD$,i,1)
        if s$<>mid$(SP$,i,1) then color SC(i):gosub echo
    next x
    next y
    SP$=SD$
    rem print status
    color 2
    x=18:
    y=1:va=CX:gosub padstr:s$="CX:"+s$:gosub echo
    y=2:va=CY:gosub padstr:s$="CY:"+s$:gosub echo
    y=3:va=LX:gosub padstr:s$="LX:"+s$:gosub echo
    y=4:va=LY:gosub padstr:s$="LY:"+s$:gosub echo
    return

!padstr
    s$=str$(va)
    !padstr2
    if len(s$)=3 then return
    s$=" "+s$
    goto padstr2

!echo
    if LCX<x then right x-LCX
    if LCX>x then left LCX-x
    if LCY<y then down y-LCY
    if LCY>y then up LCY-y
    print s$;
    LCX=x+len(s$)
    LCY=y
    return

!server
    r$=@ "select id from u where cx="+str$(CX)+" and cy="+str$(CY)
    id=r$(0,'id')
    if id<>USERID then SERVE=0:return
    if SERVE=0 then SERVE=1:STICKS=TICKS:return
    if TICKS-STICKS<20000000 then return
    STICKS=TICKS
    return
