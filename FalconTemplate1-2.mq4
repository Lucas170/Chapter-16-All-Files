//+------------------------------------------------------------------+
//|                                          Falcon EA Template v1.2
//|                                        Copyright 2015,Lucas Liew 
//|                                  lucas@blackalgotechnologies.com 
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Black Algo Technologies Pte Ltd"
#property link      "lucas@blackalgotechnologies.com"

//+------------------------------------------------------------------+
//| Setup                                               
//+------------------------------------------------------------------+
extern string  Header1 = "----------Trading Rules Variables-----------";
extern int     FastMAPeriod=10;
extern int     SlowMAPeriod=40;

extern string  Header2 = "----------Position Sizing Settings-----------";
extern string  Lot_explanation = "If IsSizingOn = true, Lots variable will be ignored";
extern double  Lots = 1;
extern bool    IsSizingOn = true;
extern double  Risk = 1; // Risk per trade (in percentage)

extern string  Header3 = "----------TP & SL Settings-----------";

extern double  FixedStopLoss = 0; // Hard Stop in Pips. Will be overridden if vol-based SL is true 
extern bool    IsVolatilityStopOn = True;
extern double     VolBasedSLMultipler = 1; // Stop Loss Amount in units of Volatility

extern double  FixedTakeProfit = 0; // Hard Take Profit in Pips. Will be overridden if vol-based TP is true 
extern bool    IsVolatilityTakeProfitOn = True; 
extern double     VolBasedTPMultipler = 2; // Take Profit Amount in units of Volatility

extern string  Header4 = "----------Volatility Measurement Settings-----------";
extern int     atr_period = 14;

extern string  Header5 = "----------Max Orders-----------";
extern int     MaxPositionsAllowed = 5;

extern string  Header6 = "----------EA General Settings-----------";
extern int     MagicNumber = 12345;
extern int     Slippage = 3; // In Pips
extern bool    IsECNbroker = false; // Is your broker an ECN
extern bool    OnJournaling = true; // Add EA updates in the Journal Tab

string  InternalHeader1="----------Errors Handling Settings-----------";
int     RetryInterval=100; // Pause Time before next retry (in milliseconds)
int     MaxRetriesPerTick=10;

string  InternalHeader2="----------Service Variables-----------";

double Stop;
double Take;
double P, YenPairAdjustFactor;
double myATR;
double FastMA1, SlowMA1;
int CrossTriggered;

//+------------------------------------------------------------------+
//| End of Setup                                          
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert Initialization                                    
//+------------------------------------------------------------------+
int init()
  {
      P = GetP(); // To account for 5 digit brokers. Used to convert pips to decimal place
      YenPairAdjustFactor = GetYenAdjustFactor(); // Adjust for YenPair
      
      start();
   return(0);
  }
