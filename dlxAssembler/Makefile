ASM = dlx_asm.exe
DLX = dlxFactorial.dlx
DATA = dataFactorial.mif
CODE = codeFactorial.mif

all: run

run:
	./$(ASM) $(DLX) $(DATA) $(CODE)

clean:
	del /Q $(DATA) $(CODE) 2>nul || true