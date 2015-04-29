SKINC    = -I Skepu
IFLAGS   = -I ./Skepu/skepu
ERLINC   = -I /usr/local/lib/erlang/erts-5.9.1/include/
LIBFLAGS = -fpic -shared
NVCCLIBF = -Xcompiler -fpic -Xcompiler -shared
#CFLAGS   = -DTIME
CFLAGS   = 
TARBALL  = erlang-gpu-skeletons.tgz
TARFLAGS = --exclude-vcs
SOURCEFILES = mapper.cpp mapper.cu Skepu Makefile README skprep.pl user.h 
USERMACROFILE = user.h

all: 	clean cpu ocl 

clean: 	
	rm -f mapper.so mapper.o f.o *~ *.beam

ocl:	mapper.cpp $(USERMACROFILE)
	./skprep.pl
	g++ -DSKEPU_OPENCL $(CFLAGS) $(SKINC) $(ERLINC) $(LIBFLAGS) -lm -o mapper.so mapper.cpp -lOpenCL
cpu:	mapper.cpp $(USERMACROFILE)
	./skprep.pl
	g++ -DSKEPU_OMP $(CFLAGS) $(SKINC) $(ERLINC) $(LIBFLAGS) -lm -o mapper.so mapper.cpp

cuda:	mapper.cu $(USERMACROFILE) 
	./skprep.pl 
	nvcc -DSKEPU_CUDA mapper.cu $(ERLINC) $(SKINC)  -w  $(NVCCLIBF) -o mapper.so

tar:	
	tar czvf $(TARBALL) $(TARFLAGS) $(SOURCEFILES)

