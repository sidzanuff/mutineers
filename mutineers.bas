cls

DBFILE$="mz"
is_server=0
re=0
li=INKEY

@ "create table if not exists c (x integer,y integer,v integer, d text)"
@ "create table if not exists u "+"(id integer,cx integer,cy integer,lx integer,ly integer,f intger, l integer)"

gosub loadplayer
@ "update u set l=1 where id="+str$(USERID)
gosub loadchunk

!mainloop
    gosub server
    gosub checkupdate
    gosub handleinput
goto mainloop

!loadplayer
r$=@ "select * from u where id="+str$(USERID)
if QCOUNT<1 then goto createplayer
cx=r$(0,'cx')
cy=r$(0,'cy')
lx=r$(0,'lx')
ly=r$(0,'ly')
f=r$(0,'f')
return
!createplayer
lx=int(rnd()*16)+1
ly=int(rnd()*16)+1
cx=0:cy=0:f=0
s$="insert into u(id,lx,ly,cx,cy,f) values("
s$=s$+str$(USERID)+","
s$=s$+str$(lx)+","
s$=s$+str$(ly)+","
s$=s$+"0,0,0)"
@ s$
return
!loadchunk
r$=@ "select * from c where x="+str$(cx)+" and y="+str$(cy)
if QCOUNT<1 then goto createchunk
cd$=r$(0,'d')
cv=r$(0,'v')
goto render
!createchunk
pi=(ly-1)*16+lx
cd$=""
for i=1 to 256
cc$=" "
if i<>pi and rnd()<.25 then cc$="#"
cd$=cd$+cc$
next i
cv=0
s$="insert into c(x,y,d,v) values("
s$=s$+str$(cx)+","
s$=s$+str$(cy)+",'"
s$=s$+cd$
s$=s$+"',0)"
@ s$
goto render
!checkupdate
q$="from c where x="+str$(cx)+" and y="+str$(cy)
r$=@ "select v "+q$
if QCOUNT<1 then goto createchunk
v=r$(0,'v')
if v=cv then return
cv=v
r$=@ "select d "+q$
cd$=r$(0,'d')
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
!render
for i=1 to 256
cdc(i)=1
next i
s$="select lx,ly,f,id from u where l=1 and cx="
s$=s$+str$(cx)+" and cy="
s$=s$+str$(cy)
r$=@ s$
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
if pid=USERID then cdc(pi)=2
if pid<>USERID then cdc(pi)=4
if pi=1 then cd$=pc$+right$(cd$,255)
if pi=256 then cd$=left$(cd$,255)+pc$
if pi>1 and pi<256 then cd$=left$(cd$,pi-1)+pc$+right$(cd$,256-pi)
next i
if re=1 then goto rerender
home
for i=1 to 16
for j=1 to 16
cdi=(i-1)*16+j
color cdc(cdi)
print mid$(cd$,cdi,1);
next j
print ""
next i
re=1:lcd$=cd$
lcx=1:lcy=17
goto printstatus
!signout
@ "update u set l=0 where id="+str$(USERID)
gosub updatechunk
end
!updatechunk
cv=cv+1
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

!rerender
for y=1 to 16
for x=1 to 16
i=(y-1)*16+x
if mid$(cd$,i,1)<>mid$(lcd$,i,1) then gosub rerenderc
next x
next y
lcd$=cd$
goto printstatus
!rerenderc
gosub locate
color cdc(i)
print mid$(cd$,i,1);
lcx=x+1:lcy=y
return
!printstatus
color 2
x=18:y=1:va=cx:gosub padstr:s$="CX:"+s$:gosub echo
x=18:y=2:va=cy:gosub padstr:s$="CY:"+s$:gosub echo
x=18:y=3:va=lx:gosub padstr:s$="LX:"+s$:gosub echo
y=4:va=ly:gosub padstr:s$="LY:"+s$:gosub echo
return
!padstr
s$=str$(va)
!padstr2
if len(s$)=3 then return
s$=" "+s$
goto padstr2
!locate
if lcx<x then right x-lcx
if lcx>x then left lcx-x
if lcy<y then down y-lcy
if lcy>y then up lcy-y
return
!echo
gosub locate
print s$;
lcx=x+len(s$)
lcy=y
return

!server
r$=@ "select id from u where cx="+str$(cx)+" and cy="+str$(cy)
id=r$(0,'id')
if id<>USERID then is_server=0:return
if is_server=0 then is_server=1:sticks=TICKS:return
if TICKS-sticks<20000000 then return
sticks=TICKS
return
