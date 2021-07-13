MPNAME=mp1

all: $(MPNAME).exe

clean:
	rm -f $(MPNAME).obj $(MPNAME).exe $(MPNAME).lst $(MPNAME).map

%.exe: %.obj
	tlink /c /v $<, $*.exe, $*.map, libmp1.lib lib291.lib

%.obj: %.asm
	nasm -g -f obj -o $*.obj $< -l $*.lst

