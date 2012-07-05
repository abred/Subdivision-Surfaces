#-------------------------------------------------
#
# Project created by QtCreator 2011-08-16T19:31:05
#
#-------------------------------------------------

QT       += core gui opengl

TARGET = treehugger
TEMPLATE = app

DEPENDPATH += /usr/include
INCLUDEPATH += ../include/ /usr/include/ /usr/local/include 3rdparty/tuio 3rdparty/oscpack ui GeneratedFiles
LIBS = -L/usr/lib/ -L/usr/local/lib -L../lib -L/opt/AMDAPP/lib/x86_64 -lGL -lGLEW -lIL -lOpenCL

DESTDIR = bin
SOURCES += main.cpp \
    tree.cpp \
    shader.cpp \
    qtuio.cpp \
    openGLQtContext.cpp \
    ocl.cpp \
    mainWindow.cpp \
    lsystem.cpp \
    externalFunc.cpp \
    cylinder.cpp \
    ContextSourceCL.cpp \
    3rdparty/tuio/TuioTime.cpp \
    3rdparty/tuio/TuioServer.cpp \
    3rdparty/tuio/TuioClient.cpp \
    3rdparty/oscpack/osc/OscTypes.cpp \
    3rdparty/oscpack/osc/OscReceivedElements.cpp \
    3rdparty/oscpack/osc/OscPrintReceivedElements.cpp \
    3rdparty/oscpack/osc/OscOutboundPacketStream.cpp \
    3rdparty/oscpack/ip/IpEndpointName.cpp \
    3rdparty/oscpack/ip/posix/UdpSocket.cpp \
    3rdparty/oscpack/ip/posix/NetworkingUtils.cpp

HEADERS  += mainwindow.h \
    tree.h \
    shader.h \
    qtuio.h \
    openGLQtContext.h \
    ocl.h \
    mainWindow.h \
    lsystem.hpp \
    externalFunc.h \
    cylinder.h \
    contextSourceCL.h \
    3rdparty/tuio/TuioTime.h \
    3rdparty/tuio/TuioServer.h \
    3rdparty/tuio/TuioPoint.h \
    3rdparty/tuio/TuioObject.h \
    3rdparty/tuio/TuioListener.h \
    3rdparty/tuio/TuioCursor.h \
    3rdparty/tuio/TuioContainer.h \
    3rdparty/tuio/TuioClient.h \
    3rdparty/oscpack/osc/OscTypes.h \
    3rdparty/oscpack/osc/OscReceivedElements.h \
    3rdparty/oscpack/osc/OscPrintReceivedElements.h \
    3rdparty/oscpack/osc/OscPacketListener.h \
    3rdparty/oscpack/osc/OscOutboundPacketStream.h \
    3rdparty/oscpack/osc/OscHostEndianness.h \
    3rdparty/oscpack/osc/OscException.h \
    3rdparty/oscpack/osc/MessageMappingOscPacketListener.h \
    3rdparty/oscpack/ip/UdpSocket.h \
    3rdparty/oscpack/ip/TimerListener.h \
    3rdparty/oscpack/ip/PacketListener.h \
    3rdparty/oscpack/ip/NetworkingUtils.h \
    3rdparty/oscpack/ip/IpEndpointName.h

OTHER_FILES += \
    teller.vert \
    teller.frag \
    solver.cl \
    calcRot.vert \
    calcRot.geom \
    calcRot.frag \
    applyRot.vert \
    applyRot.geom \
    applyRot.frag \
    rinde_neu.jpg \
    gras.jpg \
    boden.jpg \
    blatt.png
