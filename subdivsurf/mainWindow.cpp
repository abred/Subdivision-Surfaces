#include "mainWindow.h"

#include "ui_widget.h"


MainWindow::MainWindow(QWidget *parent) : 
			QMainWindow(parent),
			ui(new Ui::Widget),
			old_value		(0),
			max_value		(0)

{
	QGLFormat* form = new QGLFormat();
	form->setVersion(4, 0);
	form->setDoubleBuffer (TRUE);
	form->setDepth (TRUE);
	form->setAlpha (TRUE);
	form->setProfile (QGLFormat::CoreProfile);

#ifdef _DEBUG
	form->setOption (QGL::NoDeprecatedFunctions);
#endif

	qgl = new OpenGLQtContext (form, (QWidget*)0);

	delete form;	form = 0;

	ui->setupUi(this);
	ui->GLSpace->addWidget(qgl);
	//setCentralWidget(qgl);

	qTUIO = new QTuio(this);

	qTUIO->run();

	connect(qTUIO, SIGNAL(touchSignal(QTouchEvent*)), this, SLOT(touchSlot(QTouchEvent*)));
	connect(this, SIGNAL(rotTree(bool)), qgl, SLOT(rotTree(bool)));	

	connect(this, SIGNAL(clickedButton1()), this, SLOT(pushButton1Clicked()));
	connect(ui->pushButton_1, SIGNAL(clicked()), this, SLOT(pushButton1Clicked()));
	
	connect(this, SIGNAL(clickedButton2()), this, SLOT(pushButton2Clicked()));
	connect(ui->pushButton_2, SIGNAL(clicked()), this, SLOT(pushButton2Clicked()));
	
	connect(this, SIGNAL(clickedButton3()), this, SLOT(pushButton3Clicked()));
	connect(ui->pushButton_3, SIGNAL(clicked()), this, SLOT(pushButton3Clicked()));
	
	connect(this, SIGNAL(clickedButton4()), this, SLOT(pushButton4Clicked()));
	connect(ui->pushButton_4, SIGNAL(clicked()), this, SLOT(pushButton4Clicked()));

	connect(this, SIGNAL(clickedDial(int)), ui->dial, SLOT(setValue(int)));
	connect(ui->dial, SIGNAL(valueChanged(int)), this, SLOT(dialValueChanged(int)));

}

MainWindow::~MainWindow()
{
	delete ui;
	delete qgl;
	delete qTUIO;
}


void MainWindow::touchSlot(QTouchEvent* touchEvent)
{
	QList<QTouchEvent::TouchPoint> list = touchEvent->touchPoints();
	QPointF position(0.0f, 0.0f);
	if(!(list.isEmpty()) && touchEvent->touchPointStates() == Qt::TouchPointPressed)
	{
		position = list.first().pos();
		QPoint posTouchPoint(position.x(), position.y());

		QPoint posTouchPointRel = posTouchPoint - ui->pushButton_1->pos() - ui->groupBox->pos();	
		if (ui->pushButton_1->rect().contains(posTouchPointRel))
		{
			emit clickedButton1();
		}

		posTouchPointRel = posTouchPoint - ui->pushButton_2->pos() - ui->groupBox->pos();
		if (ui->pushButton_2->rect().contains(posTouchPointRel))
		{
			emit clickedButton2();
		}

		posTouchPointRel = posTouchPoint - ui->pushButton_3->pos() - ui->groupBox->pos();
		if (ui->pushButton_3->rect().contains(posTouchPointRel))
		{
			emit clickedButton3();
		}

		posTouchPointRel = posTouchPoint - ui->pushButton_4->pos() - ui->groupBox->pos();
		if (ui->pushButton_4->rect().contains(posTouchPointRel))
		{
			emit clickedButton4();
		}

		posTouchPointRel = posTouchPoint - ui->dial->pos();
		if (ui->dial->rect().contains(posTouchPointRel))
		{    
			double yy = (double)ui->dial->height()/2.0 - posTouchPointRel.y();
			double xx = (double)posTouchPointRel.x() - ui->dial->width()/2.0;
			double a = (xx || yy) ? qAtan2(yy, xx) : 0;

			if (a < 3.14159 / -2)
				a = a + 3.14159 * 2;

			int dist = 0;
			int minv = ui->dial->minimum(), maxv = ui->dial->maximum();
			
			if (ui->dial->minimum() < 0) {
				dist = -ui->dial->minimum();
				minv = 0;
				maxv = ui->dial->maximum() + dist;
			}

			int r = maxv - minv;
			int v;
			if (ui->dial->wrapping())
				v =  (int)(0.5 + minv + r * (3.14159 * 3 / 2 - a) / (2 * 3.14159));
			else
				v =  (int)(0.5 + minv + r* (3.14159 * 4 / 3 - a) / (3.14159 * 10 / 6));

			if (dist > 0)
				v -= dist;
			
			int boundV = 0;
			if( v <= ui->dial->minimum() )
			{
				boundV = ui->dial->minimum();
			}
			else if ( v >= ui->dial->maximum() )
			{
				boundV = ui->dial->maximum();
			}
			else
			{
				boundV = v;
			}

			int value = !(ui->dial->invertedAppearance()) ? boundV : ui->dial->maximum() - boundV;
			emit clickedDial(value);
		}

	}
	else if(!(list.isEmpty()) && touchEvent->touchPointStates() == Qt::TouchPointMoved)
	{
		position = list.first().pos();
		if (position.y() > 800)
		{
			emit rotTree((list.first().pos().x() - list.first().lastPos().x()) > 0 ? 1 : 0);
		}
	}
}


void MainWindow::pushButton1Clicked()
{
	qgl->killTree("Baum_1.txt");
	std::cout << "QGL: neuer Baum wird erstellt...\n\n";
	if (ui->dial->value() == 0)
	{
		dialValueChanged(0);
	}
	else
	{
		ui->dial->setValue(0);
	}
	old_value = 0;
	max_value = 0;
}

void MainWindow::pushButton2Clicked()
{
	qgl->killTree("Baum_2.txt");
	std::cout << "QGL: neuer Baum wird erstellt...\n\n";
	if (ui->dial->value() == 0)
	{
		dialValueChanged(0);
	}
	else
	{
		ui->dial->setValue(0);
	}
	old_value = 0;
	max_value = 0;
}

void MainWindow::pushButton3Clicked()
{
	qgl->killTree("Baum_3.txt");
	std::cout << "QGL: neuer Baum wird erstellt...\n\n";
	if (ui->dial->value() == 0)
	{
		dialValueChanged(0);
	}
	else
	{
		ui->dial->setValue(0);
	}
	old_value = 0;
	max_value = 0;

}

void MainWindow::pushButton4Clicked()
{
	qgl->makeWind();
}

void MainWindow::dialValueChanged(int value)
{
	ui->dial->setDisabled(1);

	if(value > max_value)
	{
		for(int i = old_value+1; i <= value; ++i)
		{
			qgl->setIteration(i);
		}
		max_value = value;
	}
	else
	{
		qgl->setIteration(value);
	}
	qgl->setFocus();
	
	ui->dial->setDisabled(0);
	qgl->setFocus();
	old_value = value;
}