//+------------------------------------------------------------------+
//| End of Expert Initialization                            
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert Deinitialization                                  
//+------------------------------------------------------------------+
int deinit()
  {
//----

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| End of Expert Deinitialization                          
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert start                                             
//+------------------------------------------------------------------+
int start()
  {
  
      //----------Entry & Exit Variables-----------
      
      FastMA1=iMA(Symbol(),Period(),FastMAPeriod,0, MODE_SMA, PRICE_CLOSE,1); // Shift 1
      SlowMA1=iMA(Symbol(),Period(),SlowMAPeriod,0, MODE_SMA, PRICE_CLOSE,1); // Shift 1

      CrossTriggered = Crossed(FastMA1, SlowMA1);
      
      //----------TP & SL Variables-----------
      
      myATR = iATR(NULL,Period(),atr_period,1);
      
      Stop=VolBasedStopLoss(IsVolatilityStopOn, FixedStopLoss, myATR, VolBasedSLMultipler, P);
      Take=VolBasedTakeProfit(IsVolatilityTakeProfitOn, FixedTakeProfit, myATR, VolBasedTPMultipler, P);
   
      //----------Exit Rules (All Opened Positions)-----------
      
   if(CountPosOrders(MagicNumber, OP_BUY)>=1 || CountPosOrders(MagicNumber, OP_SELL)>=1){
      if(CountPosOrders(MagicNumber, OP_BUY)>=1 && ExitSignal(CrossTriggered)==1){ // Close Long Positions
         //CloseOrderPosition(OP_BUY, OnJournaling, MagicNumber, Slippage, P); 
      }
      if(CountPosOrders(MagicNumber, OP_SELL)>=1 && ExitSignal(CrossTriggered)==2){ // Close Short Positions
         //CloseOrderPosition(OP_SELL, OnJournaling, MagicNumber, Slippage, P);
      }
   }   

      //----------Entry Rules (Market and Pending) -----------
      
   if(IsMaxPositionsReached(MaxPositionsAllowed, MagicNumber, OnJournaling) == False){
      if(EntrySignal(CrossTriggered)==1){ // Open Long Positions
         OpenPositionMarket(OP_BUY, GetLot(IsSizingOn, Lots, Risk, YenPairAdjustFactor, Stop, P), Stop, Take, MagicNumber, Slippage, OnJournaling, P, IsECNbroker, MaxRetriesPerTick);
         //OpenPositionPending(OP_BUYLIMIT, Ask - myATR, TimeCurrent() + 60*60*1000, GetLot(IsSizingOn, Lots, Risk, YenPairAdjustFactor, Stop, P), Stop, Take, MagicNumber, Slippage, OnJournaling, P, IsECNbroker, MaxRetriesPerTick);
        }

      if(EntrySignal(CrossTriggered)==2){ // Open Short Positions
         OpenPositionMarket(OP_SELL, GetLot(IsSizingOn, Lots, Risk, YenPairAdjustFactor, Stop, P), Stop, Take, MagicNumber, Slippage, OnJournaling, P, IsECNbroker, MaxRetriesPerTick);
         //OpenPositionPending(OP_SELLLIMIT, Ask + myATR, TimeCurrent() + 60*60*1000, GetLot(IsSizingOn, Lots, Risk, YenPairAdjustFactor, Stop, P), Stop, Take, MagicNumber, Slippage, OnJournaling, P, IsECNbroker, MaxRetriesPerTick);
        }
   }

      //----------Pending Order Management-----------

   if(DayOfWeek()!=0) { //Insert pending order deletion rules here
      CloseOrderPosition(OP_BUYLIMIT, OnJournaling, MagicNumber, Slippage, P);
      CloseOrderPosition(OP_SELLLIMIT, OnJournaling, MagicNumber, Slippage, P);
   }
      
      

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| End of expert start function                                     |
//+------------------------------------------------------------------+

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//|                     FUNCTIONS LIBRARY                                   
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*

Content:
1) EntrySignal
2) ExitSignal
3) GetLot
4) CheckLot
5) CountPosOrders
6) IsMaxPositionsReached
7) OpenPositionMarket
8) OpenPositionPending
9) CloseOrderPosition
10) GetP
11) GetYenAdjustFactor
12) VolBasedStopLoss
13) VolBasedTakeProfit
14) Crossed
15) HandleTradingEnvironment
16) GetErrorDescription

*/



//+------------------------------------------------------------------+
//| ENTRY SIGNAL                                                     |
//+------------------------------------------------------------------+
int EntrySignal(int CrossOccurred){
// Type: Customisable 
// Modify this function to suit your trading robot

// This function checks for entry signals

   int   entryOutput=0;

   if(CrossOccurred == 1){
      entryOutput=1; // Return 1 for Buy Signals
   }

   if(CrossOccurred == 2){
      entryOutput=2; // Return 2 for Short Signals
   }
     
   return(entryOutput); 
  }

//+------------------------------------------------------------------+
//| End of ENTRY SIGNAL                                              |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Exit SIGNAL                                                      |
//+------------------------------------------------------------------+
int ExitSignal(int CrossOccurred){
// Type: Customisable 
// Modify this function to suit your trading robot

// This function checks for exit signals

   int   ExitOutput=0;

   if(CrossOccurred == 2)
     {
      ExitOutput=1; // Close Long Positions
     }

   if(CrossOccurred == 1)
     {
      ExitOutput=2; // Close Short Positions
     }

   return(ExitOutput); 
  }

//+------------------------------------------------------------------+
//| End of Exit SIGNAL                                               
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Position Sizing Algo               
//+------------------------------------------------------------------+
// Type: Customisable 
// Modify this function to suit your trading robot

// This is our sizing algorithm
   
double GetLot(bool IsSizingOnTrigger,double FixedLots, double RiskPerTrade, int YenAdjustment, double STOP, int K) {
   
   double output;
      
   if (IsSizingOnTrigger == true) {
      output = RiskPerTrade * 0.01 * AccountBalance() / (MarketInfo(Symbol(),MODE_LOTSIZE) * MarketInfo(Symbol(),MODE_TICKVALUE) * STOP * K * Point); // Sizing Algo based on account size
      output = output * YenAdjustment; // Adjust for Yen Pairs
   } else {
      output = FixedLots;
   }
   output = NormalizeDouble(output, 2); // Round to 2 decimal place
   return(output);
}
   
