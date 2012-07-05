#include <iostream>

#include <GL/glew.h>

//#include <QtCore>
//#include <QtGui>
#include <QApplication>
#include <QGLWidget>


#include "openGLQtContext.h"

int main(int argc, char **argv)
{
	QApplication a(argc, argv);
	if (!QGLFormat::hasOpenGL()) {
		std::cerr << "This system does not support OpenGL.\n";
		return -1;
	}

	QGLFormat* form = new QGLFormat();
	form->setVersion(4, 2);
	form->setDoubleBuffer (TRUE);
	form->setDepth (TRUE);
	form->setAlpha (TRUE);
	form->setProfile (QGLFormat::CoreProfile);

//#ifdef _DEBUG
	form->setOption (QGL::NoDeprecatedFunctions);
//#endif

	QGLWidget* widget = new OpenGLQtContext (form, (QWidget*)0);
	widget->resize(800, 600);
//	widget.showFullScreen();
	widget->show();
	return a.exec();
}
