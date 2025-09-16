CXX=g++
CPPFLAGS=-g -fpermissive -I/usr/include/libusb-1.0 -I../../libpixyusb2/include -I../../arduino/libraries/Pixy2
#CPPFLAGS=-g -fpermissive -I/usr/include/libusb-1.0 -I../../libpixyusb2/include -I../../arduino/libraries/Pixy2 -ljsoncpp -L/usr/lib -I/usr/include/jsoncpp
#LDLIBS=../../../../build/libpixyusb2/libpixy2.a -lusb-1.0
LDLIBS=../../../../build/libpixyusb2/libpixy2.a -lusb-1.0 -lcurl -lpthread

#SRCS=final-cam.cpp
#SRCS=get_raw_frame.cpp
#SRCS=multi_cam.cpp
SRCS=multi-cam-custom.cpp



#SRCS=backup_test.cpp
#SRCS=multi_cam.cpp
#SRCS=multi-cam-custom.cpp
#SRCS=test.cpp
OBJS=$(subst .cpp,.o,$(SRCS))

#all: get_blocks
all: get_blocks

clean:
	#rm -f *.o final-cam 
	#rm -f *.o get_raw_frame 
	rm -f *.o multi-cam-custom 



	#rm -f *.o multi-cam 
	#rm -f *.o test 
	#rm -f *.o get_blocks_cpp_demo


get_blocks: $(OBJS)
	#$(CXX) $(LDFLAGS) -o final-cam $(OBJS) $(LDLIBS)
	#$(CXX) $(LDFLAGS) -o get_raw_frame $(OBJS) $(LDLIBS)
	$(CXX) $(LDFLAGS) -o multi-cam-custom $(OBJS) $(LDLIBS)

	#$(CXX) $(LDFLAGS) -o multi-cam $(OBJS) $(LDLIBS)
	#$(CXX) $(LDFLAGS) -o backup_test $(OBJS) $(LDLIBS)
	#$(CXX) $(LDFLAGS) -o get_blocks_cpp_demo $(OBJS) $(LDLIBS)
	#$(CXX) $(LDFLAGS) -o test $(OBJS) $(LDLIBS)