//+------------------------------------------------------------------+
//| End of Position Sizing Algo               
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| CHECK LOT
//+------------------------------------------------------------------+
double CheckLot(double Lot, bool Journaling){
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function checks if our Lots to be trade satisfies any broker limitations

   double LotToOpen=0;
   LotToOpen=NormalizeDouble(Lot,2);
   LotToOpen=MathFloor(LotToOpen/MarketInfo(Symbol(),MODE_LOTSTEP))*MarketInfo(Symbol(),MODE_LOTSTEP);
   
   if(LotToOpen<MarketInfo(Symbol(),MODE_MINLOT))LotToOpen=MarketInfo(Symbol(),MODE_MINLOT);
   if(LotToOpen>MarketInfo(Symbol(),MODE_MAXLOT))LotToOpen=MarketInfo(Symbol(),MODE_MAXLOT);
   LotToOpen=NormalizeDouble(LotToOpen,2);
   
   if(Journaling && LotToOpen!=Lot)Print("EA Journaling: Trading Lot has been changed by CheckLot function. Requested lot: "+Lot+". Lot to open: "+LotToOpen);
   
   return(LotToOpen);
  }
//+------------------------------------------------------------------+
//| End of CHECK LOT
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| COUNT POSITIONS 
//+------------------------------------------------------------------+
int CountPosOrders(int Magic, int TYPE){
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function counts number of positions/orders of OrderType TYPE

   int Orders=0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==TYPE)
         Orders++;
     }
   return(Orders);
   
  }
//+------------------------------------------------------------------+
//| End of COUNT POSITIONS
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| MAX ORDERS                                              
//+------------------------------------------------------------------+
bool IsMaxPositionsReached(int MaxPositions, int Magic, bool Journaling){   
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function checks the number of positions we are holding against the maximum allowed 

      int result = False;
      if (CountPosOrders(Magic, OP_BUY) + CountPosOrders(Magic, OP_SELL) > MaxPositions) {
         result=True;
         if(Journaling)Print("Max Orders Exceeded");
      } else if (CountPosOrders(Magic, OP_BUY) + CountPosOrders(Magic, OP_SELL) == MaxPositions) {
         result=True;
      }
      
      return(result);
      
/* Definitions: Position vs Orders
   
   Position describes an opened trade
   Order is a pending trade
   
   How to use in a sentence: Jim has 5 buy limit orders pending 10 minutes ago. The market just crashed. The orders were executed and he has 5 losing positions now lol.

*/
   }
