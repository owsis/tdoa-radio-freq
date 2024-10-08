# all - compile the program if any source files have changed
# all: Polygon.o Rectangle.o Triangle.o
# 	g++ Polygon.o Rectangle.o Triangle.o main.cpp -o main
all: ../lib/ReadIQ.o
	g++ ../lib/ReadIQ.o main.cpp -o main

# # the Polygon.o object file needs recompiled if Polygon.cpp or Polygon.hpp changes
# Polygon.o: Polygon.cpp Polygon.hpp
# 	g++ -c Polygon.cpp -o Polygon.o

# # the Rectangle.o object file needs recompiled if Rectangle.cpp or Rectangle.hpp changes
# Rectangle.o: Rectangle.cpp Rectangle.hpp
# 	g++ -c Rectangle.cpp -o Rectangle.o

# the ReadIQ.o object file needs recompiled if ReadIQ.cpp or ReadIQ.hpp changes
ReadIQ.o: ../lib/ReadIQ.cpp ../lib/ReadIQ.hpp
	g++ -c ../lib/ReadIQ.cpp -o ../lib/ReadIQ.o


# clean - delete the compiled version of your program and
# any object files or other temporary files created during compilation.
clean:
	rm -f *.o main