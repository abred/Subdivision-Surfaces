######################################################################
# Automatically generated by qmake (2.01a) Thu Jul 5 21:03:20 2012
######################################################################

QT        += opengl
CONFIG += console

QMAKE_CXXFLAGS += -std=c++0x

TEMPLATE = app
TARGET = 
DEPENDPATH += 

INCLUDEPATH += ../include/ /usr/include/ /usr/local/include /opt/AMDAPP/include/
LIBS =  -L/home/abred/qtDebug/lib/ -L/usr/lib64/ -L/usr/lib/ -L/usr/local/lib -L../lib -lGL -lGLEW -lIL

# Input
HEADERS += openGLQtContext.h
		
SOURCES += main.cpp \
		openGLQtContext.cpp
