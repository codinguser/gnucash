
#include <Xm/Xm.h>
#include <Xm/Form.h>
#include <Xm/MainW.h>

#include "datecell.h"
#include "pricecell.h"
#include "table.h"
#include "recncell.h"
#include "textcell.h"

#define DATE_CELL_C  0
#define DATE_CELL_R  0

#define DESC_CELL_C  2
#define DESC_CELL_R  0

#define MEMO_CELL_C  2
#define MEMO_CELL_R  1

#define RECN_CELL_C  3
#define RECN_CELL_R  0

#define CRED_CELL_C  4
#define CRED_CELL_R  0

#define DEBT_CELL_C  5
#define DEBT_CELL_R  0

#define BALN_CELL_C  6
#define BALN_CELL_R  0

#define MAX_COLS 7

typedef struct _BasicRegister {
   Table       * table;
   CellBlock   * cursor;
   CellBlock   * header;
   SingleCell  * dateCell;
   SingleCell  * descCell;
   SingleCell  * memoCell;
   SingleCell  * recnCell;
   PriceCell   * creditCell;
   PriceCell   * debitCell;

} BasicRegister;

BasicRegister * xaccMallocBasicRegister (void);
void            xaccInitBasicRegister (BasicRegister *);

/* ================================= */

BasicRegister * xaccMallocBasicRegister (void)
{
   BasicRegister * reg;
   reg = (BasicRegister *) malloc (sizeof (BasicRegister));
   xaccInitBasicRegister (reg);
   return reg;
}

/* ================================= */

void xaccInitBasicRegister (BasicRegister *reg)
{
   Table * table;
   CellBlock *curs, *header;
   SingleCell *cell;

   /* define the header */

   header = xaccMallocCellBlock (1, MAX_COLS);
   reg->header = header;

   cell = (SingleCell *) xaccMallocDateCell();
   cell->width = 9;
   xaccAddCell (header, cell, 0, DATE_CELL_C);
   xaccSetSingleCellValue (cell, "Date");
   
   cell = xaccMallocTextCell();
   cell->width = 19;
   xaccAddCell (header, cell, 0, DESC_CELL_C);
   xaccSetSingleCellValue (cell, "Description");

   cell = xaccMallocRecnCell();
   cell->width = 1;
   xaccAddCell (header, cell, 0, RECN_CELL_C);
   xaccSetSingleCellValue (cell, "R");

   cell = (SingleCell *) xaccMallocPriceCell();
   cell->width = 9;
   xaccAddCell (header, cell, 0, CRED_CELL_C);
   xaccSetSingleCellValue (cell, "Credit");
   
   cell = (SingleCell *) xaccMallocPriceCell();
   cell->width = 9;
   xaccAddCell (header, cell, 0, DEBT_CELL_C);
   xaccSetSingleCellValue (cell, "Debit");

   cell = (SingleCell *) xaccMallocPriceCell();
   cell->width = 9;
   xaccAddCell (header, cell, 0, BALN_CELL_C);
   xaccSetSingleCellValue (cell, "Balance");

   
   /* --------------------------- */
   curs = xaccMallocCellBlock (2, MAX_COLS);
   reg->cursor = curs;
   
   cell = (SingleCell *) xaccMallocDateCell();
   cell->width = 9;
   xaccAddCell (curs, cell, DATE_CELL_R, DATE_CELL_C);
   reg->dateCell = cell;
   
   cell = xaccMallocTextCell();
   cell->width = 9;
   xaccAddCell (curs, cell, DESC_CELL_R, DESC_CELL_C);
   reg->descCell = cell;
   
   cell = xaccMallocTextCell();
   cell->width = 9;
   xaccAddCell (curs, cell, MEMO_CELL_R, MEMO_CELL_C);
   reg->memoCell = cell;

   cell = xaccMallocRecnCell();
   cell->width = 1;
   xaccAddCell (curs, cell, RECN_CELL_R, RECN_CELL_C);
   reg->memoCell = cell;

   reg->creditCell = xaccMallocPriceCell();
   reg->creditCell->cell.width = 9;
   xaccAddCell (curs, &(reg->creditCell->cell), CRED_CELL_R, CRED_CELL_C);
   
   reg->debitCell = xaccMallocPriceCell();
   reg->debitCell->cell.width = 9;
   xaccAddCell (curs, &(reg->debitCell->cell), DEBT_CELL_R, DEBT_CELL_C);
   
   table =  xaccMallocTable (0, 0);
   table -> header = header;
   xaccSetCursor (table, curs);
   xaccInitTable (table, 5, 1);
   reg->table = table;
}

/* ================================= */

main (int argc, char *argv[]) {
  Widget toplevel, mainwindow, actionform;
  XtAppContext app;
  BasicRegister *reg;


  toplevel = XtVaAppInitialize( &app, "Xacc", NULL, 0,
                                &argc, argv, NULL,
                                NULL );


  mainwindow = XtVaCreateManagedWidget( "mainwindow", 
                                  xmMainWindowWidgetClass, toplevel, 
                                        XmNdeleteResponse, XmDESTROY,
                                        NULL );

  actionform = XtVaCreateWidget( "form", 
                                 xmFormWidgetClass, mainwindow,
                                 NULL );

  reg = xaccMallocBasicRegister ();

  xaccCreateTable (reg->table, actionform, "yodudue");

  XtManageChild (actionform);

  XtRealizeWidget(toplevel);
  XtRealizeWidget (reg->table->reg);

  XtAppMainLoop(app);

  return 0;
  }


