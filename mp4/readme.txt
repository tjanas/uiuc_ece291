Sure thing. Here is everything I did on my Windows 2000 to make it work
(redownload from ece291 website, so you get the latest updated ones):

1. Installed DJGPP to E:\DJGPP            (*** install wherever you wish,
just change the directory references later on***)
2. Installed EX291 to E:\mp\ex291
3. Installed PMODELIB to E:\mp\pmodelib
4. Download the MP4 and extracted the files into E:\mp
5. Edit Makefile so that it uses my locations of pmodelib
6. Installed NASM to E:\NASM            (*** I had this set already from the
previous MP's***)


OK, now the next thing I did was set the path and variables for the Win2K
OS:

Go in the Control Panel and open System, click on the Advanced tab, and
choose "Environment Variables"
In either the User Variables or System Variables  (** I did user variables
**), I added the following:

Variable Name:    DJGPP                    Variable Value:
E:\djgpp\djgpp.env
Variable Name:    EX291                    Variable Value:    w K7,300 M12
Variable Name:    VBEAF_PATH        Variable Value:
E:\mp\ex291\bin;E:\mp\ex291
Your Win2K default TEMP and TMP values are probably already there. If so,
just leave them alone.

The last thing I did was set the PATH. This I did under "System Variables."
Click on the Path variable and choose Edit. Here's what mine looks like
currently:

%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;E:\NASM;E:\djg
pp\bin

Basically, if you notice I only had to append two entries to my path. I had
to put in a semicolon and add   E:\NASM  , and then pop in another semicolon
and add   E:\djgpp\bin

After I did all of these, I pressed OK and left the System Properties. Now I
opened a CMD window, typed  ex291  and pressed enter. This is what should be
displayed now:

Extra BIOS services for ECE 291 v1.0, for Windows 2000
Copyright (C) 2000-2001 Peter Johnson
BETA SOFTWARE, ABSOLUTELY NO IMPLIED OR EXPRESSED WARRANTY
Running in windowed mode.
Extra BIOS services installed.

E:\MP>



OK, now in the same window you should be able to run test.exe. After you
type test and press enter, a black ECE 291 Graphics Drivers Display window
should appear with nothing in it. Press F2 while the window is active and it
should change colors. Exit that window by pressing a few of the F* keys, and
then try to run the given mp4.exe

That should also work.

Finally, test and see if you can complile. Delete the mp4.exe, and type make
and press enter. It should now look like the following:

E:\mp>make
gcc -o mp4 mp4.o e:/mp/pmodelib/lib291.a libmp4.a

E:\mp>

Congrats, its all set up. If it still doesn't work (*you ARE using Win2K
right?) and I missed something, please let me know. Good luck!

---------------------------------------------------
Terrence Bradley Janas
Dept. of Computer Engineering : Class of 2003
University of Illinois at Urbana-Champaign
http://www.uiuc.edu/~tjanas
tjanas@uiuc.edu
---------------------------------------------------







----- Original Message -----
From: "Paul Tongyoo" <tongyoo@students.uiuc.edu>
To: "Terrence Bradley Janas" <tjanas@uiuc.edu>
Sent: Thursday, November 01, 2001 12:58 PM
Subject: Re: compiling at home problem: no LoadPNG


