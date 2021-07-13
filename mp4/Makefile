MPNAME=mp4

all: $(MPNAME).exe

clean: 
	-rm $(MPNAME).exe

remake: clean all

%.exe: %.o
	gcc -o $(MPNAME) $(MPNAME).o e:/mp/pmodelib/lib291.a libmp4.a

%.o: %.asm
	nasm -f coff -ie:/mp/pmodelib/include/ -o $ $*.o $< -l $*.lst
