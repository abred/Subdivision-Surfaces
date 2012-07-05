#ifndef __MAINWINDOW_HPP_
#define __MAINWINDOW_HPP_
#include <GL/glew.h>

#include <QtCore/QtCore>
#include <QtGui/QtGui>
//#include <QtOpenGL>
#include <QtGui/QApplication>
#include <QtGui/QMessageBox>
#include <qwidget.h>
#include <qimage.h>
//#include <QtOpenGL>
//#include <QGLWidget>
#include <QObject>
#include <QTimerEvent>
#include <QPainter>
#include <QList>

#include "openGLQtContext.h"
#include "qtuio.h"

namespace Ui 
{ 
	class Widget; 
}

class MainWindow : public QMainWindow
{
	Q_OBJECT

public:
	explicit MainWindow (QWidget *parent = 0);
	~MainWindow ();
	QTuio *qTUIO;
	
	int			old_value;
	int			max_value;

	public slots:
		void touchSlot(QTouchEvent* touchEvent);

signals:
		void clickedButton1();
		void clickedButton2();
		void clickedButton3();
		void clickedButton4();
		void clickedDial(int value);
		void rotTree(bool);

protected:

private:
	Ui::Widget *ui;
	OpenGLQtContext * qgl;
	

private slots:
    void pushButton1Clicked();

    void pushButton2Clicked();

    void pushButton3Clicked();

    void pushButton4Clicked();

    void dialValueChanged(int value);


};

#endif // __MAINWINDOW_HPP_