>
>
>
> Hey terrence, just a nother 291'er.
> would you mind giving me the procedure
> you followed to setting up Win2K to run
> the MP from your home?
>
> Paul
>
> *!*!*!*!*!*!*!**!!*
> *!*!*!*!*!*!*!*!*!*!*!*!**!*!*!*!*!*!*!*!*!**!*!*!*!**!*!*!*!*!*!*!*!*!*!*
> *!*!*!*!*!*!*!*!*!*!*!*!*!*!!*                               !*!*!*!*!*!*!
> *!*!*!*!*!*!*!*!*!*                                              !*!*!*!!*
> *!!*!*!*!*!*!*!*                                                    !*!*!*
> *!*!*!*!*!*!           Paul Tongyoo                                    !*!
> *!*!*!*!****!!         Junior in Computer Engineering                   *!
> *!*!*!*!*!*!*!*!*      University of Illinois at Urbana/Champaign        *
> *!*!*!*!*!*!*          URH 0210 Garner Hall                              !
> *!*!!**!*!*!*!*!       201 E. Gregory Drive                              !
> *!*!*!*!*!             Champaign, IL 61820                             *!*
> *!*!*!*                                                              !*!*!
> *!*!*!*!*                                                              !*!
> *!*!*!*!*!*!*!*!*!*!**!*!*!*!**!*!*!*!**!*!*!*!*!**!*!*!*!*!*!**!*!*!*!*!*
> *                                                                        !
> !       "It's never too late to be what you might have been."            !
> *                           -George Elliot (Mary Ann Evans) 1819-1880    !
> !*!*!                                                                    !
> *!*!*!*!*!*!*!*!*!*!*!*!*!*!!*!**!*!*!*!*!*!*!*!*!*!*!!*!*!*!**!*!*!!*!*!*
> !*!**!*
> !*
>
> On Thu, 1 Nov 2001, Terrence Bradley Janas wrote:
>
> > Thanks, finally got everything 100% working. hehe
> >
> > tj
> >
> > "Dorian Hasimi" <hasimi@uiuc.edu> wrote in message
> > news:Pine.GSO.4.31.0111010818140.28817-100000@ux7.cso.uiuc.edu...
> > > I had to download the new pmodelib to get it fixed
> > >
> > > hth
> > >
> > >
> > > On Thu, 1 Nov 2001, Terrence Bradley Janas wrote:
> > >
> > > :  Date: Thu, 1 Nov 2001 01:57:42 -0600
> > > :  From: Terrence Bradley Janas <tjanas@uiuc.edu>
> > > :  Newsgroups: uiuc.class.ece291
> > > :  Subject: Re: compiling at home problem: no LoadPNG
> > > :
> > > :  I am also having the same problem, with the path & all the
variables
> > set
> > > :  correctly in my Win2K. However, even after downloading the mp4.zip
> > again and
> > > :  replacing the old versions of the files, I still get the same error
> > > :  described below. Kinda sucks I still can't work at home... has
anyone
> > gotten
> > > :  around this problem yet?  :-(
> > > :
> > > :  Terrence Janas
> > > :
> > > :  "michael urman" <mu@zen.ddts.net> wrote in message
> > > :  news:qKXC7.436$Wa1.5141@vixen.cso.uiuc.edu...
> > > :  > Dorian Hasimi <hasimi@uiuc.edu> wrote:
> > > :  > > D:\Dori\School\ECE291\mp4>make
> > > :  > > nasm -f coff -iD:/Dori/School/ECE291/pmodelib/include/ -o mp4.o
> > > :  mp4.asm -l mp4.lst
> > > :  > > gcc -o mp4 mp4.o D:/Dori/School/ECE291/pmodelib/lib291.a
libmp4.a
> > > :  > > mp4.o(.text+0xe6):mp4.asm: undefined reference to `LoadPNG'
> > > :  > > mp4.o(.text+0x103):mp4.asm: undefined reference to `LoadPNG'
> > > :  > > mp4.o(.text+0x120):mp4.asm: undefined reference to `LoadPNG'
> > > :  > > make.exe: *** [mp4.exe] Error 1
> > > :  > > rm mp4.o
> > > :  >
> > > :  > It's declared in pmodelib's loadpng.asm.  Right before we
released
> > MP4,
> > > :  > we had some problems with how we were building lib291.a, so you
may
> > want
> > > :  > to try downloading it again.  Alternately you can probably build
it
> > > :  > yourself, but i don't personally think it's worth the effort and
> > > :  > download time.
> > > :  >
> > > :  > Hope that fixes it.
> > > :  >
> > > :  > -m
> > > :  > --
> > > :  > Michael Urman :ECE291 TA: [- urman@students.uiuc.edu -]
> > > :
> > > :
> > > :
> > >
> > > --
> > > "...his ears if we're lucky!"
> > > --Krusty
> > >
> > >
> >
____________________________________________________________________________
> > > DORIAN HASIMI * (217)344-3598 * 2103 E Pennsylvania Ave Urbana, IL
61802
> > USA
> > >
> >
> >
> >
>
>