//+------------------------------------------------------------------+
//| End of MAX ORDERS                                                
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| OPEN FROM MARKET
//+------------------------------------------------------------------+
int OpenPositionMarket(int TYPE, double LOT, double SL, double TP, int Magic, int Slip, bool Journaling, int K, bool ECN, int Max_Retries_Per_Tick){
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function submits new orders

   int tries=0;
   string symbol=Symbol();
   int cmd=TYPE;
   double volume=CheckLot(LOT, Journaling);
   if(MarketInfo(symbol,MODE_MARGINREQUIRED)*volume>AccountFreeMargin())
     {
      Print("Can not open a trade. Not enough free margin to open "+volume+" on "+symbol);
      return(-1);
     }
   int slippage=Slip*K; // Slippage is in points. 1 point = 0.0001 on 4 digit broker and 0.00001 on a 5 digit broker
   string comment=" " + TYPE + "(#" + Magic + ")";
   int magic=Magic;
   datetime expiration=0;
   color arrow_color=0;if(TYPE==OP_BUY)arrow_color=Blue;if(TYPE==OP_SELL)arrow_color=Green;
   double stoploss=0;
   double takeprofit=0;
   double initTP = TP;
   double initSL = SL;
   int Ticket=-1;
   double price=0;
   if(!ECN)
     {
      while(tries<Max_Retries_Per_Tick) // Edits stops and take profits before the market order is placed
        {
         RefreshRates();
         if(TYPE==OP_BUY)price=Ask;if(TYPE==OP_SELL)price=Bid;
         
         // Sets Take Profits and Stop Loss. Check against Stop Level Limitations.
         if(TYPE==OP_BUY && SL!=0)
           {
            stoploss=NormalizeDouble(Ask-SL*K*Point,Digits);
            if(Bid-stoploss<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               stoploss=NormalizeDouble(Bid-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Stop Loss changed from " + initSL + " to " + MarketInfo(Symbol(),MODE_STOPLEVEL)/K + " pips");
            }
           }
         if(TYPE==OP_SELL && SL!=0)
           {
            stoploss=NormalizeDouble(Bid+SL*K*Point,Digits);
            if(stoploss-Ask<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               stoploss=NormalizeDouble(Ask+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Stop Loss changed from " + initSL + " to " + MarketInfo(Symbol(),MODE_STOPLEVEL)/K + " pips");
            }
           }
         if(TYPE==OP_BUY && TP!=0)
           {
            takeprofit=NormalizeDouble(Ask+TP*K*Point,Digits);
            if(takeprofit-Bid<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               takeprofit=NormalizeDouble(Ask+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Take Profit changed from " + initTP + " to " + MarketInfo(Symbol(),MODE_STOPLEVEL)/K + " pips");
            }
           }
         if(TYPE==OP_SELL && TP!=0)
           {
            takeprofit=NormalizeDouble(Bid-TP*K*Point,Digits);
            if(Ask-takeprofit<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               takeprofit=NormalizeDouble(Bid-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Take Profit changed from " + initTP + " to " + MarketInfo(Symbol(),MODE_STOPLEVEL)/K + " pips");
            }
           }
         if(Journaling)Print("EA Journaling: Trying to place a market order...");
         HandleTradingEnvironment(Journaling, RetryInterval);
         Ticket=OrderSend(symbol,cmd,volume,price,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color);
         if(Ticket>0)break;
         tries++;
        }
     }
   if(ECN) // Edits stops and take profits after the market order is placed
     {
      while(tries<Max_Retries_Per_Tick)
        {
         HandleTradingEnvironment(OnJournaling, RetryInterval);
         if(TYPE==OP_BUY)price=Ask;if(TYPE==OP_SELL)price=Bid;
         if(Journaling)Print("EA Journaling: Trying to place a market order...");
         Ticket=OrderSend(symbol,cmd,volume,price,slippage,0,0,comment,magic,expiration,arrow_color);
         if(Ticket>0)break;
         tries++;
        }
      if(Ticket>0 && OrderSelect(Ticket,SELECT_BY_TICKET)==true && (SL!=0 || TP!=0))
        {
        
        // Sets Take Profits and Stop Loss. Check against Stop Level Limitations.
         if(TYPE==OP_BUY && SL!=0)
           {
            stoploss=NormalizeDouble(OrderOpenPrice()-SL*K*Point,Digits);
            if(Bid-stoploss<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               stoploss=NormalizeDouble(Bid-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Stop Loss changed from " + initSL + " to " + (OrderOpenPrice()-stoploss)/(K*Point) + " pips");
            }
           }
         if(TYPE==OP_SELL && SL!=0)
           {
            stoploss=NormalizeDouble(OrderOpenPrice()+SL*K*Point,Digits);
            if(stoploss-Ask<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               stoploss=NormalizeDouble(Ask+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Stop Loss changed from " + initSL + " to " + (stoploss-OrderOpenPrice())/(K*Point) + " pips");
            }
           }
         if(TYPE==OP_BUY && TP!=0)
           {
            takeprofit=NormalizeDouble(OrderOpenPrice()+TP*K*Point,Digits);
            if(takeprofit-Bid<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               takeprofit=NormalizeDouble(Ask+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Take Profit changed from " + initTP + " to " + (takeprofit-OrderOpenPrice())/(K*Point) + " pips");
            }
           }
         if(TYPE==OP_SELL && TP!=0)
           {
            takeprofit=NormalizeDouble(OrderOpenPrice()-TP*K*Point,Digits);
            if(Ask-takeprofit<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               takeprofit=NormalizeDouble(Bid-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Take Profit changed from " + initTP + " to " + (OrderOpenPrice()-takeprofit)/(K*Point) + " pips");
            }
           }
         bool ModifyOpen=false;
         while(!ModifyOpen)
           {
            HandleTradingEnvironment(Journaling, RetryInterval);
            ModifyOpen=OrderModify(Ticket,OrderOpenPrice(),stoploss,takeprofit,expiration,arrow_color);
            if(Journaling && !ModifyOpen)Print("EA Journaling: Take Profit and Stop Loss not set. Error Description: "+GetErrorDescription(GetLastError()));
           }
        }
     }
   if(Journaling && Ticket<0)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
   if(Journaling && Ticket>0){
      Print("EA Journaling: Order successfully placed. Ticket: "+Ticket);
   }
   return(Ticket);
  }
//+------------------------------------------------------------------+
//| End of OPEN FROM MARKET   
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| OPEN PENDING ORDERS
//+------------------------------------------------------------------+
int OpenPositionPending(int TYPE, double OpenPrice, datetime expiration, double LOT, double SL, double TP, int Magic, int Slip, bool Journaling, int K, bool ECN, int Max_Retries_Per_Tick){
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function submits new pending orders
   OpenPrice = NormalizeDouble(OpenPrice, Digits);
   int tries=0;
   string symbol=Symbol();
   int cmd=TYPE;
   double volume=CheckLot(LOT, Journaling);
   if(MarketInfo(symbol,MODE_MARGINREQUIRED)*volume>AccountFreeMargin())
     {
      Print("Can not open a trade. Not enough free margin to open "+volume+" on "+symbol);
      return(-1);
     }
   int slippage=Slip*K; // Slippage is in points. 1 point = 0.0001 on 4 digit broker and 0.00001 on a 5 digit broker
   string comment=" " + TYPE + "(#" + Magic + ")";
   int magic=Magic;
   color arrow_color=0;if(TYPE==OP_BUYLIMIT || TYPE==OP_BUYSTOP)arrow_color=Blue;if(TYPE==OP_SELLLIMIT || TYPE==OP_SELLSTOP)arrow_color=Green;
   double stoploss=0;
   double takeprofit=0;
   double initTP = TP;
   double initSL = SL;
   int Ticket=-1;
   double price=0;

      while(tries<Max_Retries_Per_Tick) // Edits stops and take profits before the market order is placed
        {
         RefreshRates();
         
         // We are able to send in TP and SL when we open our orders even if we are using ECN brokers
         
         // Sets Take Profits and Stop Loss. Check against Stop Level Limitations.
         if((TYPE==OP_BUYLIMIT || TYPE==OP_BUYSTOP) && SL!=0)
           {
            stoploss=NormalizeDouble(OpenPrice-SL*K*Point,Digits);
            if(OpenPrice-stoploss<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               stoploss=NormalizeDouble(OpenPrice-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Stop Loss changed from " + initSL + " to " + (OpenPrice-stoploss)/(K*Point) + " pips");
            }
           }
         if((TYPE==OP_BUYLIMIT || TYPE==OP_BUYSTOP) && TP!=0)
           {
            takeprofit=NormalizeDouble(OpenPrice+TP*K*Point,Digits);
            if(takeprofit-OpenPrice<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               takeprofit=NormalizeDouble(OpenPrice+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Take Profit changed from " + initTP + " to " + (takeprofit-OpenPrice)/(K*Point) + " pips");
            }
           }
         if((TYPE==OP_SELLLIMIT || TYPE==OP_SELLSTOP) && SL!=0)
           {
            stoploss=NormalizeDouble(OpenPrice+SL*K*Point,Digits);
            if(stoploss-OpenPrice<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               stoploss=NormalizeDouble(OpenPrice+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Stop Loss changed from " + initSL + " to " + (OpenPrice-stoploss)/(K*Point) + " pips");
            }
           }
         if((TYPE==OP_SELLLIMIT || TYPE==OP_SELLSTOP) && TP!=0)
           {
            takeprofit=NormalizeDouble(OpenPrice-TP*K*Point,Digits);
            if(OpenPrice-takeprofit<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) {
               takeprofit=NormalizeDouble(OpenPrice-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Take Profit changed from " + initTP + " to " + (OrderOpenPrice()-stoploss)/(K*Point) + " pips");
            }
           }
         if(Journaling)Print("EA Journaling: Trying to place a pending order...");
         HandleTradingEnvironment(Journaling, RetryInterval);
         
         //Note: We did not modify Open Price if it breaches the Stop Level Limitations as Open Prices are sensitive and important. It is unsafe to change it automatically.
         Ticket=OrderSend(symbol,cmd,volume,OpenPrice,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color);
         if(Ticket>0)break;
         tries++;
        }
     
   if(Journaling && Ticket<0)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
   if(Journaling && Ticket>0){
      Print("EA Journaling: Order successfully placed. Ticket: "+Ticket);
   }
   return(Ticket);
  }
//+------------------------------------------------------------------+
//| End of OPEN PENDING ORDERS 
//+------------------------------------------------------------------+ 
//+------------------------------------------------------------------+
//| CLOSE/DELETE ORDERS AND POSITIONS
//+------------------------------------------------------------------+
bool CloseOrderPosition(int TYPE, bool Journaling, int Magic, int Slip , int K){
// Type: Fixed Template 
// Do not edit unless you know what you're doing

   for(int i=0; i<OrdersTotal(); i++)
     {
      // Note: Once pending orders become positions, OP_BUYLIMIT AND OP_BUYSTOP becomes OP_BUY, OP_SELLLIMIT and OP_SELLSTOP becomes OP_SELL
      if(TYPE==OP_BUY || TYPE==OP_SELL)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==TYPE)
           {
            bool Closing=false;
            double Price=0;
            color arrow_color=0;if(TYPE==OP_BUY)arrow_color=Blue;if(TYPE==OP_SELL)arrow_color=Green;
            if(Journaling)Print("EA Journaling: Trying to close position "+OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling, RetryInterval);
            if(TYPE==OP_BUY)Price=Bid; if(TYPE==OP_SELL)Price=Ask;
            Closing=OrderClose(OrderTicket(),OrderLots(),Price,Slip*K,arrow_color);
            if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Closing)Print("EA Journaling: Position successfully closed.");
           }
        }
      else
        {
         bool Delete=false;
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==TYPE)
           {
            if(Journaling)Print("EA Journaling: Trying to delete order "+OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling, RetryInterval);
            Delete=OrderDelete(OrderTicket(),CLR_NONE);
            if(Journaling && !Delete)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Delete)Print("EA Journaling: Order successfully deleted.");
           }
        }
     }
   if(CountPosOrders(Magic, TYPE)==0)return(true); else return(false);
  }
//+------------------------------------------------------------------+
//| End of CLOSE/DELETE ORDERS  
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Check for 4/5 Digits Broker              
//+------------------------------------------------------------------+ 
int GetP() {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function returns P, which is used for converting pips to decimals/points

   int output;
   if(Digits == 5 || Digits == 3) output = 10;else output = 1; 
   return(output);

/* Some definitions: Pips vs Point

1 pip = 0.0001 on a 4 digit broker and 0.00010 on a 5 digit broker
1 point = 0.0001 on 4 digit broker and 0.00001 on a 5 digit broker
  
*/ 
   
}
//+------------------------------------------------------------------+
//| End of Check for 4/5 Digits Broker               
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Yen Adjustment Factor             
//+------------------------------------------------------------------+ 
int GetYenAdjustFactor() {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function returns a constant factor, which is used for position sizing for Yen pairs

   int output = 1;
   if(Digits == 3 || Digits == 2) output = 100;
   return(output);
}
//+------------------------------------------------------------------+
//| End of Yen Adjustment Factor             
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Volatility-Based Stop Loss                                             
//+------------------------------------------------------------------+
double VolBasedStopLoss(bool isVolatilitySwitchOn, double fixedStop, double volATR, double volMultiplier, int K){ // K represents our P multiplier to adjust for broker digits
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function calculates stop loss amount based on volatility

     double StopL;
         if(!isVolatilitySwitchOn){
            StopL=fixedStop; // If Volatility Stop Loss not activated. Stop Loss = Fixed Pips Stop Loss
         } else {
            StopL=volMultiplier*volATR/(K*Point); // Stop Loss in Pips
         } 
     return(StopL);
  }

//+------------------------------------------------------------------+
//| End of Volatility-Based Stop Loss                  
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Volatility-Based Take Profit                                     
//+------------------------------------------------------------------+

double VolBasedTakeProfit(bool isVolatilitySwitchOn, double fixedTP, double volATR, double volMultiplier, int K){ // K represents our P multiplier to adjust for broker digits
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function calculates take profit amount based on volatility

     double TakeP;
         if(!isVolatilitySwitchOn){
            TakeP=fixedTP; // If Volatility Take Profit not activated. Take Profit = Fixed Pips Take Profit
         } else {
            TakeP=volMultiplier*volATR/(K*Point); // Take Profit in Pips
         }
     return(TakeP);
  }

//+------------------------------------------------------------------+
//| End of Volatility-Based Take Profit                 
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// Cross                                                             
//+------------------------------------------------------------------+

// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function determines if a cross happened between 2 lines/data set

/* 

If Output is 0: No cross happened
If Output is 1: Line 1 crossed Line 2 from Bottom
If Output is 2: Line 1 crossed Line 2 from top 

*/

int Crossed(double line1 , double line2){

   static int CurrentDirection1 = 0;
   static int LastDirection1 = 0;
   static bool FirstTime1 = true;

//----
   if(line1 > line2)
     CurrentDirection1 = 1;  // line1 above line2
   if(line1 < line2)
     CurrentDirection1 = 2;  // line1 below line2
   //----
   if(FirstTime1 == true) // Need to check if this is the first time the function is run
   {
     FirstTime1 = false; // Change variable to false
     LastDirection1 = CurrentDirection1; // Set new direction
     return (0);
   }
   
   if(CurrentDirection1 != LastDirection1 && FirstTime1 == false)  // If not the first time and there is a direction change
   {
     LastDirection1 = CurrentDirection1; // Set new direction
     return(CurrentDirection1); // 1 for up, 2 for down
   }
   else
   {
     return (0);  // No direction change
   }
}

//+------------------------------------------------------------------+
// End of Cross                                                      
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| HANDLE TRADING ENVIRONMENT                                       
//+------------------------------------------------------------------+
void HandleTradingEnvironment(bool Journaling, int Retry_Interval){
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function checks for errors

   if(IsTradeAllowed()==true)return;
   if(!IsConnected())
     {
      if(Journaling)Print("EA Journaling: Terminal is not connected to server...");
      return;
     }
   if(!IsTradeAllowed() && Journaling)Print("EA Journaling: Trade is not alowed for some reason...");
   if(IsConnected() && !IsTradeAllowed())
     {
      while(IsTradeContextBusy()==true)
        {
         if(Journaling)Print("EA Journaling: Trading context is busy... Will wait a bit...");
         Sleep(Retry_Interval);
        }
     }
   RefreshRates();
  }
//+------------------------------------------------------------------+
//| End of HANDLE TRADING ENVIRONMENT                                
//+------------------------------------------------------------------+  
//+------------------------------------------------------------------+
//| ERROR DESCRIPTION                                                
//+------------------------------------------------------------------+
string GetErrorDescription(int error){
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function returns the exact error

   string ErrorDescription="";
//---
   switch(error)
     {
      case 0:     ErrorDescription = "NO Error. Everything should be good.";                                    break;
      case 1:     ErrorDescription = "No error returned, but the result is unknown";                            break;
      case 2:     ErrorDescription = "Common error";                                                            break;
      case 3:     ErrorDescription = "Invalid trade parameters";                                                break;
      case 4:     ErrorDescription = "Trade server is busy";                                                    break;
      case 5:     ErrorDescription = "Old version of the client terminal";                                      break;
      case 6:     ErrorDescription = "No connection with trade server";                                         break;
      case 7:     ErrorDescription = "Not enough rights";                                                       break;
      case 8:     ErrorDescription = "Too frequent requests";                                                   break;
      case 9:     ErrorDescription = "Malfunctional trade operation";                                           break;
      case 64:    ErrorDescription = "Account disabled";                                                        break;
      case 65:    ErrorDescription = "Invalid account";                                                         break;
      case 128:   ErrorDescription = "Trade timeout";                                                           break;
      case 129:   ErrorDescription = "Invalid price";                                                           break;
      case 130:   ErrorDescription = "Invalid stops";                                                           break;
      case 131:   ErrorDescription = "Invalid trade volume";                                                    break;
      case 132:   ErrorDescription = "Market is closed";                                                        break;
      case 133:   ErrorDescription = "Trade is disabled";                                                       break;
      case 134:   ErrorDescription = "Not enough money";                                                        break;
      case 135:   ErrorDescription = "Price changed";                                                           break;
      case 136:   ErrorDescription = "Off quotes";                                                              break;
      case 137:   ErrorDescription = "Broker is busy";                                                          break;
      case 138:   ErrorDescription = "Requote";                                                                 break;
      case 139:   ErrorDescription = "Order is locked";                                                         break;
      case 140:   ErrorDescription = "Long positions only allowed";                                             break;
      case 141:   ErrorDescription = "Too many requests";                                                       break;
      case 145:   ErrorDescription = "Modification denied because order too close to market";                   break;
      case 146:   ErrorDescription = "Trade context is busy";                                                   break;
      case 147:   ErrorDescription = "Expirations are denied by broker";                                        break;
      case 148:   ErrorDescription = "Too many open and pending orders (more than allowed)";                    break;
      case 4000:  ErrorDescription = "No error";                                                                break;
      case 4001:  ErrorDescription = "Wrong function pointer";                                                  break;
      case 4002:  ErrorDescription = "Array index is out of range";                                             break;
      case 4003:  ErrorDescription = "No memory for function call stack";                                       break;
      case 4004:  ErrorDescription = "Recursive stack overflow";                                                break;
      case 4005:  ErrorDescription = "Not enough stack for parameter";                                          break;
      case 4006:  ErrorDescription = "No memory for parameter string";                                          break;
      case 4007:  ErrorDescription = "No memory for temp string";                                               break;
      case 4008:  ErrorDescription = "Not initialized string";                                                  break;
      case 4009:  ErrorDescription = "Not initialized string in array";                                         break;
      case 4010:  ErrorDescription = "No memory for array string";                                              break;
      case 4011:  ErrorDescription = "Too long string";                                                         break;
      case 4012:  ErrorDescription = "Remainder from zero divide";                                              break;
      case 4013:  ErrorDescription = "Zero divide";                                                             break;
      case 4014:  ErrorDescription = "Unknown command";                                                         break;
      case 4015:  ErrorDescription = "Wrong jump (never generated error)";                                      break;
      case 4016:  ErrorDescription = "Not initialized array";                                                   break;
      case 4017:  ErrorDescription = "DLL calls are not allowed";                                               break;
      case 4018:  ErrorDescription = "Cannot load library";                                                     break;
      case 4019:  ErrorDescription = "Cannot call function";                                                    break;
      case 4020:  ErrorDescription = "Expert function calls are not allowed";                                   break;
      case 4021:  ErrorDescription = "Not enough memory for temp string returned from function";                break;
      case 4022:  ErrorDescription = "System is busy (never generated error)";                                  break;
      case 4050:  ErrorDescription = "Invalid function parameters count";                                       break;
      case 4051:  ErrorDescription = "Invalid function parameter value";                                        break;
      case 4052:  ErrorDescription = "String function internal error";                                          break;
      case 4053:  ErrorDescription = "Some array error";                                                        break;
      case 4054:  ErrorDescription = "Incorrect series array using";                                            break;
      case 4055:  ErrorDescription = "Custom indicator error";                                                  break;
      case 4056:  ErrorDescription = "Arrays are incompatible";                                                 break;
      case 4057:  ErrorDescription = "Global variables processing error";                                       break;
      case 4058:  ErrorDescription = "Global variable not found";                                               break;
      case 4059:  ErrorDescription = "Function is not allowed in testing mode";                                 break;
      case 4060:  ErrorDescription = "Function is not confirmed";                                               break;
      case 4061:  ErrorDescription = "Send mail error";                                                         break;
      case 4062:  ErrorDescription = "String parameter expected";                                               break;
      case 4063:  ErrorDescription = "Integer parameter expected";                                              break;
      case 4064:  ErrorDescription = "Double parameter expected";                                               break;
      case 4065:  ErrorDescription = "Array as parameter expected";                                             break;
      case 4066:  ErrorDescription = "Requested history data in updating state";                                break;
      case 4067:  ErrorDescription = "Some error in trading function";                                          break;
      case 4099:  ErrorDescription = "End of file";                                                             break;
      case 4100:  ErrorDescription = "Some file error";                                                         break;
      case 4101:  ErrorDescription = "Wrong file name";                                                         break;
      case 4102:  ErrorDescription = "Too many opened files";                                                   break;
      case 4103:  ErrorDescription = "Cannot open file";                                                        break;
      case 4104:  ErrorDescription = "Incompatible access to a file";                                           break;
      case 4105:  ErrorDescription = "No order selected";                                                       break;
      case 4106:  ErrorDescription = "Unknown symbol";                                                          break;
      case 4107:  ErrorDescription = "Invalid price";                                                           break;
      case 4108:  ErrorDescription = "Invalid ticket";                                                          break;
      case 4109:  ErrorDescription = "EA is not allowed to trade is not allowed. ";                             break;
      case 4110:  ErrorDescription = "Longs are not allowed. Check the expert properties";                      break;
      case 4111:  ErrorDescription = "Shorts are not allowed. Check the expert properties";                     break;
      case 4200:  ErrorDescription = "Object exists already";                                                   break;
      case 4201:  ErrorDescription = "Unknown object property";                                                 break;
      case 4202:  ErrorDescription = "Object does not exist";                                                   break;
      case 4203:  ErrorDescription = "Unknown object type";                                                     break;
      case 4204:  ErrorDescription = "No object name";                                                          break;
      case 4205:  ErrorDescription = "Object coordinates error";                                                break;
      case 4206:  ErrorDescription = "No specified subwindow";                                                  break;
      case 4207:  ErrorDescription = "Some error in object function";                                           break;
      default:    ErrorDescription = "No error or error is unknown";
     }
   return(ErrorDescription);
  }
//+------------------------------------------------------------------+
//| End of ERROR DESCRIPTION                                         
//+------------------------------------------------------------------+