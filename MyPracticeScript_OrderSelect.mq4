//+------------------------------------------------------------------+
//|                                 MyPracticeScript_OrderSelect.mq4 
//|                                        Copyright 2015,Lucas Liew 
//|                                  lucas@blackalgotechnologies.com 
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Black Algo Technologies Pte Ltd"
#property link      "lucas@blackalgotechnologies.com"
#property strict

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   
   int Orders=0;
   for(int i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
         Print(OrderTicket());
         Print(OrderType());
     }

  }
//+------------------------------------------------------------------+
